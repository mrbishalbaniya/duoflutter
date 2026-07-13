import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/two_factor_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../repositories/auth_repository.dart';
import '../settings/providers/settings_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final DuoUser? user;
  final String? error;

  AuthState copyWith({AuthStatus? status, DuoUser? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, {bool autoBootstrap = true}) : super(const AuthState()) {
    if (autoBootstrap) {
      bootstrap();
    }
  }

  final Ref _ref;
  Future<void>? _bootstrapFuture;

  AuthRepository get _auth => _ref.read(authRepositoryProvider);

  Future<void> bootstrap() {
    return _bootstrapFuture ??= _bootstrapImpl();
  }

  Future<void> _bootstrapImpl() async {
    try {
      final hasSession = await _auth.hasSession();
      if (!hasSession) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _auth.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _ref.read(pushNotificationServiceProvider).syncIfEnabled();
    } catch (_) {
      await _auth.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(error: null);
    try {
      final user = await _auth.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _ref.read(pushNotificationServiceProvider).syncIfEnabled();
    } on TwoFactorRequiredException {
      rethrow;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(error: null);
    try {
      final google = _ref.read(googleAuthServiceProvider);
      final credentials = await google.signIn();
      if (credentials == null) return;

      final DuoUser user;
      if (credentials.idToken != null) {
        user = await _auth.loginWithGoogle(credentials.idToken!);
      } else {
        user = await _auth.loginWithGoogleCode(
          code: credentials.code!,
          redirectUri: credentials.redirectUri!,
        );
      }

      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _ref.read(pushNotificationServiceProvider).syncIfEnabled();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(error: null);
    try {
      final user = await _auth.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _ref.read(pushNotificationServiceProvider).syncIfEnabled();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _auth.getMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _ref.read(pushNotificationServiceProvider).syncIfEnabled();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _ref.read(pushNotificationServiceProvider).unregister();
    } catch (_) {}
    await _auth.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
