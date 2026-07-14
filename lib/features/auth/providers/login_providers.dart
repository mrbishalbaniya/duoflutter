import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/two_factor_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../security/models/security_models.dart';
import '../../security/providers/security_providers.dart';
import '../auth_controller.dart';
import '../domain/login_domain.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginUiState extends Equatable {
  const LoginUiState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.isBiometricLoading = false,
    this.error,
    this.showPasswordResetSuccess = false,
    this.pendingChallenge,
  });

  final bool isLoading;
  final bool isGoogleLoading;
  final bool isBiometricLoading;
  final String? error;
  final bool showPasswordResetSuccess;
  final TwoFactorLoginChallenge? pendingChallenge;

  bool get isBusy => isLoading || isGoogleLoading || isBiometricLoading;
  bool get needsTwoFactor => pendingChallenge != null;

  LoginUiState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    bool? isBiometricLoading,
    String? error,
    bool? showPasswordResetSuccess,
    TwoFactorLoginChallenge? pendingChallenge,
    bool clearError = false,
    bool clearPasswordResetSuccess = false,
    bool clearChallenge = false,
  }) {
    return LoginUiState(
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      isBiometricLoading: isBiometricLoading ?? this.isBiometricLoading,
      error: clearError ? null : (error ?? this.error),
      showPasswordResetSuccess: clearPasswordResetSuccess
          ? false
          : (showPasswordResetSuccess ?? this.showPasswordResetSuccess),
      pendingChallenge: clearChallenge ? null : (pendingChallenge ?? this.pendingChallenge),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isGoogleLoading,
        isBiometricLoading,
        error,
        showPasswordResetSuccess,
        pendingChallenge,
      ];
}

class LoginController extends StateNotifier<LoginUiState> {
  LoginController(this._ref) : super(const LoginUiState());

  final Ref _ref;

  void showPasswordResetBanner() {
    state = state.copyWith(showPasswordResetSuccess: true, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearChallenge() {
    state = state.copyWith(clearChallenge: true);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearChallenge: true);
    try {
      await _ref.read(authControllerProvider.notifier).login(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on TwoFactorRequiredException catch (e) {
      state = state.copyWith(
        isLoading: false,
        pendingChallenge: e.challenge,
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: mapLoginError(e));
      return false;
    }
  }

  Future<bool> completeTwoFactor(String code) async {
    final challenge = state.pendingChallenge;
    if (challenge == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authControllerProvider.notifier).completeTwoFactorLogin(
            challengeToken: challenge.challengeToken,
            code: code,
          );
      state = state.copyWith(isLoading: false, clearChallenge: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: mapLoginError(e));
      return false;
    }
  }

  Future<void> resendTwoFactorOtp() async {
    final challenge = state.pendingChallenge;
    if (challenge == null) return;
    await _ref.read(authRepositoryProvider).sendTwoFactorLoginOtp(challenge.challengeToken);
  }

  Future<bool> signInWithBiometric() async {
    state = state.copyWith(isBiometricLoading: true, clearError: true);
    try {
      final bio = _ref.read(biometricAuthServiceProvider);
      final enabled = await bio.isLocallyEnabled();
      if (!enabled) {
        state = state.copyWith(
          isBiometricLoading: false,
          error: 'Biometric login is not set up on this device.',
        );
        return false;
      }
      final ok = await bio.authenticate(reason: 'Sign in to Duo');
      if (!ok) {
        state = state.copyWith(isBiometricLoading: false, error: 'Biometric verification cancelled.');
        return false;
      }
      final token = await bio.readToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isBiometricLoading: false, error: 'Biometric credential missing. Re-enable in Security Center.');
        return false;
      }
      await _ref.read(authControllerProvider.notifier).loginWithBiometric(token);
      state = state.copyWith(isBiometricLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isBiometricLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isBiometricLoading: false, error: mapLoginError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isGoogleLoading: true, clearError: true);
    try {
      await _ref.read(authControllerProvider.notifier).loginWithGoogle();
      state = state.copyWith(isGoogleLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isGoogleLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isGoogleLoading: false,
        error: mapGoogleSignInError(e),
      );
      return false;
    }
  }
}

String mapGoogleSignInError(Object error) {
  if (error is PlatformException && error.code == 'CANCELED') {
    return 'Google sign-in was cancelled.';
  }

  final message = error.toString().replaceFirst('StateError: ', '');
  if (message.contains('cancelled') || message.contains('canceled')) {
    return 'Google sign-in was cancelled.';
  }
  if (message.contains('redirect_uri_mismatch')) {
    return 'Google redirect URI is not allowed. Add '
        '${AppConfig.googleOAuthRedirectUri} to Google Cloud Console.';
  }
  return message.isNotEmpty ? message : 'Google sign-in failed.';
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginUiState>((ref) {
  return LoginController(ref);
});
