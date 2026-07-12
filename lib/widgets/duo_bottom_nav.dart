import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/duo_gradients.dart';
import '../core/theme/duo_theme.dart';

class DuoBottomNav extends StatelessWidget {
  const DuoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  static const _items = [
    (icon: Icons.group_outlined, active: Icons.group, label: 'Discover'),
    (icon: Icons.chat_bubble_outline, active: Icons.chat_bubble, label: 'Chat'),
    (icon: Icons.favorite_border, active: Icons.favorite, label: 'Match'),
    (icon: Icons.map_outlined, active: Icons.map, label: 'Map'),
    (icon: Icons.person_outline, active: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.paddingOf(context).bottom + 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: DuoColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              height: 72,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final selected = currentIndex == index;
                  final isCenter = index == 2;

                  if (isCenter) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -10),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: selected ? DuoGradients.brandBr : null,
                                  color: selected ? null : scheme.surfaceContainerHighest,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : scheme.outline.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DuoColors.primary.withValues(
                                        alpha: selected ? 0.35 : 0.12,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  selected ? item.active : item.icon,
                                  size: 28,
                                  color: selected ? Colors.white : DuoColors.primary,
                                ),
                              ),
                            ),
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
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                selected ? item.active : item.icon,
                                size: 22,
                                color: selected ? DuoColors.primary : scheme.onSurfaceVariant,
                              ),
                              if (index == 1 && unreadCount > 0)
                                Positioned(
                                  right: -10,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: DuoColors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? DuoColors.primary : scheme.onSurfaceVariant,
                            ),
                          ),
                          if (selected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: DuoColors.primary,
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
