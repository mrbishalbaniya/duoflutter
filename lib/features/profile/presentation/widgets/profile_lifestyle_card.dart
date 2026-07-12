import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/duo_theme.dart';

class ProfileLifestyleCard extends StatelessWidget {
  const ProfileLifestyleCard({
    super.key,
    required this.tags,
    this.animationIndex = 0,
  });

  final List<String> tags;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: tags.isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Icon(Icons.style_outlined, color: scheme.primary),
          title: const Text(
            'Lifestyle & interests',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          children: [
            if (tags.isEmpty)
              Text(
                'No lifestyle tags yet.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: DuoColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: DuoColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: DuoColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    )
        .animate(delay: (50 * animationIndex).ms)
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.03, end: 0);
  }
}
