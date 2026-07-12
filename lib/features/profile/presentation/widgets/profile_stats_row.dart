import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/theme/duo_theme.dart';

class ProfileStatItem {
  const ProfileStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final DuoProfile profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = [
      ProfileStatItem(
        label: 'Complete',
        value: '${profile.profileCompleteness}%',
        icon: Icons.pie_chart_outline_rounded,
      ),
      ProfileStatItem(
        label: 'Photos',
        value: '${profile.allPhotos.length}',
        icon: Icons.photo_library_outlined,
      ),
      ProfileStatItem(
        label: 'Verified',
        value: profile.isVerified ? 'Yes' : 'No',
        icon: Icons.verified_outlined,
      ),
      ProfileStatItem(
        label: 'Interests',
        value: '${profile.lifestyleTags.length}',
        icon: Icons.interests_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return RepaintBoundary(
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    item: stats[i],
                    compact: compact,
                    scheme: scheme,
                    index: i,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
    required this.compact,
    required this.scheme,
    required this.index,
  });

  final ProfileStatItem item;
  final bool compact;
  final ColorScheme scheme;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(item.icon, size: compact ? 18 : 20, color: DuoColors.primary),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + index * 80),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.92 + (0.08 * t), child: child),
            ),
            child: Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: compact ? 14 : 16,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    )
        .animate(delay: (60 * index).ms)
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
