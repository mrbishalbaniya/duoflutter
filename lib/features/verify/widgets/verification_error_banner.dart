import 'package:flutter/material.dart';

class VerificationErrorBanner extends StatelessWidget {
  const VerificationErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}

class VerificationInfoBanner extends StatelessWidget {
  const VerificationInfoBanner({
    super.key,
    required this.message,
    this.tone = VerificationBannerTone.info,
  });

  final String message;
  final VerificationBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, border, fg) = switch (tone) {
      VerificationBannerTone.info => (
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.primary.withValues(alpha: 0.2),
          theme.colorScheme.onSurface,
        ),
      VerificationBannerTone.warning => (
          Colors.amber.withValues(alpha: 0.12),
          Colors.amber.withValues(alpha: 0.35),
          Colors.amber.shade900,
        ),
      VerificationBannerTone.success => (
          theme.colorScheme.primary.withValues(alpha: 0.1),
          theme.colorScheme.primary.withValues(alpha: 0.2),
          theme.colorScheme.primary,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
    );
  }
}

enum VerificationBannerTone { info, warning, success }
