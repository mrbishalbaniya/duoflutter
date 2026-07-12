import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../../core/providers/core_providers.dart';
import '../../repositories/verification_repository.dart';
import 'domain/verification_domain.dart';
import 'models/verification_models.dart';
import 'services/verification_image_service.dart';

class VerificationState extends Equatable {
  const VerificationState({
    this.mode = VerificationMode.defaultMode,
    this.step = VerificationFlowStep.instructions,
    this.session,
    this.livenessIndex = 0,
    this.completedSteps = const [],
    this.submitting = false,
    this.deviceLoading = false,
    this.stepFeedback,
    this.stepActionReady = false,
    this.result,
    this.error,
    this.autoStatus,
    this.cameraReady = false,
    this.cameraError,
    this.dashboardStatus,
    this.dashboardLoading = false,
    this.initialSessionToken,
  });

  final VerificationMode mode;
  final VerificationFlowStep step;
  final VerificationStartResponse? session;
  final int livenessIndex;
  final List<LivenessStep> completedSteps;
  final bool submitting;
  final bool deviceLoading;
  final LivenessStepResponse? stepFeedback;
  final bool stepActionReady;
  final VerificationStatusResponse? result;
  final String? error;
  final String? autoStatus;
  final bool cameraReady;
  final String? cameraError;
  final VerificationStatusResponse? dashboardStatus;
  final bool dashboardLoading;
  final String? initialSessionToken;

  LivenessStep? get currentLivenessStep {
    final steps = session?.livenessSteps ?? const [];
    if (livenessIndex < 0 || livenessIndex >= steps.length) return null;
    return steps[livenessIndex];
  }

  int get progressPercent => verificationProgressPercent(
        step: step,
        session: session,
        completedLivenessCount: completedSteps.length,
      );

  VerificationState copyWith({
    VerificationMode? mode,
    VerificationFlowStep? step,
    VerificationStartResponse? session,
    bool clearSession = false,
    int? livenessIndex,
    List<LivenessStep>? completedSteps,
    bool? submitting,
    bool? deviceLoading,
    LivenessStepResponse? stepFeedback,
    bool clearStepFeedback = false,
    bool? stepActionReady,
    VerificationStatusResponse? result,
    bool clearResult = false,
    String? error,
    bool clearError = false,
    String? autoStatus,
    bool clearAutoStatus = false,
    bool? cameraReady,
    String? cameraError,
    bool clearCameraError = false,
    VerificationStatusResponse? dashboardStatus,
    bool? dashboardLoading,
    String? initialSessionToken,
  }) {
    return VerificationState(
      mode: mode ?? this.mode,
      step: step ?? this.step,
      session: clearSession ? null : (session ?? this.session),
      livenessIndex: livenessIndex ?? this.livenessIndex,
      completedSteps: completedSteps ?? this.completedSteps,
      submitting: submitting ?? this.submitting,
      deviceLoading: deviceLoading ?? this.deviceLoading,
      stepFeedback: clearStepFeedback ? null : (stepFeedback ?? this.stepFeedback),
      stepActionReady: stepActionReady ?? this.stepActionReady,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      autoStatus: clearAutoStatus ? null : (autoStatus ?? this.autoStatus),
      cameraReady: cameraReady ?? this.cameraReady,
      cameraError: clearCameraError ? null : (cameraError ?? this.cameraError),
      dashboardStatus: dashboardStatus ?? this.dashboardStatus,
      dashboardLoading: dashboardLoading ?? this.dashboardLoading,
      initialSessionToken: initialSessionToken ?? this.initialSessionToken,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        step,
        session,
        livenessIndex,
        completedSteps,
        submitting,
        deviceLoading,
        stepFeedback,
        stepActionReady,
        result,
        error,
        autoStatus,
        cameraReady,
        cameraError,
        dashboardStatus,
        dashboardLoading,
        initialSessionToken,
      ];
}

class VerificationController extends StateNotifier<VerificationState> {
  VerificationController(this._ref) : super(const VerificationState());

  final Ref _ref;
  Timer? _advanceTimer;

  VerificationRepository get _repo => _ref.read(verificationRepositoryProvider);
  VerificationImageService get _images => VerificationImageService();

  void configure({
    VerificationMode mode = VerificationMode.defaultMode,
    String? initialSessionToken,
  }) {
    state = state.copyWith(
      mode: mode,
      initialSessionToken: initialSessionToken,
      step: mode == VerificationMode.device ? VerificationFlowStep.liveness : VerificationFlowStep.instructions,
      deviceLoading: mode == VerificationMode.device && initialSessionToken != null,
    );

    if (mode == VerificationMode.defaultMode) {
      unawaited(loadDashboardStatus());
    }
    if (mode == VerificationMode.device && initialSessionToken != null) {
      unawaited(loadDeviceSession(initialSessionToken));
    }
  }

  Future<void> loadDashboardStatus() async {
    state = state.copyWith(dashboardLoading: true, clearError: true);
    try {
      final status = await _repo.getVerificationStatus();
      state = state.copyWith(dashboardStatus: status, dashboardLoading: false);
    } catch (_) {
      state = state.copyWith(dashboardLoading: false);
    }
  }

  Future<void> loadDeviceSession(String sessionToken) async {
    state = state.copyWith(deviceLoading: true, clearError: true);
    try {
      final detail = await _repo.getVerificationSession(sessionToken);
      if (finalVerificationStatuses.contains(detail.status)) {
        state = state.copyWith(
          result: detail,
          step: VerificationFlowStep.result,
          deviceLoading: false,
        );
        return;
      }

      final startPayload = VerificationStartResponse(
        sessionId: sessionToken,
        sessionToken: sessionToken,
        expiresAt: detail.expiresAt,
        instructions: const [],
        livenessSteps: detail.livenessSteps,
        handoffUrl: detail.handoffUrl,
      );

      final completed = detail.session?.livenessStepsCompleted ?? const [];
      final nextIndex = completed.length;
      state = state.copyWith(
        session: startPayload,
        completedSteps: completed,
        livenessIndex: nextIndex,
        step: nextIndex >= detail.livenessSteps.length
            ? VerificationFlowStep.selfie
            : VerificationFlowStep.liveness,
        deviceLoading: false,
        clearStepFeedback: true,
        stepActionReady: false,
      );
    } catch (e) {
      state = state.copyWith(
        deviceLoading: false,
        step: VerificationFlowStep.instructions,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  Future<void> startOnDevice() async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final data = await _repo.startVerification();
      state = state.copyWith(
        session: data,
        livenessIndex: 0,
        completedSteps: const [],
        step: VerificationFlowStep.liveness,
        submitting: false,
        clearStepFeedback: true,
        stepActionReady: false,
      );
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  Future<void> startCrossDevice() async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final data = state.session ?? await _repo.startVerification();
      state = state.copyWith(
        session: data,
        step: VerificationFlowStep.crossDevice,
        submitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  void useThisDevice() {
    state = state.copyWith(
      livenessIndex: 0,
      completedSteps: const [],
      step: VerificationFlowStep.liveness,
      clearStepFeedback: true,
      stepActionReady: false,
      clearError: true,
    );
  }

  void onRemoteComplete(VerificationStatusResponse remoteResult) {
    state = state.copyWith(
      result: remoteResult,
      step: VerificationFlowStep.result,
    );
    _maybeRefreshProfile(remoteResult);
  }

  void resetLivenessStepContext() {
    state = state.copyWith(
      clearStepFeedback: true,
      stepActionReady: false,
      clearAutoStatus: true,
      clearError: true,
    );
  }

  void onLivenessIndexChanged() {
    resetLivenessStepContext();
  }

  Future<void> captureLiveness(File imageFile) async {
    final session = state.session;
    final step = state.currentLivenessStep;
    if (session == null || step == null) return;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final compressed = await _images.compressForUpload(imageFile);
      final response = await _repo.submitLivenessStep(
        sessionToken: session.sessionToken,
        step: step,
        image: compressed,
      );

      var nextState = state.copyWith(
        stepFeedback: response,
        completedSteps: response.livenessStepsCompleted,
        submitting: false,
      );

      if (response.baselineCaptured) {
        nextState = nextState.copyWith(stepActionReady: true, clearError: true);
      }

      state = nextState;

      if (response.passed) {
        _advanceTimer?.cancel();
        _advanceTimer = Timer(const Duration(milliseconds: 500), () {
          final nextIndex = state.livenessIndex + 1;
          final steps = state.session?.livenessSteps ?? const [];
          if (nextIndex >= steps.length) {
            state = state.copyWith(
              step: VerificationFlowStep.selfie,
              clearStepFeedback: true,
              stepActionReady: false,
            );
          } else {
            state = state.copyWith(
              livenessIndex: nextIndex,
              clearStepFeedback: true,
              stepActionReady: false,
            );
          }
        });
      }
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  Future<void> captureSelfie(File imageFile) async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(submitting: true, clearError: true, step: VerificationFlowStep.processing);
    try {
      final compressed = await _images.compressForUpload(imageFile);
      final response = await _repo.uploadVerificationSelfie(
        sessionToken: session.sessionToken,
        image: compressed,
      );
      state = state.copyWith(
        result: response,
        step: VerificationFlowStep.result,
        submitting: false,
      );
      _maybeRefreshProfile(response);
    } catch (e) {
      state = state.copyWith(
        submitting: false,
        step: VerificationFlowStep.selfie,
        error: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  void setCameraReady(bool ready) {
    state = state.copyWith(cameraReady: ready, clearCameraError: ready);
  }

  void setCameraError(String? message) {
    state = state.copyWith(cameraError: message, cameraReady: false);
  }

  void updateAutoStatus(String? message) {
    state = state.copyWith(autoStatus: message);
  }

  void tryAgain() {
    _advanceTimer?.cancel();
    state = state.copyWith(
      step: VerificationFlowStep.instructions,
      clearSession: true,
      clearResult: true,
      clearError: true,
      livenessIndex: 0,
      completedSteps: const [],
      clearStepFeedback: true,
      stepActionReady: false,
    );
    unawaited(loadDashboardStatus());
  }

  void _maybeRefreshProfile(VerificationStatusResponse response) {
    if (response.status == VerificationStatus.verified) {
      unawaited(_ref.read(authControllerProvider.notifier).refreshUser());
    }
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }
}
