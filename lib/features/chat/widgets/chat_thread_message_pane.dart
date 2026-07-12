import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_message_selectors.dart';
import '../providers/chat_thread_controller.dart';
import 'chat_message_list.dart';
import 'chat_media_viewer.dart';
import 'chat_shimmer.dart';
import 'chat_typing_indicator.dart';

/// Message list body — watches only list-related state slices.
class ChatThreadMessagePane extends ConsumerStatefulWidget {
  const ChatThreadMessagePane({
    super.key,
    required this.conversationId,
    required this.scrollController,
    required this.onSetRetryText,
  });

  final String conversationId;
  final ScrollController scrollController;
  final void Function(String text) onSetRetryText;

  @override
  ConsumerState<ChatThreadMessagePane> createState() =>
      _ChatThreadMessagePaneState();
}

class _ChatThreadMessagePaneState extends ConsumerState<ChatThreadMessagePane> {
  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      chatThreadControllerProvider(widget.conversationId)
          .select((s) => s.loading),
    );
    final listSlice = ref.watch(
      chatThreadControllerProvider(widget.conversationId).select(
        (s) => (
          chatListStructureRevision(s.listEntries),
          s.listEntries.length,
          s.loadingEarlier,
          s.error,
          s.conversation?.otherUserProfile.displayPhoto,
          s.isOtherUserTyping,
        ),
      ),
    );

    final structureRevision = listSlice.$1;
    final entryCount = listSlice.$2;
    final loadingEarlier = listSlice.$3;
    final error = listSlice.$4;
    final otherPhoto = listSlice.$5;
    final isOtherUserTyping = listSlice.$6;
    final notifier =
        ref.read(chatThreadControllerProvider(widget.conversationId).notifier);

    if (loading) {
      return const ChatThreadShimmer();
    }

    final entries = ref
        .read(chatThreadControllerProvider(widget.conversationId))
        .listEntries;

    if (entryCount == 0 && error != null) {
      return _ChatLoadError(
        message: error,
        onRetry: notifier.load,
      );
    }

    if (entryCount == 0) {
      return const _ChatEmptyState();
    }

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        ChatMessageList(
          key: ValueKey('chat-list-$structureRevision'),
          conversationId: widget.conversationId,
          entries: entries,
          loadingEarlier: loadingEarlier,
          otherPhoto: otherPhoto,
          scrollController: widget.scrollController,
          onReply: (entry) => notifier.setReplyingTo(entry.message),
          onReact: (entry, emoji) => notifier.react(entry.message, emoji),
          onDeleteForMe: (entry) => notifier.deleteMessage(entry.message, 'for_me'),
          onDeleteForEveryone: (entry) =>
              notifier.deleteMessage(entry.message, 'for_everyone'),
          onRetry: (entry) => notifier.retryFailed(
            entry.message,
            widget.onSetRetryText,
          ),
          onImageTap: (entry) {
            final msg = entry.message;
            if (msg.imageUrl?.isNotEmpty ?? false) {
              openChatMediaViewer(
                context,
                message: msg,
                onReply: () => notifier.setReplyingTo(msg),
                onDeleteForMe: () => notifier.deleteMessage(msg, 'for_me'),
                onDeleteForEveryone: () =>
                    notifier.deleteMessage(msg, 'for_everyone'),
              );
            }
          },
        ),
        if (isOtherUserTyping)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: ChatTypingIndicator(
              compact: true,
              avatarUrl: otherPhoto?.isNotEmpty == true ? otherPhoto : null,
            ),
          ),
      ],
    );
  }
}

class _ChatLoadError extends StatelessWidget {
  const _ChatLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text('Could not load messages', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text('Say hello!', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Send a message to start the conversation.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
