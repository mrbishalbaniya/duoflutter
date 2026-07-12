import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionProgressHeader extends StatelessWidget {
  const PermissionProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.accent,
  });

  final int currentStep;
  final int totalSteps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: accent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                color: accent,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final active = index == currentStep;
            final done = index < currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: done
                    ? accent.withValues(alpha: 0.55)
                    : active
                        ? accent
                        : scheme.outline.withValues(alpha: 0.28),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

class PermissionBenefitChips extends StatelessWidget {
  const PermissionBenefitChips({super.key, required this.benefits, required this.accent});

  final List<String> benefits;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: benefits
          .map(
            (benefit) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Text(
                benefit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
