import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_gradients.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/verification_domain.dart';
import '../models/verification_models.dart';
import '../verification_controller.dart';
import 'verification_error_banner.dart';
import 'verification_status_badge.dart';
import 'verification_timeline.dart';

class VerificationInstructionsStep extends StatelessWidget {
  const VerificationInstructionsStep({
    super.key,
    required this.state,
    required this.onStartDevice,
    required this.onStartCrossDevice,
  });

  final VerificationState state;
  final VoidCallback onStartDevice;
  final VoidCallback onStartCrossDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboard = state.dashboardStatus;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (state.dashboardLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (dashboard != null && dashboard.status != VerificationStatus.pending) ...[
          _DashboardCard(status: dashboard),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
            color: theme.colorScheme.secondary.withValues(alpha: 0.45),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DuoGradients.brand,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text('Verify your profile', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Confirm you are the person in your profile photos. Complete a short liveness check and take a selfie.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...defaultInstructions.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 16),
        VerificationTimeline(
          currentStep: VerificationFlowStep.instructions,
          livenessSteps: const [
            LivenessStep.smile,
            LivenessStep.blink,
            LivenessStep.headLeft,
            LivenessStep.headRight,
          ],
          completedSteps: const [],
          resultStatus: dashboard?.status,
        ),
        if (state.error != null) ...[
          const SizedBox(height: 16),
          VerificationErrorBanner(message: state.error!),
        ],
        const SizedBox(height: 20),
        DuoGradientButton(
          label: state.submitting ? 'Starting…' : 'Start on this device',
          onPressed: state.submitting ? null : onStartDevice,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OR', style: theme.textTheme.labelSmall),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Verify on another device', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Share a QR code, link, or email to finish verification on a phone with a camera — no login required on that device.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: state.submitting ? null : onStartCrossDevice,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(state.submitting ? 'Preparing link…' : 'Get QR code, link & email'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.status});

  final VerificationStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Current status', style: theme.textTheme.titleSmall),
              const Spacer(),
              VerificationStatusBadge(status: status.status, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          _MetricRow(label: 'Face match', value: '${(status.similarityScore * 100).round()}%'),
          _MetricRow(label: 'Liveness', value: '${(status.livenessScore * 100).round()}%'),
          _MetricRow(label: 'Fraud risk', value: '${(status.fraudProbability * 100).round()}%'),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
