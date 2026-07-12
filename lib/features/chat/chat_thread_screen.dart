import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/chat_models.dart';
import 'chat_utils.dart';
import 'providers/chat_thread_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_dialogs.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_shimmer.dart';
import 'widgets/chat_thread_header.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _wasLoadingEarlier = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 48) {
      ref
          .read(chatThreadControllerProvider(widget.conversationId).notifier)
          .onScrollNearTop();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels <= 96;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      ref
          .read(chatThreadControllerProvider(widget.conversationId).notifier)
          .markInitialScrollDone();
    });
  }

  void _preserveScrollAfterPrepend(int previousCount, int newCount) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final added = newCount - previousCount;
      if (added <= 0) return;
      final estimatedAddedHeight = added * 72.0;
      _scrollController.jumpTo(_scrollController.offset + estimatedAddedHeight);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatThreadControllerProvider(widget.conversationId));
    final notifier =
        ref.read(chatThreadControllerProvider(widget.conversationId).notifier);

    ref.listen(chatThreadControllerProvider(widget.conversationId), (prev, next) {
      if (prev?.loading == true && next.loading == false) {
        _scrollToBottom(jump: true);
      }
      if (next.initialScrollPending && next.messages.isNotEmpty) {
        _scrollToBottom(jump: true);
      }

      final prevCount = prev?.messages.length ?? _lastMessageCount;
      final nextCount = next.messages.length;
      if (nextCount != prevCount) {
        if (_wasLoadingEarlier && next.loadingEarlier == false) {
          _preserveScrollAfterPrepend(prevCount, nextCount);
        } else if (nextCount > prevCount) {
          final grewAtEnd = next.messages.isNotEmpty &&
              ((prev?.messages.isEmpty ?? true) ||
                  next.messages.last.clientTempId != prev?.messages.last.clientTempId ||
                  next.messages.last.id != prev?.messages.last.id);
          if (grewAtEnd && (_isNearBottom() || next.messages.last.isMine)) {
            _scrollToBottom();
          }
        }
        _lastMessageCount = nextCount;
      }
      _wasLoadingEarlier = next.loadingEarlier;

      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        notifier.clearError();
      }
    });

    final convo = thread.conversation;
    final visibleMessages = thread.visibleMessages;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: convo == null
          ? AppBar(
              title: const Text('Chat'),
              bottom: thread.loading
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : null,
            )
          : ChatThreadHeader(
              conversation: convo,
              isOtherUserTyping: thread.isOtherUserTyping,
              wsConnected: thread.wsConnected,
              onVoiceCall: () => _showCallSnack(context, 'Voice call'),
              onVideoCall: () => _showCallSnack(context, 'Video call'),
              onMute: () => notifier.updateSettings(muted: !convo.isMuted),
              onPin: () => notifier.updateSettings(pinned: !convo.isPinned),
              onNickname: () async {
                final nickname = await showNicknameDialog(
                  context,
                  currentName: convo.otherUserProfile.displayName,
                  initialNickname: convo.otherUserNickname,
                );
                if (nickname != null) await notifier.setNickname(nickname);
              },
              onClearHistory: () async {
                final ok = await showClearHistoryDialog(context);
                if (ok) await notifier.clearHistory();
              },
              onReport: () async {
                final reason = await showReportDialog(context);
                if (reason != null) {
                  final ok = await notifier.report(reason);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. Thank you.')),
                    );
                  }
                }
              },
              onUnmatch: () async {
                final ok = await showUnmatchDialog(context);
                if (ok) {
                  final success = await notifier.unmatch();
                  if (success && context.mounted) context.pop();
                }
              },
            ),
      body: Column(
        children: [
          if (!thread.wsConnected && !thread.loading)
            MaterialBanner(
              content: const Text('Reconnecting… messages may be delayed'),
              leading: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              actions: [
                TextButton(
                  onPressed: () => notifier.reconnect(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: thread.loading
                ? const ChatThreadShimmer()
                : visibleMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Say hello!',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send a message to start the conversation.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount:
                            visibleMessages.length + (thread.loadingEarlier ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (thread.loadingEarlier && index == 0) {
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
                          final msgIndex = thread.loadingEarlier ? index - 1 : index;
                          final msg = visibleMessages[msgIndex];
                          final previous =
                              msgIndex > 0 ? visibleMessages[msgIndex - 1] : null;
                          final grouped = isGroupedWithPrevious(msg, previous);
                          final showDate = shouldShowDateSeparator(msg, previous);

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    dateSeparatorLabel(msg.timestamp),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ChatMessageBubble(
                                message: msg,
                                showAvatar: !grouped,
                                isGrouped: grouped,
                                otherPhoto: convo?.otherUserProfile.displayPhoto,
                                animationIndex: msgIndex,
                                onReply: () => notifier.setReplyingTo(msg),
                                onReact: (emoji) => notifier.react(msg, emoji),
                                onDeleteForMe: () =>
                                    notifier.deleteMessage(msg, 'for_me'),
                                onDeleteForEveryone: () =>
                                    notifier.deleteMessage(msg, 'for_everyone'),
                                onRetry: msg.sendStatus == MessageSendStatus.failed
                                    ? () => notifier.retryFailed(msg, (t) {
                                          _controller.text = t;
                                        })
                                    : null,
                                onImageTap: msg.imageUrl?.isNotEmpty ?? false
                                    ? () => _openImage(context, msg.imageUrl!)
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          ChatComposer(
            controller: _controller,
            onSend: () {
              notifier.send(_controller.text);
              _controller.clear();
            },
            onTyping: notifier.onTyping,
            replyingTo: thread.replyingTo,
            onCancelReply: () => notifier.setReplyingTo(null),
            onPickImage: () => notifier.pickImage(),
            onPickCamera: () => notifier.pickImage(source: ImageSource.camera),
            showEmojiPicker: thread.showEmojiPicker,
            onToggleEmojiPicker: notifier.toggleEmojiPicker,
            onEmojiSelected: (emoji) => _controller.text += emoji,
            sending: thread.sending,
            uploading: thread.uploading,
          ),
        ],
      ),
    );
  }

  void _showCallSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not available yet.')),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'chat-image-$url',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }
}
