import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../chat_utils.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onPin,
    this.onMute,
    this.onArchive,
    this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final photo = conversation.otherUserProfile.displayPhoto;
    final typing = conversation.isOtherUserTyping;
    final scheme = Theme.of(context).colorScheme;
    final preview = typing
        ? 'Typing…'
        : (conversation.lastMessage?.isMine ?? false)
            ? 'You: ${lastMessagePreview(conversation)}'
            : lastMessagePreview(conversation);
    final time = formatMessageTime(conversationActivityIso(conversation));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage:
                        photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                    child: photo.isEmpty ? const Icon(Icons.person, size: 28) : null,
                  ),
                  if (typing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  conversation.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (conversation.otherUserProfile.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.verified, size: 16, color: Colors.lightBlue.shade300),
                              ],
                              if (conversation.isPinned) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.push_pin, size: 14, color: DuoColors.primary),
                              ],
                              if (conversation.isMuted) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.notifications_off_outlined,
                                    size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ],
                            ],
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: typing
                                      ? DuoColors.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: typing ? FontWeight.w600 : FontWeight.w400,
                                ),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: DuoColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onSelected: (value) {
                  switch (value) {
                    case 'pin':
                      onPin?.call();
                    case 'mute':
                      onMute?.call();
                    case 'archive':
                      onArchive?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(conversation.isArchived ? 'Unarchive' : 'Archive'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete chat')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
