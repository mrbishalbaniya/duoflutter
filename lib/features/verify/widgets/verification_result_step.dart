import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/verification_domain.dart';
import '../models/verification_models.dart';
import 'verification_error_banner.dart';
import 'verification_timeline.dart';

class VerificationResultStep extends StatelessWidget {
  const VerificationResultStep({
    super.key,
    required this.result,
    required this.mode,
    required this.onTryAgain,
    this.session,
  });

  final VerificationStatusResponse result;
  final VerificationMode mode;
  final VoidCallback onTryAgain;
  final VerificationStartResponse? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, subtitle, icon, tone) = switch (result.status) {
      VerificationStatus.verified => (
          'Verified Profile',
          mode == VerificationMode.device
              ? 'You can close this screen and return to your other device.'
              : 'Your profile now shows a verified badge.',
          Icons.verified_rounded,
          VerificationBannerTone.success,
        ),
      VerificationStatus.underReview => (
          'Under Review',
          'Our team will review your submission shortly.',
          Icons.hourglass_top_rounded,
          VerificationBannerTone.warning,
        ),
      VerificationStatus.rejected => (
          'Verification Failed',
          'Please try again with better lighting and a clear front-facing photo.',
          Icons.cancel_rounded,
          VerificationBannerTone.warning,
        ),
      VerificationStatus.pending => (
          'Pending',
          'Your verification is still in progress.',
          Icons.pending_outlined,
          VerificationBannerTone.info,
        ),
    };

    final cardColor = switch (result.status) {
      VerificationStatus.verified => theme.colorScheme.primary.withValues(alpha: 0.1),
      VerificationStatus.underReview => Colors.amber.withValues(alpha: 0.12),
      VerificationStatus.rejected => theme.colorScheme.error.withValues(alpha: 0.08),
      VerificationStatus.pending => theme.colorScheme.secondary,
    };

    final borderColor = switch (result.status) {
      VerificationStatus.verified => theme.colorScheme.primary.withValues(alpha: 0.3),
      VerificationStatus.underReview => Colors.amber.withValues(alpha: 0.35),
      VerificationStatus.rejected => theme.colorScheme.error.withValues(alpha: 0.25),
      VerificationStatus.pending => theme.colorScheme.outline,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary)
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              _MetricRow(label: 'Face match', value: '${(result.similarityScore * 100).round()}%'),
              _MetricRow(label: 'Liveness', value: '${(result.livenessScore * 100).round()}%'),
              _MetricRow(label: 'Fraud risk', value: '${(result.fraudProbability * 100).round()}%'),
            ],
          ),
        ),
        if (session != null) ...[
          const SizedBox(height: 16),
          VerificationTimeline(
            currentStep: VerificationFlowStep.result,
            livenessSteps: session!.livenessSteps,
            completedSteps: result.session?.livenessStepsCompleted ?? const [],
            resultStatus: result.status,
          ),
        ],
        if (result.rejectionReasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...result.rejectionReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: VerificationInfoBanner(message: reason, tone: tone),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (result.status != VerificationStatus.verified) ...[
          OutlinedButton(
            onPressed: onTryAgain,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
        ],
        DuoGradientButton(
          label: mode == VerificationMode.device ? 'Done' : 'Back to Profile',
          onPressed: () {
            if (mode == VerificationMode.device) {
              context.go(AppRoutes.verify);
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
