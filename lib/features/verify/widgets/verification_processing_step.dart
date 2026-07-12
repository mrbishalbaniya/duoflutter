import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerificationProcessingStep extends StatefulWidget {
  const VerificationProcessingStep({super.key});

  @override
  State<VerificationProcessingStep> createState() => _VerificationProcessingStepState();
}

class _VerificationProcessingStepState extends State<VerificationProcessingStep> {
  static const _stages = [
    'Analyzing selfie',
    'Matching profile photos',
    'Running liveness checks',
    'Submitting verification',
  ];

  int _activeStage = 0;

  @override
  void initState() {
    super.initState();
    _advanceStages();
  }

  Future<void> _advanceStages() async {
    for (var i = 1; i < _stages.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _activeStage = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 4),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms),
            const SizedBox(height: 24),
            Text('Verifying your identity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This usually takes a few seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ...List.generate(_stages.length, (index) {
              final done = index < _activeStage;
              final active = index == _activeStage;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      done
                          ? Icons.check_circle_rounded
                          : active
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                      size: 20,
                      color: done || active
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _stages[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
