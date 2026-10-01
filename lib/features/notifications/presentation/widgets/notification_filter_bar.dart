import 'package:flutter/material.dart';

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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

          final icon = switch (filter) {
            NotificationFilter.all => Icons.notifications_rounded,
            NotificationFilter.unread => Icons.mark_email_unread_rounded,
            NotificationFilter.messages => Icons.chat_bubble_rounded,
            NotificationFilter.matches => Icons.favorite_rounded,
            NotificationFilter.likes => Icons.thumb_up_alt_rounded,
          };
          final scheme = Theme.of(context).colorScheme;

          return ChoiceChip(
            avatar: Icon(icon, size: 16, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onChanged(filter),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            selectedColor: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            shape: const StadiumBorder(),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          );
        },
      ),
    );
  }
}
