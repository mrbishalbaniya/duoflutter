import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/two_factor_exception.dart';
import '../auth_controller.dart';
import '../domain/login_domain.dart';

class LoginUiState extends Equatable {
  const LoginUiState({
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.error,
    this.showPasswordResetSuccess = false,
  });

  final bool isLoading;
  final bool isGoogleLoading;
  final String? error;
  final bool showPasswordResetSuccess;

  bool get isBusy => isLoading || isGoogleLoading;

  LoginUiState copyWith({
    bool? isLoading,
    bool? isGoogleLoading,
    String? error,
    bool? showPasswordResetSuccess,
    bool clearError = false,
    bool clearPasswordResetSuccess = false,
  }) {
    return LoginUiState(
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      error: clearError ? null : (error ?? this.error),
      showPasswordResetSuccess: clearPasswordResetSuccess
          ? false
          : (showPasswordResetSuccess ?? this.showPasswordResetSuccess),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isGoogleLoading,
        error,
        showPasswordResetSuccess,
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

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ref.read(authControllerProvider.notifier).login(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on TwoFactorRequiredException catch (e) {
      state = state.copyWith(isLoading: false);
      return _completeTwoFactor(e.challenge);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: mapLoginError(e));
      return false;
    }
  }

  Future<bool> _completeTwoFactor(dynamic challenge) async {
    // UI layer should show 2FA dialog — handled via pending challenge in state extension
    state = state.copyWith(
      error: 'Two-factor authentication required. Enter your verification code.',
    );
    return false;
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
