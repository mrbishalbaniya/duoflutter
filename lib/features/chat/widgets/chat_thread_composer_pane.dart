import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/chat_thread_controller.dart';
import 'chat_composer.dart';

/// Composer pane — rebuilds only on composer/voice state, not on every message.
class ChatThreadComposerPane extends ConsumerWidget {
  const ChatThreadComposerPane({
    super.key,
    required this.conversationId,
    required this.controller,
  });

  final String conversationId;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slice = ref.watch(
      chatThreadControllerProvider(conversationId).select(
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
    final notifier = ref.read(chatThreadControllerProvider(conversationId).notifier);

    return ChatComposer(
      controller: controller,
      onSend: () {
        notifier.send(controller.text);
        controller.clear();
      },
      onTyping: notifier.onTyping,
      replyingTo: slice.$1,
      onCancelReply: () => notifier.setReplyingTo(null),
      onPickImage: notifier.pickImage,
      onPickCamera: () => notifier.pickImage(source: ImageSource.camera),
      showEmojiPicker: slice.$2,
      onToggleEmojiPicker: notifier.toggleEmojiPicker,
      onEmojiSelected: (emoji) {
        controller.text += emoji;
        notifier.toggleEmojiPicker();
      },
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
