import 'package:flutter/material.dart';

import '../../../../core/theme/duo_theme.dart';
import '../../domain/notification_item.dart';

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    required this.active,
    required this.onChanged,
    required this.unreadCount,
  });

  final NotificationFilter active;
  final ValueChanged<NotificationFilter> onChanged;
  final int unreadCount;

  static const _filters = [
    NotificationFilter.all,
    NotificationFilter.unread,
    NotificationFilter.messages,
    NotificationFilter.matches,
    NotificationFilter.likes,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final selected = filter == active;
          final label = switch (filter) {
            NotificationFilter.all => 'All',
            NotificationFilter.unread => unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
            NotificationFilter.messages => 'Messages',
            NotificationFilter.matches => 'Matches',
            NotificationFilter.likes => 'Likes',
          };

          return FilterChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onChanged(filter),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedColor: DuoColors.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: selected
                  ? DuoColors.primary
                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          );
        },
      ),
    );
  }
}
