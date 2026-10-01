import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/verification_domain.dart';
import '../models/verification_models.dart';

/// Result card, matching web VerificationFlow "result".
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
    final scheme = Theme.of(context).colorScheme;
    final verified = result.status == VerificationStatus.verified;

    final (Color tone, IconData icon, String title) = switch (result.status) {
      VerificationStatus.verified => (const Color(0xFF10B981), Icons.verified_rounded, "You're verified"),
      VerificationStatus.underReview => (const Color(0xFFF59E0B), Icons.hourglass_top_rounded, 'Under review'),
      VerificationStatus.pending => (const Color(0xFFF59E0B), Icons.hourglass_top_rounded, 'Under review'),
      VerificationStatus.rejected => (const Color(0xFFEF4444), Icons.close_rounded, "Couldn't verify you"),
    };
    final message = mode == VerificationMode.device && verified
        ? 'All done. You can close this and go back to your other device.'
        : verified
            ? 'Your profile now shows the verified badge.'
            : result.status == VerificationStatus.rejected
                ? 'Try again in good light, facing the camera.'
                : "Our team will check it shortly. We'll let you know.";

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: tone.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: tone.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: tone),
              ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.elasticOut, duration: 700.ms),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurfaceVariant),
              ),
              if (!verified && result.rejectionReasons.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final reason in result.rejectionReasons)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_rounded, size: 17, color: tone),
                              const SizedBox(width: 8),
                              Expanded(child: Text(reason, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0),
        const SizedBox(height: 24),
        DuoGradientButton(
          label: mode == VerificationMode.device ? 'Done' : 'Back to profile',
          onPressed: () => context.go(mode == VerificationMode.device ? AppRoutes.verify : AppRoutes.profile),
        ),
        if (!verified) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTryAgain,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: const StadiumBorder(),
              foregroundColor: scheme.primary,
            ),
            child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ],
    );
  }
}
