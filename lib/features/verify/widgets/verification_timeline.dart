import 'package:flutter/material.dart';

import '../domain/verification_domain.dart';
import '../models/verification_models.dart';

class VerificationTimeline extends StatelessWidget {
  const VerificationTimeline({
    super.key,
    required this.currentStep,
    required this.livenessSteps,
    required this.completedSteps,
    this.resultStatus,
  });

  final VerificationFlowStep currentStep;
  final List<LivenessStep> livenessSteps;
  final List<LivenessStep> completedSteps;
  final VerificationStatus? resultStatus;

  @override
  Widget build(BuildContext context) {
    final items = buildVerificationTimeline(
      currentStep: currentStep,
      livenessSteps: livenessSteps,
      completedSteps: completedSteps,
      resultStatus: resultStatus,
    );
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verification timeline', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ...items.map((item) {
          final color = switch (item.state) {
            TimelineItemState.completed => theme.colorScheme.primary,
            TimelineItemState.active => theme.colorScheme.tertiary,
            TimelineItemState.upcoming => theme.colorScheme.outline,
          };
          final icon = switch (item.state) {
            TimelineItemState.completed => Icons.check_circle_rounded,
            TimelineItemState.active => Icons.radio_button_checked_rounded,
            TimelineItemState.upcoming => Icons.radio_button_off_rounded,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.state == TimelineItemState.upcoming
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      fontWeight: item.state == TimelineItemState.active ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
