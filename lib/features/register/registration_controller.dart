import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        step: json['step'] as int? ?? 1,
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

  Future<void> handleContinue() async {
    state = state.copyWith(clearError: true);
    if (state.step == 2 && !state.accountCreated) {
      state = state.copyWith(isSubmitting: true);
      try {
        await createAccountIfNeeded();
      } catch (_) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Could not create your account. This email or phone may already be registered.',
        );
        return;
      }
      state = state.copyWith(isSubmitting: false);
    }
    nextStep();
  }

  Future<void> handleSubmit() async {
    state = state.copyWith(clearError: true, isSubmitting: true);
    try {
      if (!state.accountCreated) {
        await createAccountIfNeeded();
      }
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
