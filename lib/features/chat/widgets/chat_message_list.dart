import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/chat_message_list_entry.dart';
import 'chat_message_bubble.dart';

typedef ChatMessageAction = void Function();

/// Isolated, repaint-bounded message row for the reverse ListView.
class ChatMessageListTile extends StatelessWidget {
  const ChatMessageListTile({
    super.key,
    required this.conversationId,
    required this.entry,
    required this.otherPhoto,
    required this.maxBubbleWidth,
    required this.animateEntrance,
    this.onReply,
    this.onReact,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onRetry,
    this.onImageTap,
  });

  final String conversationId;
  final ChatMessageListEntry entry;
  final String? otherPhoto;
  final double maxBubbleWidth;
  final bool animateEntrance;
  final ChatMessageAction? onReply;
  final ValueChanged<String>? onReact;
  final ChatMessageAction? onDeleteForMe;
  final ChatMessageAction? onDeleteForEveryone;
  final ChatMessageAction? onRetry;
  final ChatMessageAction? onImageTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.showDateSeparator)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                entry.dateLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ChatMessageBubble(
            conversationId: conversationId,
            messageKey: entry.stableKey,
            fallbackMessage: entry.message,
            showAvatar: entry.showAvatar,
            isGrouped: entry.isGrouped,
            otherPhoto: otherPhoto,
            maxBubbleWidth: maxBubbleWidth,
            animateEntrance: animateEntrance,
            onReply: onReply,
            onReact: onReact,
            onDeleteForMe: onDeleteForMe,
            onDeleteForEveryone: onDeleteForEveryone,
            onRetry: onRetry,
            onImageTap: onImageTap,
          ),
        ],
      ),
    );
  }
}

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({
    super.key,
    required this.conversationId,
    required this.entries,
    required this.loadingEarlier,
    required this.otherPhoto,
    required this.scrollController,
    required this.onReply,
    required this.onReact,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
    required this.onRetry,
    required this.onImageTap,
  });

  final String conversationId;
  final List<ChatMessageListEntry> entries;
  final bool loadingEarlier;
  final String? otherPhoto;
  final ScrollController scrollController;
  final void Function(ChatMessageListEntry entry) onReply;
  final void Function(ChatMessageListEntry entry, String emoji) onReact;
  final void Function(ChatMessageListEntry entry) onDeleteForMe;
  final void Function(ChatMessageListEntry entry) onDeleteForEveryone;
  final void Function(ChatMessageListEntry entry) onRetry;
  final void Function(ChatMessageListEntry entry) onImageTap;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _animatedKeys = <String>{};
  bool _allowEntranceAnimation = false;
  double? _maxBubbleWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _allowEntranceAnimation = true;
        _animatedKeys.addAll(widget.entries.map((e) => e.stableKey));
      });
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _maxBubbleWidth ??= MediaQuery.sizeOf(context).width * 0.78;
    final entries = widget.entries;

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemCount = entries.length + (widget.loadingEarlier ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      // ignore: deprecated_member_use
      cacheExtent: 720,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      findChildIndexCallback: (Key key) {
        if (key is! ValueKey<String>) return null;
        final entryIndex = entries.indexWhere((e) => e.stableKey == key.value);
        if (entryIndex < 0) return null;
        return entries.length - 1 - entryIndex;
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (widget.loadingEarlier && index == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final entry = entries[entries.length - 1 - index];
        final shouldAnimate = _allowEntranceAnimation &&
            !_animatedKeys.contains(entry.stableKey);
        if (shouldAnimate) {
          _animatedKeys.add(entry.stableKey);
        }

        return ChatMessageListTile(
          key: ValueKey(entry.stableKey),
          conversationId: widget.conversationId,
          entry: entry,
          otherPhoto: widget.otherPhoto,
          maxBubbleWidth: _maxBubbleWidth!,
          animateEntrance: shouldAnimate,
          onReply: () => widget.onReply(entry),
          onReact: (emoji) => widget.onReact(entry, emoji),
          onDeleteForMe: () => widget.onDeleteForMe(entry),
          onDeleteForEveryone: () => widget.onDeleteForEveryone(entry),
          onRetry: () => widget.onRetry(entry),
          onImageTap: () => widget.onImageTap(entry),
        );
      },
    );
  }
}

/// Full-screen image preview with disk/memory cache.
void openChatImagePreview(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Hero(
        tag: 'chat-image-$url',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    ),
  );
}
