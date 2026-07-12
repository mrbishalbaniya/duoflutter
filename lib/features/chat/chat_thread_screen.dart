import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/chat_thread_controller.dart';
import 'widgets/chat_dialogs.dart';
import 'widgets/chat_thread_composer_pane.dart';
import 'widgets/chat_thread_header.dart';
import 'widgets/chat_thread_message_pane.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Reverse list: maxScrollExtent is the top (older messages).
    if (pos.pixels >= pos.maxScrollExtent - 48) {
      ref
          .read(chatThreadControllerProvider(widget.conversationId).notifier)
          .onScrollNearTop();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels <= 120;
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (jump) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      ref
          .read(chatThreadControllerProvider(widget.conversationId).notifier)
          .markInitialScrollDone();
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
    final notifier =
        ref.read(chatThreadControllerProvider(widget.conversationId).notifier);

    ref.listen(
      chatThreadControllerProvider(widget.conversationId).select(
        (s) => (
          s.loading,
          s.initialScrollPending,
          s.messages.length,
          s.messages.isEmpty
              ? ''
              : '${s.messages.last.id}:${s.messages.last.clientTempId}',
          s.error,
          s.micPermissionDenied,
        ),
      ),
      (prev, next) {
      if (prev?.$1 == true && next.$1 == false) {
        _scrollToBottom(jump: true);
      }
      if (next.$2 && next.$3 > 0) {
        _scrollToBottom(jump: true);
      }

      final prevCount = prev?.$3 ?? _lastMessageCount;
      final nextCount = next.$3;
      if (nextCount != prevCount && nextCount > prevCount) {
        final grewAtEnd = nextCount > 0 &&
            (prev == null || prev.$4.isEmpty || next.$4 != prev.$4);
        if (grewAtEnd) {
          final last = ref
              .read(chatThreadControllerProvider(widget.conversationId))
              .messages
              .lastOrNull;
          if (_isNearBottom() || (last?.isMine ?? false)) {
            _scrollToBottom();
          }
        }
        _lastMessageCount = nextCount;
      }

      if (next.$5 != null && next.$5 != prev?.$5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.$5!),
            action: next.$6
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: notifier.openMicrophoneSettings,
                  )
                : null,
          ),
        );
        notifier.clearError();
      }
    });

    final headerSlice = ref.watch(
      chatThreadControllerProvider(widget.conversationId).select(
        (s) => (
          s.conversation,
          s.loading,
          s.isOtherUserTyping,
          s.wsConnected,
        ),
      ),
    );
    final showBanner = ref.watch(
      chatThreadControllerProvider(widget.conversationId)
          .select((s) => s.showReconnectBanner),
    );

    final convo = headerSlice.$1;
    final loading = headerSlice.$2;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: convo == null
          ? AppBar(
              title: const Text('Chat'),
              bottom: loading
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  : null,
            )
          : ChatThreadHeader(
              conversation: convo,
              isOtherUserTyping: headerSlice.$3,
              wsConnected: headerSlice.$4,
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
          if (showBanner)
            MaterialBanner(
              content: const Text('Reconnecting… messages may be delayed'),
              leading: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              actions: [
                TextButton(
                  onPressed: notifier.reconnect,
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: ChatThreadMessagePane(
              conversationId: widget.conversationId,
              scrollController: _scrollController,
              onSetRetryText: (text) => _controller.text = text,
            ),
          ),
          ChatThreadComposerPane(
            conversationId: widget.conversationId,
            controller: _controller,
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
}
