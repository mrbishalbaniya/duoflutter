import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/permission_local_store.dart';
import '../models/permission_models.dart';
import '../services/permission_service.dart';

final permissionLocalStoreProvider = Provider<PermissionLocalStore>((ref) {
  return PermissionLocalStore(ref.watch(localStorageProvider).settings);
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

Future<DuoPermissionStatus> requestAppNotificationsAccess(Ref ref) async {
  try {
    await ref.read(pushNotificationServiceProvider).register();
    try {
      await ref.read(pushMessagingCoordinatorProvider).reinitialize();
    } catch (_) {}
    return DuoPermissionStatus.granted;
  } catch (_) {
    return ref.read(permissionServiceProvider).request(DuoPermissionType.notifications);
  }
}

final permissionSetupCompleteProvider =
    StateNotifierProvider<PermissionSetupGateController, bool>((ref) {
  return PermissionSetupGateController(ref);
});

class PermissionSetupGateController extends StateNotifier<bool> {
  PermissionSetupGateController(Ref ref)
      : _ref = ref,
        super(_readInitial(ref));

  final Ref _ref;

  static bool _readInitial(Ref ref) {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    return ref.read(permissionLocalStoreProvider).isSetupComplete;
  }

  Future<void> markComplete() async {
    await _ref.read(permissionLocalStoreProvider).markSetupComplete();
    state = true;
  }

  Future<void> reset() async {
    await _ref.read(permissionLocalStoreProvider).resetSetup();
    state = false;
  }
}

final permissionStatusesSnapshotProvider =
    FutureProvider<Map<DuoPermissionType, DuoPermissionStatus>>((ref) async {
  return ref.watch(permissionServiceProvider).checkAll();
});

class PermissionSetupController extends StateNotifier<PermissionSetupState> {
  PermissionSetupController(this._ref) : super(const PermissionSetupState()) {
    _refreshStatuses();
  }

  final Ref _ref;

  PermissionService get _service => _ref.read(permissionServiceProvider);

  Future<void> _refreshStatuses() async {
    final statuses = await _service.checkAll();
    state = state.copyWith(statuses: statuses);
  }

  Future<DuoPermissionStatus> allowCurrent() async {
    final definition = state.currentDefinition;
    state = state.copyWith(isRequesting: true, showSuccess: false);

    final status = definition.type == DuoPermissionType.notifications
        ? await requestAppNotificationsAccess(_ref)
        : await _service.request(definition.type);
    final nextStatuses = Map<DuoPermissionType, DuoPermissionStatus>.from(state.statuses)
      ..[definition.type] = status;

    state = state.copyWith(
      statuses: nextStatuses,
      isRequesting: false,
      showSuccess: status.isGranted && state.isLastStep,
    );
    return status;
  }

  void skipCurrent() {
    final definition = state.currentDefinition;
    if (!definition.optional) return;
    final nextStatuses = Map<DuoPermissionType, DuoPermissionStatus>.from(state.statuses)
      ..[definition.type] = DuoPermissionStatus.denied;
    state = state.copyWith(
      statuses: nextStatuses,
      showSuccess: false,
      currentStep: state.isLastStep ? state.currentStep : state.currentStep + 1,
    );
  }

  void advance() {
    if (state.isLastStep) return;
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      showSuccess: false,
    );
  }

  void goToStep(int step) {
    state = state.copyWith(
      currentStep: step.clamp(0, state.totalSteps - 1),
      showSuccess: false,
    );
  }

  Future<void> completeSetup() async {
    await _ref.read(permissionSetupCompleteProvider.notifier).markComplete();
  }
}

final permissionSetupControllerProvider =
    StateNotifierProvider.autoDispose<PermissionSetupController, PermissionSetupState>((ref) {
  return PermissionSetupController(ref);
});

class PermissionManagementController extends StateNotifier<PermissionManagementState> {
  PermissionManagementController(this._ref) : super(const PermissionManagementState()) {
    refresh();
  }

  final Ref _ref;

  PermissionService get _service => _ref.read(permissionServiceProvider);

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    final statuses = await _service.checkAll();
    state = state.copyWith(statuses: statuses, isRefreshing: false);
  }

  Future<DuoPermissionStatus> request(DuoPermissionType type) async {
    final status = type == DuoPermissionType.notifications
        ? await requestAppNotificationsAccess(_ref)
        : await _service.request(type);
    final next = Map<DuoPermissionType, DuoPermissionStatus>.from(state.statuses)..[type] = status;
    state = state.copyWith(statuses: next);
    return status;
  }

  Future<void> openSettings() => _service.openSystemSettings();

  Future<void> resetSetupFlow() async {
    await _ref.read(permissionSetupCompleteProvider.notifier).reset();
  }
}

final permissionManagementControllerProvider =
    StateNotifierProvider.autoDispose<PermissionManagementController, PermissionManagementState>((ref) {
  return PermissionManagementController(ref);
});
