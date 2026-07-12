import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../chat_utils.dart';
import '../domain/chat_message_status.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.showAvatar,
    required this.isGrouped,
    this.otherPhoto,
    this.onReply,
    this.onReact,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onRetry,
    this.onImageTap,
    this.animationIndex = 0,
  });

  final ChatMessage message;
  final bool showAvatar;
  final bool isGrouped;
  final String? otherPhoto;
  final VoidCallback? onReply;
  final ValueChanged<String>? onReact;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final VoidCallback? onRetry;
  final VoidCallback? onImageTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    if (!message.isVisible) return const SizedBox.shrink();

    final isMine = message.isMine;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        top: isGrouped ? 2 : 8,
        bottom: 2,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && showAvatar)
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: (otherPhoto?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(otherPhoto!)
                  : null,
              child: (otherPhoto?.isEmpty ?? true) ? const Icon(Icons.person, size: 14) : null,
            )
          else if (!isMine)
            const SizedBox(width: 28),
          if (!isMine && showAvatar) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              onTap: message.sendStatus == MessageSendStatus.failed ? onRetry : null,
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _BubbleBody(
                    message: message,
                    maxWidth: maxWidth,
                    onImageTap: onImageTap,
                  ),
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.entries
                            .map(
                              (e) => Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: scheme.outline),
                                ),
                                child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (isMine)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatClockTime(message.timestamp),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(width: 4),
                          _StatusIcon(message: message),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms, delay: (animationIndex.clamp(0, 6) * 30).ms)
        .slideY(
          begin: isMine ? 0.08 : 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 280.ms,
        );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: quickReactionEmojis
                  .map(
                    (emoji) => IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onReact?.call(emoji);
                      },
                      icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  )
                  .toList(),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: message.content));
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
            if (message.isMine && !message.isDeletedForEveryone)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteForEveryone?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for me'),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteForMe?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.message,
    required this.maxWidth,
    this.onImageTap,
  });

  final ChatMessage message;
  final double maxWidth;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final deleted = message.isDeletedForEveryone;
    final imageOnly = isImageOnlyMessage(message);
    final scheme = Theme.of(context).colorScheme;

    if (imageOnly && !deleted) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 280),
          child: GestureDetector(
            onTap: onImageTap,
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      );
    }

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        gradient: isMine
            ? const LinearGradient(
                colors: [DuoColors.primary, DuoColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMine ? null : scheme.surfaceContainerHighest,
        borderRadius: radius,
        border: isMine ? null : Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyTo != null) _ReplyQuote(reply: message.replyTo!),
          if ((message.imageUrl?.isNotEmpty ?? false) && !deleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: onImageTap,
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    width: maxWidth - 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (isVoiceMessage(message))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, size: 18, color: isMine ? Colors.white : DuoColors.primary),
                const SizedBox(width: 8),
                Text(
                  voiceMessageLabel,
                  style: TextStyle(
                    color: isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else
            Text(
              deleted ? 'This message was deleted' : message.content,
              style: TextStyle(
                color: isMine ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply});

  final Map<String, dynamic> reply;

  @override
  Widget build(BuildContext context) {
    final sender = reply['sender_name'] as String? ?? '';
    final content = reply['content'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: DuoColors.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sender.isNotEmpty)
            Text(sender, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    switch (messageStatusIcon(message)) {
      case MessageStatusIcon.pending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
        );
      case MessageStatusIcon.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
      case MessageStatusIcon.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlue.shade200,
        );
      case MessageStatusIcon.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatusIcon.sent:
        return const Icon(Icons.done, size: 14, color: Colors.white70);
    }
  }
}
