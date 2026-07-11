import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
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
                          offset: const Offset(0, -8),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [DuoColors.primary, DuoColors.primaryContainer],
                                    )
                                  : null,
                              color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: DuoColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              selected ? item.active : item.icon,
                              color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            selected ? item.active : item.icon,
                            color: selected
                                ? DuoColors.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          if (index == 1 && unreadCount > 0)
                            Positioned(
                              right: -8,
                              top: -4,
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
                          color: selected
                              ? DuoColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}
