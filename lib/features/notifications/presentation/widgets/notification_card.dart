import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/theme/duo_theme.dart';
import '../../domain/notification_item.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
    this.onSelectToggle,
    this.animationIndex = 0,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectToggle;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentFor(item.type);

    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onMarkRead();
            },
            backgroundColor: DuoColors.primary,
            foregroundColor: Colors.white,
            icon: item.isRead ? Icons.mark_email_unread_outlined : Icons.done_all,
            label: item.isRead ? 'Unread' : 'Read',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selectionMode ? onSelectToggle : onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.isRead
                  ? scheme.surfaceContainerLow
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? DuoColors.primary
                    : scheme.outlineVariant.withValues(alpha: 0.45),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 8),
                    child: Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected ? DuoColors.primary : scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                _Avatar(item: item, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${item.type.emoji} ${item.type.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatNotificationTime(item.receivedAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    decoration: const BoxDecoration(
                      color: DuoColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 220.ms,
          delay: (animationIndex.clamp(0, 8) * 35).ms,
        )
        .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }

  Color _accentFor(DuoNotificationType type) {
    return switch (type) {
      DuoNotificationType.chatMessage => const Color(0xFF5C8DFF),
      DuoNotificationType.profileLike => DuoColors.primary,
      DuoNotificationType.newMatch => const Color(0xFFE91E8C),
      DuoNotificationType.callIncoming => const Color(0xFF4CAF50),
      DuoNotificationType.callMissed => const Color(0xFFFF9800),
      DuoNotificationType.unknown => DuoColors.primaryContainer,
    };
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item, required this.accent});

  final NotificationItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl.isNotEmpty ? item.imageUrl : item.iconUrl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accent.withValues(alpha: 0.15),
          backgroundImage: image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
          child: image.isEmpty
              ? Text(item.type.emoji, style: const TextStyle(fontSize: 18))
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
            ),
            child: Center(
              child: Text(
                item.type.emoji,
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
