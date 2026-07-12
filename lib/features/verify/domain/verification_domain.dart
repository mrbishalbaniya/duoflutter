import 'package:flutter/material.dart';

import '../models/verification_models.dart';

enum VerificationFlowStep {
  instructions,
  crossDevice,
  liveness,
  selfie,
  processing,
  result,
}

enum VerificationMode { defaultMode, device }

class LivenessStepInfo {
  const LivenessStepInfo({
    required this.title,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String hint;
  final IconData icon;
}

const livenessStepCatalog = <LivenessStep, LivenessStepInfo>{
  LivenessStep.smile: LivenessStepInfo(
    title: 'Smile',
    hint: 'Hold neutral, then smile.',
    icon: Icons.sentiment_satisfied_alt_outlined,
  ),
  LivenessStep.blink: LivenessStepInfo(
    title: 'Blink',
    hint: 'Hold still, then blink.',
    icon: Icons.visibility_outlined,
  ),
  LivenessStep.headLeft: LivenessStepInfo(
    title: 'Turn Left',
    hint: 'Hold still, then turn left.',
    icon: Icons.arrow_back_rounded,
  ),
  LivenessStep.headRight: LivenessStepInfo(
    title: 'Turn Right',
    hint: 'Hold still, then turn right.',
    icon: Icons.arrow_forward_rounded,
  ),
};

const defaultInstructions = [
  'Center your face inside the frame',
  'Remove hats and sunglasses',
  'Ensure good lighting',
  'Keep your head steady',
];

const finalVerificationStatuses = {
  VerificationStatus.verified,
  VerificationStatus.rejected,
  VerificationStatus.underReview,
};

int verificationProgressPercent({
  required VerificationFlowStep step,
  VerificationStartResponse? session,
  required int completedLivenessCount,
}) {
  switch (step) {
    case VerificationFlowStep.instructions:
      return 0;
    case VerificationFlowStep.crossDevice:
      return 15;
    case VerificationFlowStep.liveness:
      if (session == null || session.livenessSteps.isEmpty) return 20;
      return ((completedLivenessCount / session.livenessSteps.length) * 100).round();
    case VerificationFlowStep.selfie:
      return 85;
    case VerificationFlowStep.processing:
      return 95;
    case VerificationFlowStep.result:
      return 100;
  }
}

List<VerificationTimelineItem> buildVerificationTimeline({
  required VerificationFlowStep currentStep,
  required List<LivenessStep> livenessSteps,
  required List<LivenessStep> completedSteps,
  VerificationStatus? resultStatus,
}) {
  final items = <VerificationTimelineItem>[
    VerificationTimelineItem(
      id: 'instructions',
      label: 'Get started',
      state: _timelineState(currentStep.index > VerificationFlowStep.instructions.index, currentStep == VerificationFlowStep.instructions),
    ),
  ];

  for (var i = 0; i < livenessSteps.length; i++) {
    final step = livenessSteps[i];
    final info = livenessStepCatalog[step]!;
    final done = completedSteps.contains(step);
    final active = currentStep == VerificationFlowStep.liveness && !done && completedSteps.length == i;
    items.add(
      VerificationTimelineItem(
        id: 'liveness_$step',
        label: info.title,
        state: _timelineState(done, active),
      ),
    );
  }

  items.addAll([
    VerificationTimelineItem(
      id: 'selfie',
      label: 'Selfie',
      state: _timelineState(
        currentStep.index > VerificationFlowStep.selfie.index ||
            (resultStatus != null && resultStatus != VerificationStatus.pending),
        currentStep == VerificationFlowStep.selfie,
      ),
    ),
    VerificationTimelineItem(
      id: 'review',
      label: resultStatus == VerificationStatus.verified
          ? 'Verified'
          : resultStatus == VerificationStatus.rejected
              ? 'Rejected'
              : resultStatus == VerificationStatus.underReview
                  ? 'Under review'
                  : 'Review',
      state: _timelineState(
        resultStatus == VerificationStatus.verified,
        currentStep == VerificationFlowStep.processing || currentStep == VerificationFlowStep.result,
      ),
    ),
  ]);

  return items;
}

TimelineItemState _timelineState(bool done, bool active) {
  if (done) return TimelineItemState.completed;
  if (active) return TimelineItemState.active;
  return TimelineItemState.upcoming;
}

enum TimelineItemState { completed, active, upcoming }

class VerificationTimelineItem {
  const VerificationTimelineItem({
    required this.id,
    required this.label,
    required this.state,
  });

  final String id;
  final String label;
  final TimelineItemState state;
}

String faceOverlayStatusMessage({
  required VerificationFlowStep step,
  LivenessStep? livenessStep,
  required bool awaitingAction,
  required bool cameraReady,
}) {
  if (!cameraReady) return 'Starting camera…';
  if (step == VerificationFlowStep.selfie) {
    return 'Look straight at the camera and tap Capture';
  }
  if (livenessStep == null) return 'Position your face in the oval';
  if (!awaitingAction) {
    return 'Hold a neutral pose, then tap Capture';
  }
  switch (livenessStep) {
    case LivenessStep.smile:
      return 'Smile naturally, then tap Capture';
    case LivenessStep.blink:
      return 'Close your eyes fully, then tap Capture';
    case LivenessStep.headLeft:
      return 'Turn your head left, then tap Capture';
    case LivenessStep.headRight:
      return 'Turn your head right, then tap Capture';
  }
}
