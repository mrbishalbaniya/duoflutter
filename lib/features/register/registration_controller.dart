import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';

import '../../core/providers/core_providers.dart';
import '../auth/auth_controller.dart';
import 'registration_models.dart';
import 'registration_validators.dart';

const _storageKey = 'duo_registration_store';

class RegistrationController extends StateNotifier<RegistrationState> {
  RegistrationController(this._ref) : super(const RegistrationState()) {
    _loadPersisted();
  }

  final Ref _ref;

  void _loadPersisted() {
    final box = _ref.read(localStorageProvider).settings;
    final raw = box.get(_storageKey);
    if (raw is! String || raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = RegistrationData.fromPersistedJson(
        json['data'] as Map<String, dynamic>? ?? {},
      );
      state = state.copyWith(
        step: ((json['step'] as int?) ?? 1).clamp(1, totalRegistrationSteps),
        accountSubStep: AccountSubStep.values[json['accountSubStep'] as int? ?? 0],
        data: data,
        accountCreated: json['accountCreated'] as bool? ?? false,
      );
    } catch (_) {}
  }

  void _persist() {
    final box = _ref.read(localStorageProvider).settings;
    final payload = jsonEncode({
      'step': state.step,
      'accountSubStep': state.accountSubStep.index,
      'data': state.data.toPersistedJson(),
      'accountCreated': state.accountCreated,
    });
    box.put(_storageKey, payload);
  }

  void patchData(RegistrationData Function(RegistrationData current) patch) {
    state = state.copyWith(data: patch(state.data), clearError: true);
    _persist();
  }

  void setAccountSubStep(AccountSubStep subStep) {
    state = state.copyWith(accountSubStep: subStep, clearError: true);
    _persist();
  }

  void setAccountCreated(bool value) {
    state = state.copyWith(accountCreated: value);
    _persist();
  }

  void nextStep() {
    final next = (state.step + 1).clamp(1, totalRegistrationSteps);
    state = state.copyWith(step: next, clearError: true);
    _persist();
  }

  void prevStep() {
    final prev = (state.step - 1).clamp(1, totalRegistrationSteps);
    state = state.copyWith(step: prev, clearError: true);
    _persist();
  }

  void goToStep(int step) {
    state = state.copyWith(step: step.clamp(1, totalRegistrationSteps), clearError: true);
    _persist();
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  Future<void> createAccountIfNeeded() async {
    if (state.accountCreated || state.data.signedUpWithGoogle) return;
    final email = registrationEmail(state.data);
    final fullName = '${state.data.firstName} ${state.data.lastName}'.trim();
    await _ref.read(authControllerProvider.notifier).register(
          email: email,
          password: state.data.password,
          fullName: fullName.isEmpty ? 'Duo Member' : fullName,
        );
    setAccountCreated(true);
  }

  bool get _isSignedIn =>
      _ref.read(authControllerProvider).status == AuthStatus.authenticated;

  /// Makes sure a signed-in account exists before anything that needs auth
  /// (leaving step 2, uploading photos). The saved "account created" flag can
  /// outlive the login itself (expired token, logout, reinstall), so the real
  /// session is checked instead of trusting the flag. Returns true when signed in.
  Future<bool> ensureAccount() async {
    if (state.accountCreated && _isSignedIn) return true;

    if (state.data.signedUpWithGoogle) {
      // Google sign-up cannot be redone silently; send them back to step 1.
      state = state.copyWith(accountCreated: false);
      patchData((d) => d.copyWith(signedUpWithGoogle: false, otpVerified: false, verifiedEmail: ''));
      setAccountSubStep(AccountSubStep.form);
      goToStep(1);
      state = state.copyWith(
        isSubmitting: false,
        error: 'Your Google session ended. Sign up with Google again to continue.',
      );
      return false;
    }

    state = state.copyWith(accountCreated: false, isSubmitting: true, clearError: true);
    _persist();
    try {
      try {
        await createAccountIfNeeded();
      } on ApiException catch (e) {
        // The account was made in an earlier attempt: sign back in with the
        // same email and password instead of failing.
        final exists = RegExp('already exists', caseSensitive: false).hasMatch('${e.raw ?? e.message}');
        if (!exists || state.data.password.isEmpty) rethrow;
        await _ref
            .read(authControllerProvider.notifier)
            .login(registrationEmail(state.data), state.data.password);
        setAccountCreated(true);
      }
    } catch (e) {
      final raw = e is ApiException ? e.raw : null;
      final fieldError = raw is Map ? _firstFieldError(raw, const ['password', 'email']) : null;
      final message = fieldError?.message ??
          (e is ApiException && e.message.trim().isNotEmpty
              ? e.message
              : 'Could not create your account. Check your email and password, or try again.');
      state = state.copyWith(isSubmitting: false, error: message);
      if (fieldError != null) {
        // Password/email problems can only be fixed on the account form.
        if (fieldError.field == 'password') {
          patchData((d) => d.copyWith(password: '', confirmPassword: ''));
        }
        setAccountSubStep(AccountSubStep.form);
        goToStep(1);
        state = state.copyWith(error: message);
      } else if (RegExp('verify your email', caseSensitive: false).hasMatch(message)) {
        // Verification expired server-side; send them back for a new code.
        patchData((d) => d.copyWith(otpVerified: false, verifiedEmail: ''));
        setAccountSubStep(AccountSubStep.form);
        goToStep(1);
        state = state.copyWith(error: message);
      }
      return false;
    }
    state = state.copyWith(isSubmitting: false);
    return true;
  }

  Future<void> handleContinue() async {
    state = state.copyWith(clearError: true);
    if (state.step == 2 && !await ensureAccount()) return;
    nextStep();
  }

  /// First server validation message for one of [fields], e.g. "This password is too common."
  ({String field, String message})? _firstFieldError(Map raw, List<String> fields) {
    for (final field in fields) {
      final value = raw[field];
      final text = value is List && value.isNotEmpty ? '${value.first}' : (value is String ? value : '');
      if (text.trim().isEmpty) continue;
      final message = field == 'password' && !text.toLowerCase().contains('password')
          ? 'Password: $text'
          : text;
      return (field: field, message: message);
    }
    return null;
  }

  Future<void> handleSubmit() async {
    state = state.copyWith(clearError: true, isSubmitting: true);
    try {
      if (!await ensureAccount()) {
        state = state.copyWith(isSubmitting: false);
        return;
      }
      state = state.copyWith(isSubmitting: true);
      final photoUrls = collectRegistrationPhotoUrls(state.data.photos);
      final payload = mapRegistrationToProfile(
        state.data,
        profilePhotoUrl: photoUrls.profilePhotoUrl,
        galleryUrls: photoUrls.galleryUrls,
      );
      await _ref.read(profileRepositoryProvider).updateProfile(payload);
      await _ref.read(authControllerProvider.notifier).refreshUser();
      reset();
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceFirst('StateError: ', '').replaceFirst('Exception: ', ''),
      );
      return;
    }
    state = state.copyWith(isSubmitting: false);
  }

  void reset() {
    state = const RegistrationState();
    _ref.read(localStorageProvider).settings.delete(_storageKey);
  }
}

final registrationControllerProvider =
    StateNotifierProvider<RegistrationController, RegistrationState>((ref) {
  return RegistrationController(ref);
});
