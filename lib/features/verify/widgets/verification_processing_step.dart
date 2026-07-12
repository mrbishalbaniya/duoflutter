import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerificationProcessingStep extends StatelessWidget {
  const VerificationProcessingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 4),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
          const SizedBox(height: 20),
          Text('Verifying your identity', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Comparing your selfie with profile photos and running security checks…',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
