import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/theme/duo_theme.dart';
import '../../domain/notification_item.dart';

/// Accent colour per notification type (shared by card + filter chips).
Color notificationAccent(DuoNotificationType type) {
  return switch (type) {
    DuoNotificationType.chatMessage || DuoNotificationType.messageReaction => const Color(0xFF5C8DFF),
    DuoNotificationType.profileLike || DuoNotificationType.superLike => DuoColors.primary,
    DuoNotificationType.newMatch => const Color(0xFFE91E8C),
    DuoNotificationType.callIncoming => const Color(0xFF22C55E),
    DuoNotificationType.callMissed => const Color(0xFFF59E0B),
    DuoNotificationType.updateAvailable => const Color(0xFFD4A574),
    DuoNotificationType.securityAlert => const Color(0xFFEF4444),
    DuoNotificationType.profileViewed => const Color(0xFF8B5CF6),
    DuoNotificationType.verificationUpdate ||
    DuoNotificationType.profileVerified ||
    DuoNotificationType.photoApproved =>
      const Color(0xFF22C55E),
    DuoNotificationType.paymentSuccess ||
    DuoNotificationType.paymentFailure ||
    DuoNotificationType.subscriptionPurchased ||
    DuoNotificationType.subscriptionExpired =>
      const Color(0xFFD4A574),
    _ => DuoColors.primaryContainer,
  };
}

/// Material icon per type (cleaner than emoji, matches the rest of the app).
IconData notificationIcon(DuoNotificationType type) {
  return switch (type) {
    DuoNotificationType.chatMessage => Icons.chat_bubble_rounded,
    DuoNotificationType.messageReaction => Icons.emoji_emotions_rounded,
    DuoNotificationType.profileLike => Icons.favorite_rounded,
    DuoNotificationType.superLike => Icons.star_rounded,
    DuoNotificationType.newMatch => Icons.favorite_rounded,
    DuoNotificationType.profileViewed => Icons.visibility_rounded,
    DuoNotificationType.profileVerified ||
    DuoNotificationType.verificationUpdate =>
      Icons.verified_rounded,
    DuoNotificationType.photoApproved => Icons.photo_rounded,
    DuoNotificationType.subscriptionPurchased ||
    DuoNotificationType.subscriptionExpired =>
      Icons.workspace_premium_rounded,
    DuoNotificationType.paymentSuccess => Icons.check_circle_rounded,
    DuoNotificationType.paymentFailure => Icons.error_rounded,
    DuoNotificationType.securityAlert => Icons.shield_rounded,
    DuoNotificationType.callIncoming => Icons.call_rounded,
    DuoNotificationType.callMissed => Icons.phone_missed_rounded,
    DuoNotificationType.updateAvailable => Icons.system_update_rounded,
    DuoNotificationType.adminAnnouncement ||
    DuoNotificationType.systemMaintenance =>
      Icons.campaign_rounded,
    _ => Icons.notifications_rounded,
  };
}

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
    final accent = notificationAccent(item.type);
    final unread = !item.isRead;
    final radius = BorderRadius.circular(20);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : unread
                ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.06), scheme.surfaceContainerHigh)
                : scheme.surfaceContainerLow,
        border: Border.all(
          color: selected
              ? scheme.primary
              : unread
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outlineVariant.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent strip marks unread items at a glance.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: unread ? 4 : 0,
                color: accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: selectionMode
                            ? Padding(
                                key: const ValueKey('check'),
                                padding: const EdgeInsets.only(right: 10, top: 12),
                                child: Icon(
                                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('none')),
                      ),
                      _Avatar(item: item, accent: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatNotificationTime(item.receivedAt),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                    color: unread ? scheme.primary : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (item.body.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.35,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(notificationIcon(item.type), size: 13, color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  item.type.label,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
                                ),
                                const Spacer(),
                                if (unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Slidable(
        key: ValueKey(item.id),
        enabled: !selectionMode,
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onMarkRead();
              },
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              borderRadius: radius,
              child: _SlideLabel(
                icon: item.isRead ? Icons.mark_email_unread_rounded : Icons.done_all_rounded,
                label: item.isRead ? 'Unread' : 'Read',
              ),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onDelete();
              },
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              borderRadius: radius,
              child: const _SlideLabel(icon: Icons.delete_rounded, label: 'Delete'),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: selectionMode ? onSelectToggle : onTap,
            onLongPress: onLongPress,
            child: card,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms, delay: (animationIndex.clamp(0, 8) * 35).ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

class _SlideLabel extends StatelessWidget {
  const _SlideLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item, required this.accent});

  final NotificationItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = item.imageUrl.isNotEmpty ? item.imageUrl : item.iconUrl;
    final fallback = Icon(notificationIcon(item.type), color: accent, size: 22);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.08)],
              ),
            ),
            child: image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(child: fallback),
                  )
                : Center(child: fallback),
          ),
          // Type badge only when a photo hides the type icon.
          if (image.isNotEmpty)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(notificationIcon(item.type), size: 11, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
