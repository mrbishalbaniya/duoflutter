import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/theme/duo_theme.dart';
import '../../domain/profile_domain.dart';

class ProfileCompletenessCard extends StatelessWidget {
  const ProfileCompletenessCard({super.key, required this.profile});

  final DuoProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checklist = profileCompletenessChecklist(profile);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DuoColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Profile completeness',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: profile.profileCompleteness),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '$value%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: profile.profileCompleteness / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final item in checklist)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    size: 18,
                    semanticLabel: item.done ? 'Completed' : 'Incomplete',
                    color: item.done ? DuoColors.esewaGreen : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.done ? scheme.onSurface : scheme.onSurfaceVariant,
                        fontWeight: item.done ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }
}
