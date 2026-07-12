import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/security_repository.dart';
import '../models/security_models.dart';
import '../services/biometric_auth_service.dart';
import '../services/device_fingerprint_service.dart';

final deviceFingerprintServiceProvider = Provider<DeviceFingerprintService>((ref) {
  return DeviceFingerprintService();
});

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(
    client: ref.watch(dioClientProvider),
    deviceService: ref.watch(deviceFingerprintServiceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ── Overview ───────────────────────────────────────────────

final securityOverviewProvider = FutureProvider.autoDispose<SecurityOverview>((ref) async {
  return ref.watch(securityRepositoryProvider).getOverview();
});

// ── Devices ────────────────────────────────────────────────

final activeDevicesProvider = FutureProvider.autoDispose<List<UserDevice>>((ref) async {
  return ref.watch(securityRepositoryProvider).listDevices();
});

final trustedDevicesProvider = FutureProvider.autoDispose<List<UserDevice>>((ref) async {
  final devices = await ref.watch(securityRepositoryProvider).listDevices();
  return devices.where((d) => d.isTrustedActive).toList();
});

// ── Login history ──────────────────────────────────────────

class LoginHistoryQuery extends Equatable {
  const LoginHistoryQuery({this.search = '', this.successFilter, this.page = 1});

  final String search;
  final bool? successFilter;
  final int page;

  @override
  List<Object?> get props => [search, successFilter, page];
}

final loginHistoryProvider =
    FutureProvider.autoDispose.family<({List<LoginHistoryEntry> results, int total}), LoginHistoryQuery>(
  (ref, query) async {
    return ref.watch(securityRepositoryProvider).loginHistory(
          search: query.search,
          success: query.successFilter,
          page: query.page,
        );
  },
);

// ── Security alerts ────────────────────────────────────────

final securityEventsProvider = FutureProvider.autoDispose<List<SecurityEvent>>((ref) async {
  return ref.watch(securityRepositoryProvider).listEvents();
});

final unreadSecurityEventsProvider = FutureProvider.autoDispose<List<SecurityEvent>>((ref) async {
  return ref.watch(securityRepositoryProvider).listEvents(unreadOnly: true);
});

// ── Biometric capabilities ─────────────────────────────────

final biometricCapabilitiesProvider = FutureProvider.autoDispose<BiometricCapabilities>((ref) async {
  return ref.watch(biometricAuthServiceProvider).getCapabilities();
});

final localBiometricEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(biometricAuthServiceProvider).isLocallyEnabled();
});

// ── 2FA controller ─────────────────────────────────────────

enum TwoFactorStep { intro, verifyPassword, setup, verifyCode, backupCodes, done }

class TwoFactorState extends Equatable {
  const TwoFactorState({
    this.step = TwoFactorStep.intro,
    this.loading = false,
    this.error,
    this.method,
    this.totpSetup,
    this.backupCodes = const [],
    this.password = '',
  });

  final TwoFactorStep step;
  final bool loading;
  final String? error;
  final String? method;
  final TotpSetupData? totpSetup;
  final List<String> backupCodes;
  final String password;

  TwoFactorState copyWith({
    TwoFactorStep? step,
    bool? loading,
    String? error,
    String? method,
    TotpSetupData? totpSetup,
    List<String>? backupCodes,
    String? password,
    bool clearError = false,
  }) {
    return TwoFactorState(
      step: step ?? this.step,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      method: method ?? this.method,
      totpSetup: totpSetup ?? this.totpSetup,
      backupCodes: backupCodes ?? this.backupCodes,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [step, loading, error, method, totpSetup, backupCodes];
}

class TwoFactorController extends StateNotifier<TwoFactorState> {
  TwoFactorController(this._ref) : super(const TwoFactorState());

  final Ref _ref;

  SecurityRepository get _repo => _ref.read(securityRepositoryProvider);

  void goTo(TwoFactorStep step) => state = state.copyWith(step: step, clearError: true);

  Future<void> verifyPasswordAndContinue(String password, String method) async {
    state = state.copyWith(loading: true, password: password, method: method, clearError: true);
    try {
      final ok = await _repo.verifyPassword(password);
      if (!ok) {
        state = state.copyWith(loading: false, error: 'Incorrect password.');
        return;
      }
      if (method == 'totp') {
        final setup = await _repo.setupTotp(password);
        state = state.copyWith(loading: false, totpSetup: setup, step: TwoFactorStep.setup);
      } else {
        await _repo.setupEmail2fa(password);
        state = state.copyWith(loading: false, step: TwoFactorStep.verifyCode);
      }
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> verifyAndEnable(String code) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final codes = await _repo.enable2fa(code);
      state = state.copyWith(
        loading: false,
        backupCodes: codes,
        step: TwoFactorStep.backupCodes,
      );
      _ref.invalidate(securityOverviewProvider);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> disable(String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.disable2fa(password);
      state = const TwoFactorState(step: TwoFactorStep.done);
      _ref.invalidate(securityOverviewProvider);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}

final twoFactorControllerProvider =
    StateNotifierProvider.autoDispose<TwoFactorController, TwoFactorState>((ref) {
  return TwoFactorController(ref);
});

// ── Security action controller ─────────────────────────────

class SecurityActionState extends Equatable {
  const SecurityActionState({this.loading = false, this.message, this.error});

  final bool loading;
  final String? message;
  final String? error;

  SecurityActionState copyWith({bool? loading, String? message, String? error, bool clear = false}) {
    return SecurityActionState(
      loading: loading ?? this.loading,
      message: clear ? null : message ?? this.message,
      error: clear ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [loading, message, error];
}

class SecurityActionController extends StateNotifier<SecurityActionState> {
  SecurityActionController(this._ref) : super(const SecurityActionState());

  final Ref _ref;

  SecurityRepository get _repo => _ref.read(securityRepositoryProvider);
  BiometricAuthService get _bio => _ref.read(biometricAuthServiceProvider);

  void _invalidateAll() {
    _ref.invalidate(securityOverviewProvider);
    _ref.invalidate(activeDevicesProvider);
    _ref.invalidate(trustedDevicesProvider);
    _ref.invalidate(securityEventsProvider);
    _ref.invalidate(loginHistoryProvider);
  }

  Future<bool> enableBiometric(String password) async {
    state = const SecurityActionState(loading: true);
    try {
      final authed = await _bio.authenticate(reason: 'Enable biometric login for Duo');
      if (!authed) {
        state = const SecurityActionState(error: 'Biometric verification cancelled.');
        return false;
      }
      final token = await _repo.enableBiometric(password);
      await _bio.saveToken(token);
      state = const SecurityActionState(message: 'Biometric login enabled.');
      _invalidateAll();
      _ref.invalidate(localBiometricEnabledProvider);
      return true;
    } on ApiException catch (e) {
      state = SecurityActionState(error: e.message);
      return false;
    }
  }

  Future<bool> disableBiometric(String password) async {
    state = const SecurityActionState(loading: true);
    try {
      await _repo.disableBiometric(password);
      await _bio.clearLocal();
      state = const SecurityActionState(message: 'Biometric login disabled.');
      _invalidateAll();
      _ref.invalidate(localBiometricEnabledProvider);
      return true;
    } on ApiException catch (e) {
      state = SecurityActionState(error: e.message);
      return false;
    }
  }

  Future<bool> logoutAll({required bool keepCurrent}) async {
    state = const SecurityActionState(loading: true);
    try {
      final count = await _repo.logoutAllDevices(keepCurrent: keepCurrent);
      state = SecurityActionState(message: 'Signed out of $count device(s).');
      _invalidateAll();
      return true;
    } on ApiException catch (e) {
      state = SecurityActionState(error: e.message);
      return false;
    }
  }

  Future<bool> changePassword({
    required String current,
    required String newPassword,
    required String confirm,
  }) async {
    state = const SecurityActionState(loading: true);
    try {
      final msg = await _repo.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      state = SecurityActionState(message: msg);
      _invalidateAll();
      return true;
    } on ApiException catch (e) {
      state = SecurityActionState(error: e.message);
      return false;
    }
  }
}

final securityActionControllerProvider =
    StateNotifierProvider.autoDispose<SecurityActionController, SecurityActionState>((ref) {
  return SecurityActionController(ref);
});
