import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';
import '../map_utils.dart';

class ZoneDetailSheet extends StatelessWidget {
  const ZoneDetailSheet({
    super.key,
    required this.zone,
    required this.onClose,
  });

  final ActivityZone zone;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = activityZoneColor(zone.level);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(color.argb),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _levelLabel(zone.level),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            Text(
              zone.name.isNotEmpty ? zone.name : 'Activity zone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatTile(label: 'Active users', value: '${zone.activeUsers}'),
                const SizedBox(width: 12),
                _StatTile(label: 'Score', value: zone.score.round().toString()),
                if (zone.friendsActive > 0) ...[
                  const SizedBox(width: 12),
                  _StatTile(label: 'Friends', value: '${zone.friendsActive}'),
                ],
              ],
            ),
            if (zone.badges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final badge in zone.badges)
                    Chip(
                      label: Text(badge),
                      backgroundColor: DuoColors.primary.withValues(alpha: 0.12),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  String _levelLabel(String level) => switch (level) {
        'viral' => 'Viral zone',
        'trending' => 'Trending zone',
        'high' => 'High activity',
        'moderate' => 'Moderate activity',
        _ => 'Low activity',
      };
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
