import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/chat_emoji_utils.dart';
import '../providers/chat_thread_controller.dart';
import '../services/chat_debug_log.dart';
import 'chat_composer.dart';

/// Composer pane — rebuilds only on composer/voice state, not on every message.
class ChatThreadComposerPane extends ConsumerStatefulWidget {
  const ChatThreadComposerPane({
    super.key,
    required this.conversationId,
    required this.controller,
  });

  final String conversationId;
  final TextEditingController controller;

  @override
  ConsumerState<ChatThreadComposerPane> createState() =>
      _ChatThreadComposerPaneState();
}

class _ChatThreadComposerPaneState extends ConsumerState<ChatThreadComposerPane> {
  late final ChatEmojiRecentStore _recentStore;
  List<String> _recentEmojis = const [];

  @override
  void initState() {
    super.initState();
    _recentStore = ChatEmojiRecentStore.fromRef(ref);
    _recentEmojis = _recentStore.load();
  }

  void _insertEmoji(String emoji) {
    insertEmojiAtCursor(widget.controller, emoji);
    ChatDebugLog.emojiInserted(
      emoji: emoji,
      cursor: widget.controller.selection.baseOffset,
      length: widget.controller.text.length,
    );
    unawaited(_persistRecent(emoji));
  }

  Future<void> _persistRecent(String emoji) async {
    final updated = await _recentStore.record(emoji);
    if (!mounted) return;
    setState(() => _recentEmojis = updated);
  }

  @override
  Widget build(BuildContext context) {
    final slice = ref.watch(
      chatThreadControllerProvider(widget.conversationId).select(
        (s) => (
          s.replyingTo,
          s.showEmojiPicker,
          s.sending,
          s.uploading,
          s.isVoiceComposeActive,
          s.isRecording,
          s.voiceDraftReady,
          s.voiceRecordingSeconds,
        ),
      ),
    );
    final notifier =
        ref.read(chatThreadControllerProvider(widget.conversationId).notifier);

    return ChatComposer(
      controller: widget.controller,
      onSend: () {
        notifier.closeEmojiPicker();
        notifier.send(widget.controller.text);
        widget.controller.clear();
        notifier.stopTyping();
      },
      onTyping: notifier.onTyping,
      onTypingStop: notifier.stopTyping,
      replyingTo: slice.$1,
      onCancelReply: () => notifier.setReplyingTo(null),
      onPickImage: notifier.pickImage,
      onPickCamera: () => notifier.pickImage(source: ImageSource.camera),
      showEmojiPicker: slice.$2,
      onOpenEmojiPicker: notifier.openEmojiPicker,
      onCloseEmojiPicker: notifier.closeEmojiPicker,
      onEmojiSelected: _insertEmoji,
      recentEmojis: _recentEmojis,
      sending: slice.$3,
      uploading: slice.$4,
      isVoiceComposeActive: slice.$5,
      isRecording: slice.$6,
      voiceDraftReady: slice.$7,
      voiceRecordingSeconds: slice.$8,
      onVoiceListeningChange: notifier.onVoiceListeningChange,
      onCancelVoiceRecording: notifier.cancelVoiceRecording,
      onSendVoiceMessage: notifier.sendVoiceMessage,
    );
  }
}
