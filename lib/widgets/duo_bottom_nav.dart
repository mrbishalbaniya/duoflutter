import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/appearance.dart';
import '../core/theme/nav_icon_sets.dart';

import '../core/theme/theme_extensions.dart';

class DuoBottomNav extends ConsumerWidget {
  const DuoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  static const _labels = ['Discover', 'Chat', 'Match', 'Map', 'Profile'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final set = navIconSetById(ref.watch(appearanceProvider.select((a) => a.iconSet)));
    final items = [
      for (var i = 0; i < _labels.length; i++)
        (icon: set.icons[i].$1, active: set.icons[i].$2, label: _labels[i]),
    ];
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: duo.navBarSurface,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: duo.navBarBorder),
              boxShadow: [
                BoxShadow(
                  color: duo.cardShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final selected = currentIndex == index;
                  final isCenter = index == 2;

                  if (isCenter) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        // Circle sits fully inside the bar (the old -10px lift was
                        // clipped by the bar's rounded ClipRRect) and gets the same
                        // label as the other tabs so all five line up.
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _iconSlot,
                              height: _iconSlot,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: selected ? duo.brandBrGradient : null,
                                color: selected
                                    ? null
                                    : scheme.primary.withValues(alpha: 0.12),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: scheme.primary.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                selected ? item.active : item.icon,
                                size: 24,
                                color: selected
                                    ? scheme.onPrimary
                                    : scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 7), // matches dot (3 + 4)
                          ],
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: _iconSlot,
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    selected ? item.active : item.icon,
                                    size: 22,
                                    color: selected
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                  if (index == 1 && unreadCount > 0)
                                    Positioned(
                                      right: -10,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: duo.badgeBackground,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          style: TextStyle(
                                            color: duo.badgeForeground,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                          // Always reserve the dot's space so selecting a tab
                          // doesn't shift its label relative to the others.
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: selected
                                  ? scheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared icon area height so every tab's label sits on the same line.
const double _iconSlot = 40;
