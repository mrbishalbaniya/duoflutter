import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';

const _levelLabels = <String, String>{
  'low': 'Low activity',
  'moderate': 'Moderate activity',
  'high': 'High activity',
  'trending': 'Trending zone',
  'viral': 'Viral zone',
};

/// Web-parity floating zone popup (`ZonePopup.tsx`).
class ZonePopupCard extends StatelessWidget {
  const ZonePopupCard({
    super.key,
    required this.zone,
    required this.onClose,
    required this.onOpenDetails,
  });

  final ActivityZone zone;
  final VoidCallback onClose;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelLabel = _levelLabels[zone.level] ?? 'Activity zone';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: DuoColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        zone.name.isNotEmpty ? zone.name : 'Activity zone',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat(value: '${zone.activeUsers}', label: 'Active'),
                const SizedBox(width: 16),
                _Stat(value: '${zone.score.round()}', label: 'Score'),
                if (zone.friendsActive > 0) ...[
                  const SizedBox(width: 16),
                  _Stat(value: '${zone.friendsActive}', label: 'Friends'),
                ],
              ],
            ),
            if (zone.badges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  for (final badge in zone.badges)
                    Chip(
                      label: Text(badge),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenDetails,
                child: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutCubic);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
