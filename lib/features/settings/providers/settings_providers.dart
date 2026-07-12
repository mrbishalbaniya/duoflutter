import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/notification_repository.dart';
import '../../auth/auth_controller.dart';
import '../domain/settings_domain.dart';
import '../services/push_notification_service.dart';

class SettingsUiState extends Equatable {
  const SettingsUiState({
    this.pushStatus = const PushStatus(
      supported: true,
      configured: false,
      permission: PushPermissionState.notDetermined,
      enabled: false,
    ),
    this.pushLoading = true,
    this.pushSaving = false,
    this.pushError,
    this.pushMessage,
    this.passwordSaving = false,
    this.passwordError,
    this.passwordMessage,
  });

  final PushStatus pushStatus;
  final bool pushLoading;
  final bool pushSaving;
  final String? pushError;
  final String? pushMessage;
  final bool passwordSaving;
  final String? passwordError;
  final String? passwordMessage;

  SettingsUiState copyWith({
    PushStatus? pushStatus,
    bool? pushLoading,
    bool? pushSaving,
    String? pushError,
    String? pushMessage,
    bool? passwordSaving,
    String? passwordError,
    String? passwordMessage,
    bool clearPushError = false,
    bool clearPushMessage = false,
    bool clearPasswordError = false,
    bool clearPasswordMessage = false,
  }) {
    return SettingsUiState(
      pushStatus: pushStatus ?? this.pushStatus,
      pushLoading: pushLoading ?? this.pushLoading,
      pushSaving: pushSaving ?? this.pushSaving,
      pushError: clearPushError ? null : pushError ?? this.pushError,
      pushMessage: clearPushMessage ? null : pushMessage ?? this.pushMessage,
      passwordSaving: passwordSaving ?? this.passwordSaving,
      passwordError: clearPasswordError ? null : passwordError ?? this.passwordError,
      passwordMessage: clearPasswordMessage ? null : passwordMessage ?? this.passwordMessage,
    );
  }

  @override
  List<Object?> get props => [
        pushStatus,
        pushLoading,
        pushSaving,
        pushError,
        pushMessage,
        passwordSaving,
        passwordError,
        passwordMessage,
      ];
}

class SettingsController extends StateNotifier<SettingsUiState> {
  SettingsController(this._ref) : super(const SettingsUiState()) {
    refreshPushStatus();
  }

  final Ref _ref;

  PushNotificationService get _push => _ref.read(pushNotificationServiceProvider);

  Future<void> refreshPushStatus() async {
    state = state.copyWith(pushLoading: true, clearPushError: true, clearPushMessage: true);
    try {
      final status = await _push.getStatus();
      state = state.copyWith(pushStatus: status, pushLoading: false);
    } catch (_) {
      state = state.copyWith(
        pushLoading: false,
        pushStatus: const PushStatus(
          supported: true,
          configured: false,
          permission: PushPermissionState.notDetermined,
          enabled: false,
        ),
      );
    }
  }

  Future<void> togglePushNotifications() async {
    state = state.copyWith(
      pushSaving: true,
      clearPushError: true,
      clearPushMessage: true,
    );
    try {
      if (state.pushStatus.enabled) {
        await _push.unregister();
        state = state.copyWith(
          pushSaving: false,
          pushMessage: 'Push notifications turned off.',
        );
      } else {
        await _push.register();
        state = state.copyWith(
          pushSaving: false,
          pushMessage: 'Push notifications enabled.',
        );
      }
      await refreshPushStatus();
    } catch (e) {
      state = state.copyWith(
        pushSaving: false,
        pushError: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final validationError = validatePasswordChange(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (validationError != null) {
      state = state.copyWith(
        passwordError: validationError,
        clearPasswordMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      passwordSaving: true,
      clearPasswordError: true,
      clearPasswordMessage: true,
    );
    try {
      final message = await _ref.read(authRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      state = state.copyWith(passwordSaving: false, passwordMessage: message);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(passwordSaving: false, passwordError: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(passwordSaving: false, passwordError: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _ref.read(authControllerProvider.notifier).logout();
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    repository: ref.watch(notificationRepositoryProvider),
    storage: ref.watch(localStorageProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioClientProvider));
});

final settingsControllerProvider =
    StateNotifierProvider.autoDispose<SettingsController, SettingsUiState>((ref) {
  return SettingsController(ref);
});
