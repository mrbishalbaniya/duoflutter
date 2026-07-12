import 'package:flutter/material.dart';

import '../models/verification_models.dart';

class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final VerificationStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, icon, bg, fg) = switch (status) {
      VerificationStatus.verified => (
          'Verified',
          Icons.verified_rounded,
          theme.colorScheme.primary.withValues(alpha: 0.12),
          theme.colorScheme.primary,
        ),
      VerificationStatus.rejected => (
          'Rejected',
          Icons.cancel_rounded,
          theme.colorScheme.error.withValues(alpha: 0.12),
          theme.colorScheme.error,
        ),
      VerificationStatus.underReview => (
          'Under review',
          Icons.hourglass_top_rounded,
          Colors.amber.withValues(alpha: 0.15),
          Colors.amber.shade800,
        ),
      VerificationStatus.pending => (
          'Pending',
          Icons.pending_outlined,
          theme.colorScheme.secondary,
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 16 : 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
