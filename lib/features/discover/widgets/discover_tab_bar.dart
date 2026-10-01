import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/discover_models.dart';
import '../providers/discover_providers.dart';

class DiscoverTabBar extends ConsumerWidget {
  const DiscoverTabBar({super.key, required this.counts});

  final Map<DiscoverTab, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(discoverTabProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (final tab in DiscoverTab.values)
              Expanded(
                child: _TabChip(
                  label: _label(tab),
                  count: counts[tab] ?? 0,
                  selected: active == tab,
                  onTap: () => ref.read(discoverTabProvider.notifier).state = tab,
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.04, end: 0);
  }

  String _label(DiscoverTab tab) => switch (tab) {
        DiscoverTab.visitors => 'Visited',
        DiscoverTab.sent => 'Sent',
        DiscoverTab.received => 'Liked you',
        DiscoverTab.matched => 'Matched',
      };
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: selected ? DuoColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            // Count as a tiny superscript after the label: "Sent³".
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (count > 0)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Transform.translate(
                        offset: const Offset(1.5, -5),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white.withValues(alpha: 0.9) : DuoColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
