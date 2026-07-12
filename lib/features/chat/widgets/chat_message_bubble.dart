import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../chat_utils.dart';
import '../domain/chat_message_selectors.dart';
import '../domain/chat_message_status.dart';
import '../providers/chat_thread_controller.dart';
import 'voice_message_bubble.dart';

class ChatMessageBubble extends ConsumerWidget {
  const ChatMessageBubble({
    super.key,
    required this.conversationId,
    required this.messageKey,
    required this.fallbackMessage,
    required this.showAvatar,
    required this.isGrouped,
    this.otherPhoto,
    this.maxBubbleWidth,
    this.animateEntrance = false,
    this.onReply,
    this.onReact,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onRetry,
    this.onImageTap,
  });

  final String conversationId;
  final String messageKey;
  final ChatMessage fallbackMessage;
  final bool showAvatar;
  final bool isGrouped;
  final String? otherPhoto;
  final double? maxBubbleWidth;
  final bool animateEntrance;
  final VoidCallback? onReply;
  final ValueChanged<String>? onReact;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final VoidCallback? onRetry;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      chatThreadControllerProvider(conversationId).select(
        (s) =>
            chatMessageForKey(s.visibleMessages, messageKey) ?? fallbackMessage,
      ),
    );

    if (!message.isVisible) return const SizedBox.shrink();

    final isMine = message.isMine;
    final maxWidth = maxBubbleWidth ?? MediaQuery.sizeOf(context).width * 0.78;
    final scheme = Theme.of(context).colorScheme;

    Widget row = Padding(
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
              child: (otherPhoto?.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 14)
                  : null,
            )
          else if (!isMine)
            const SizedBox(width: 28),
          if (!isMine && showAvatar) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context, message),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: scheme.outline),
                                ),
                                child: Text(
                                  '${e.key} ${e.value}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  if (isMine && !isVoiceOnlyMessage(message))
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatClockTime(message.timestamp),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
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
    );

    if (animateEntrance) {
      row = row
          .animate()
          .fadeIn(duration: 180.ms)
          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic, duration: 220.ms);
    }

    return row;
  }

  void _showActions(BuildContext context, ChatMessage message) {
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
    final voiceOnly = isVoiceOnlyMessage(message);
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;

    if (voiceOnly && !deleted && (message.imageUrl?.isNotEmpty ?? false)) {
      final player = VoiceMessageBubble(
        messageId: '${message.id}',
        audioUrl: message.imageUrl!,
        waveColor: isMine ? duo.chatVoiceWaveOutgoing : duo.chatVoiceWaveIncoming,
        onGradientBubble: isMine,
        compact: true,
      );

      return Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: isMine ? duo.chatOutgoingGradient : null,
          color: isMine ? null : duo.chatIncomingBackground,
          borderRadius: BorderRadius.circular(18),
          border: isMine
              ? null
              : Border.all(color: duo.chatIncomingBorder.withValues(alpha: 0.55)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            player,
            Positioned(
              bottom: 0,
              right: isMine ? 0 : null,
              left: isMine ? null : 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatClockTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: isMine
                          ? duo.chatOnOutgoing.withValues(alpha: 0.7)
                          : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _StatusIcon(message: message),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (imageOnly && !deleted) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: GestureDetector(
            onTap: onImageTap,
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: isAnimatedImageUrl(message.imageUrl) ? 320 : 640,
              filterQuality: FilterQuality.medium,
              placeholder: (_, __) => Container(
                height: 180,
                width: maxWidth,
                color: scheme.surfaceContainerHighest,
              ),
              errorWidget: (_, __, ___) => Container(
                height: 180,
                width: maxWidth,
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
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
        gradient: isMine ? duo.chatOutgoingGradient : null,
        color: isMine ? null : duo.chatIncomingBackground,
        borderRadius: radius,
        border: isMine
            ? null
            : Border.all(color: duo.chatIncomingBorder.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.replyTo != null) _ReplyQuote(reply: message.replyTo!),
          if ((message.imageUrl?.isNotEmpty ?? false) && !deleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: isVoiceMessage(message)
                  ? VoiceMessageBubble(
                      messageId: '${message.id}',
                      audioUrl: message.imageUrl!,
                      waveColor:
                          isMine ? duo.chatVoiceWaveOutgoing : duo.chatVoiceWaveIncoming,
                      onGradientBubble: isMine,
                      compact: true,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: onImageTap,
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: maxWidth - 28,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              isAnimatedImageUrl(message.imageUrl) ? 320 : 640,
                          filterQuality: FilterQuality.medium,
                          placeholder: (_, __) => Container(
                            height: 140,
                            color: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
            ),
          if (!isVoiceMessage(message))
            Text(
              deleted ? 'This message was deleted' : message.content,
              style: TextStyle(
                color: isMine ? duo.chatOnOutgoing : scheme.onSurface,
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
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    final sender = reply['sender_name'] as String? ?? '';
    final content = reply['content'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: duo.chatReplyScrim,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sender.isNotEmpty)
            Text(
              sender,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: scheme.primary,
              ),
            ),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.9),
            ),
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
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    switch (messageStatusIcon(message)) {
      case MessageStatusIcon.pending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: duo.chatOnOutgoing.withValues(alpha: 0.75),
          ),
        );
      case MessageStatusIcon.failed:
        return Icon(Icons.error_outline, size: 14, color: scheme.error);
      case MessageStatusIcon.read:
        return const Icon(Icons.done_all, size: 14, color: AppColors.chatReadReceipt);
      case MessageStatusIcon.delivered:
        return Icon(Icons.done_all, size: 14, color: duo.chatOnOutgoing.withValues(alpha: 0.75));
      case MessageStatusIcon.sent:
        return Icon(Icons.done, size: 14, color: duo.chatOnOutgoing.withValues(alpha: 0.75));
    }
  }
}
