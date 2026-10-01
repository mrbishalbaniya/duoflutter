import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/chat_emoji_utils.dart';
import '../domain/chat_location.dart';
import '../providers/chat_thread_controller.dart';
import '../services/chat_debug_log.dart';
import 'chat_composer.dart';
import 'location_message_card.dart';

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

class _ChatThreadComposerPaneState
    extends ConsumerState<ChatThreadComposerPane> {
  late final ChatEmojiRecentStore _recentStore;
  List<String> _recentEmojis = const [];
  bool _sharingLocation = false;

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Web `handleShareLocation` + `confirmShareLocation`: get a GPS fix, preview it
  /// with the address, then send `buildLocationMessage(...)` as a normal message.
  Future<void> _shareLocation() async {
    if (_sharingLocation) return;
    setState(() => _sharingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Turn on location services to share your location.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _toast('Location access is blocked. Allow it in app settings.');
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        _toast('Location permission is needed to share your location.');
        return;
      }
      final Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        _toast('Finding your location took too long. Try again.');
        return;
      }
      if (!mounted) return;
      final convo = ref
          .read(chatThreadControllerProvider(widget.conversationId))
          .conversation;
      final choice = await showShareLocationSheet(
        context,
        lat: position.latitude,
        lng: position.longitude,
        recipientName: convo?.displayName,
      );
      if (!choice.send || !mounted) return;
      await ref
          .read(chatThreadControllerProvider(widget.conversationId).notifier)
          .send(
            buildLocationMessage(
              position.latitude,
              position.longitude,
              choice.address,
            ),
          );
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }

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
    final notifier = ref.read(
      chatThreadControllerProvider(widget.conversationId).notifier,
    );

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
      onShareLocation: _shareLocation,
      sharingLocation: _sharingLocation,
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
