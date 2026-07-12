import 'package:flutter/material.dart';

import '../models/verification_models.dart';
import 'verification_domain.dart';

/// Visual-only face guide states (mirrors Next.js faceAuthStatus.ts).
enum FaceGuideState {
  preparing,
  searching,
  aligning,
  ready,
  capturing,
  success,
  error,
}

extension FaceGuideStateX on FaceGuideState {
  Color get accentColor {
    return switch (this) {
      FaceGuideState.preparing => const Color(0xFF64B5F6),
      FaceGuideState.searching => const Color(0xFF00E5FF),
      FaceGuideState.aligning => const Color(0xFFFFB74D),
      FaceGuideState.ready => const Color(0xFF66BB6A),
      FaceGuideState.capturing => const Color(0xFFE84A7A),
      FaceGuideState.success => const Color(0xFF66BB6A),
      FaceGuideState.error => const Color(0xFFEF5350),
    };
  }

  String get label {
    return switch (this) {
      FaceGuideState.preparing => 'Preparing camera',
      FaceGuideState.searching => 'Detecting face',
      FaceGuideState.aligning => 'Checking alignment',
      FaceGuideState.ready => 'Hold steady',
      FaceGuideState.capturing => 'Capturing',
      FaceGuideState.success => 'Aligned',
      FaceGuideState.error => 'Adjust position',
    };
  }

  bool get pulseDot => this == FaceGuideState.searching || this == FaceGuideState.aligning;
}

FaceGuideState deriveFaceGuideState({
  required bool cameraReady,
  required bool submitting,
  required bool awaitingAction,
  required bool hasCameraError,
}) {
  if (hasCameraError) return FaceGuideState.error;
  if (!cameraReady) return FaceGuideState.preparing;
  if (submitting) return FaceGuideState.capturing;
  if (awaitingAction) return FaceGuideState.ready;
  return FaceGuideState.aligning;
}

String shortCameraInstruction({
  required bool isSelfie,
  required bool awaitingAction,
  LivenessStep? livenessStep,
}) {
  if (isSelfie) return 'Center your face. Look straight ahead.';
  if (!awaitingAction) return 'Center your face inside the frame.';
  return switch (livenessStep) {
    LivenessStep.smile => 'Smile naturally.',
    LivenessStep.blink => 'Close your eyes briefly.',
    LivenessStep.headLeft => 'Turn your head left.',
    LivenessStep.headRight => 'Turn your head right.',
    null => 'Keep your head steady.',
  };
}

String verificationStageLabel({
  required VerificationFlowStep step,
  required bool cameraReady,
  required bool submitting,
  required bool awaitingAction,
  required bool isSelfie,
}) {
  if (step == VerificationFlowStep.processing) return 'Uploading verification';
  if (step == VerificationFlowStep.result) return 'Verification complete';
  if (!cameraReady) return 'Preparing camera';
  if (submitting) return isSelfie ? 'Uploading verification' : 'Performing liveness check';
  if (awaitingAction) return 'Performing liveness check';
  if (isSelfie) return 'Detecting face';
  return 'Checking alignment';
}
