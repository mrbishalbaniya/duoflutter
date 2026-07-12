import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/chat_repository.dart';
import '../chat_utils.dart';
import '../domain/chat_message_cache.dart';
import '../domain/chat_message_selectors.dart';
import '../domain/chat_thread_state.dart';
import '../services/chat_websocket_service.dart';
import '../services/voice_recording_service.dart';
import 'chat_providers.dart';

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, ChatThreadState, String>((ref, conversationId) {
  final controller = ChatThreadController(
    conversationId: conversationId,
    repository: ref.read(chatRepositoryProvider),
    messageCache: ref.read(chatMessageCacheProvider),
    onConversationsChanged: () => ref.invalidate(conversationsProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

class _PendingSend {
  const _PendingSend({
    required this.content,
    this.imageUrl = '',
    this.replyToId,
  });

  final String content;
  final String imageUrl;
  final int? replyToId;
}

class ChatThreadController extends StateNotifier<ChatThreadState> {
  ChatThreadController({
    required this.conversationId,
    required this.repository,
    required this.messageCache,
    required this.onConversationsChanged,
  }) : super(const ChatThreadState()) {
    _ws = ChatWebSocketService(repository);
    _connSub = _ws.connectionStream.listen(_onConnectionState);
    _wsSub = _ws.events.listen(_handleWsEvent);
    unawaited(_init());
  }

  final String conversationId;
  final ChatRepository repository;
  final ChatMessageCache messageCache;
  final VoidCallback onConversationsChanged;

  late final ChatWebSocketService _ws;
  final _picker = ImagePicker();
  final _failedSends = <String, _PendingSend>{};
  final _pendingAckTimers = <String, Timer>{};

  Timer? _typingTimer;
  Timer? _typingClearTimer;
  Timer? _voiceRecordingTimer;
  VoiceRecordingService? _voiceRecorder;
  StreamSubscription<ChatWsEvent>? _wsSub;
  StreamSubscription<WsConnectionState>? _connSub;
  bool _disposed = false;
  int _pollCycle = 0;

  Future<void> _init() async {
    unawaited(_connectWs());
    await load();
    if (!_ws.isConnected) {
      await _connectWs();
    }
  }

  String get _activeConversationId => state.conversation?.publicId ?? conversationId;

  String? get _wsPublicId {
    final id = state.conversation?.publicId.trim();
    if (id != null && id.isNotEmpty) return id;
    final route = conversationId.trim();
    if (route.length >= 10) return route;
    return null;
  }

  void _onConnectionState(WsConnectionState connection) {
    if (_disposed) return;
    state = state.copyWith(
      wsConnected: connection.connected,
      wsReconnecting: connection.reconnecting,
    );
    if (connection.connected) {
      _markRead();
    }
    if (kDebugMode) {
      debugPrint(
        '[ChatThread] connection connected=${connection.connected} '
        'reconnecting=${connection.reconnecting}',
      );
    }
  }

  void _syncWsState() {
    if (_disposed) return;
    state = state.copyWith(
      wsConnected: _ws.isConnected,
      wsReconnecting: _ws.isReconnecting && !_ws.isConnected,
    );
  }

  void _markRead() {
    if (state.messages.isEmpty) return;
    _ws.send({'type': 'mark_read'});
  }

  void _touchCache(List<ChatMessage> messages) {
    final key = _activeConversationId;
    if (key.isEmpty) return;
    messageCache.put(key, messages);
  }

  List<ChatMessage> _sortedVisible(List<ChatMessage> messages) {
    final sorted = sortMessages(messages);
    return sorted.where((m) => m.isVisible).toList(growable: false);
  }

  ChatThreadState _withMessages(ChatThreadState base, List<ChatMessage> messages) {
    final visible = _sortedVisible(messages);
    return base.copyWith(
      messages: messages,
      visibleMessages: visible,
      listEntries: buildMessageListEntries(visible),
    );
  }

  void _commitMessages(List<ChatMessage> messages, {bool cache = true}) {
    state = _withMessages(state, messages);
    if (cache) _touchCache(state.messages);
  }

  /// Applies merged messages using a structural patch when list layout is unchanged.
  void _applyMergedMessages(List<ChatMessage> merged, {bool cache = true}) {
    final newVisible = _sortedVisible(merged);
    final newEntries = buildMessageListEntries(newVisible);
    if (chatListStructureRevision(state.listEntries) ==
        chatListStructureRevision(newEntries)) {
      _patchMessages(merged, cache: cache);
      return;
    }
    _commitMessages(merged, cache: cache);
  }

  /// Updates message payloads without rebuilding list layout (read receipts, reactions).
  void _patchMessages(List<ChatMessage> messages, {bool cache = true}) {
    final visible = _sortedVisible(messages);
    state = state.copyWith(messages: messages, visibleMessages: visible);
    if (cache) _touchCache(messages);
  }

  void _noteHttpSuccess() {
    if (_disposed) return;
    if (!state.httpDeliveryOk) {
      state = state.copyWith(httpDeliveryOk: true);
    }
  }

  void _noteHttpFailure() {
    if (_disposed) return;
    state = state.copyWith(httpDeliveryOk: false);
  }

  Future<void> load() async {
    final cacheKey = conversationId.trim();
    final cached = messageCache.peek(cacheKey) ??
        messageCache.peek(_activeConversationId);
    if (cached != null) {
      final visible = cached.where((m) => m.isVisible).toList(growable: false);
      state = state.copyWith(
        messages: cached,
        visibleMessages: visible,
        listEntries: buildMessageListEntries(visible),
        loading: false,
        initialScrollPending: true,
        httpDeliveryOk: true,
      );
    } else {
      state = state.copyWith(loading: true, clearError: true);
    }

    final errors = <String>[];

    ChatMessagesPage? page;
    Conversation? convo;

    final candidates = _conversationIdCandidates();
    if (candidates.isNotEmpty) {
      final primary = candidates.first;
      Future<ChatMessagesPage?> fetchMessages() async {
        try {
          return await repository.getMessages(primary, limit: 50);
        } on ApiException catch (e) {
          errors.add(e.message);
          _noteHttpFailure();
          return null;
        }
      }

      Future<Conversation?> fetchConversation() async {
        try {
          return await repository.getConversation(primary);
        } on ApiException catch (e) {
          if (!errors.contains(e.message)) errors.add(e.message);
          _noteHttpFailure();
          return null;
        }
      }

      final results = await Future.wait<Object?>([
        fetchMessages(),
        fetchConversation(),
      ]);
      page = results[0] as ChatMessagesPage?;
      convo = results[1] as Conversation?;
    }

    if (page == null) {
      for (final id in candidates.skip(1)) {
        try {
          page = await repository.getMessages(id, limit: 50);
          errors.clear();
          break;
        } on ApiException catch (e) {
          if (!errors.contains(e.message)) errors.add(e.message);
          _noteHttpFailure();
        }
      }
    }

    if (convo == null) {
      for (final id in candidates.skip(1)) {
        try {
          convo = await repository.getConversation(id);
          break;
        } on ApiException catch (e) {
          if (!errors.contains(e.message)) errors.add(e.message);
          _noteHttpFailure();
        }
      }
    }

    convo ??= await _findConversationInList();

    if (page == null && convo != null) {
      try {
        page = await repository.getMessages(convo.publicId, limit: 50);
        errors.clear();
      } on ApiException catch (e) {
        errors.add(e.message);
        _noteHttpFailure();
      }
    }

    if (_disposed) return;
    final sorted = page != null ? sortMessages(page.results) : state.messages;
    final visible = sorted.where((m) => m.isVisible).toList(growable: false);
    state = state.copyWith(
      conversation: convo,
      messages: sorted,
      visibleMessages: visible,
      listEntries: buildMessageListEntries(visible),
      isOtherUserTyping: convo?.isOtherUserTyping ?? false,
      hasMore: page?.hasMore ?? false,
      loading: false,
      initialScrollPending: sorted.isNotEmpty,
      httpDeliveryOk: true,
      error: errors.isEmpty ? null : errors.first,
    );
    if (sorted.isNotEmpty) {
      _touchCache(sorted);
    }
    _noteHttpSuccess();
    if (_ws.isConnected) _markRead();
  }

  List<String> _conversationIdCandidates() {
    final id = conversationId.trim();
    if (id.isEmpty) return const [];
    final seen = <String>{};
    final candidates = <String>[];
    void add(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) return;
      candidates.add(normalized);
    }

    add(id);
    final convo = state.conversation;
    if (convo != null) {
      add(convo.publicId);
      add(convo.id.toString());
    }
    return candidates;
  }

  Future<Conversation?> _findConversationInList() async {
    try {
      final conversations = await repository.getConversations();
      for (final convo in conversations) {
        if (convo.publicId == conversationId ||
            convo.id.toString() == conversationId) {
          return convo;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> reconnect() async {
    await _ws.reconnect();
    _syncWsState();
  }

  Future<void> _connectWs() async {
    final publicId = _wsPublicId;
    if (publicId == null) {
      if (kDebugMode) {
        debugPrint('[ChatThread] ws deferred — waiting for public_id');
      }
      return;
    }
    await _ws.connect(publicId);
    _syncWsState();
  }

  void _handleWsEvent(ChatWsEvent event) {
    if (_disposed) return;

    switch (event.type) {
      case 'chat_message':
        _onIncomingMessage(ChatMessage.fromJson(event.data));
      case 'typing_status':
        final typing = event.data['is_typing'] as bool? ?? false;
        state = state.copyWith(isOtherUserTyping: typing);
        _typingClearTimer?.cancel();
        if (typing) {
          _typingClearTimer = Timer(const Duration(seconds: 3), () {
            if (!_disposed) state = state.copyWith(isOtherUserTyping: false);
          });
        }
      case 'message_reacted':
        _onMessageReacted(event.data);
      case 'message_deleted':
        _onMessageDeleted(event.data);
      case 'messages_read':
        _onMessagesRead(event.data);
      case 'poll_messages':
        _pollLatestMessages();
    }
  }

  void _onIncomingMessage(ChatMessage msg) {
    final messages = List<ChatMessage>.from(state.messages);
    if (msg.clientTempId != null) {
      _clearPendingAck(msg.clientTempId!);
      final idx = messages.indexWhere((m) => m.clientTempId == msg.clientTempId);
      if (idx >= 0) {
        messages[idx] = msg.copyWith(sendStatus: MessageSendStatus.sent);
        _commitMessages(messages);
        onConversationsChanged();
        _markRead();
        return;
      }
    }
    if (messages.any((m) => m.id == msg.id && m.id > 0)) return;
    messages.add(msg);
    _commitMessages(messages);
    onConversationsChanged();
    _markRead();
  }

  void _onMessageReacted(Map<String, dynamic> data) {
    final messageId = data['id'] as int?;
    if (messageId == null) return;
    final reactions = _parseReactionsMap(data['reactions']);
    _patchMessages(
      state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(reactions: reactions);
      }).toList(),
      cache: false,
    );
  }

  void _onMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['id'] as int?;
    final deleteType = data['delete_type'] as String? ?? 'for_me';
    if (messageId == null) return;
    _commitMessages(
      state.messages
          .map((m) {
            if (m.id != messageId) return m;
            if (deleteType == 'for_everyone') {
              return m.copyWith(
                isDeletedForEveryone: true,
                content: 'This message was deleted',
              );
            }
            return m.copyWith(isDeletedForMe: true);
          })
          .where((m) => m.isVisible)
          .toList(),
      cache: false,
    );
  }

  void _onMessagesRead(Map<String, dynamic> data) {
    final ids = (data['message_ids'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final now = DateTime.now().toUtc().toIso8601String();
    _patchMessages(
      state.messages.map((m) {
        if (!m.isMine) return m;
        if (ids.isNotEmpty && !ids.contains(m.id)) return m;
        return m.copyWith(
          isRead: true,
          readAt: m.readAt ?? now,
          deliveredAt: m.deliveredAt ?? now,
        );
      }).toList(),
      cache: false,
    );
  }

  Future<void> _pollLatestMessages() async {
    try {
      _pollCycle++;
      final sw = Stopwatch()..start();
      final page = await repository.getMessages(_activeConversationId, limit: 50);
      if (_disposed) return;
      _noteHttpSuccess();
      if (kDebugMode) {
        debugPrint('[ChatThread] poll ok ${sw.elapsedMilliseconds}ms '
            'count=${page.results.length}');
      }
      final merged = _mergeMessages(state.messages, page.results);
      if (merged.length != state.messages.length ||
          (merged.isNotEmpty &&
              state.messages.isNotEmpty &&
              merged.last.id != state.messages.last.id)) {
        _applyMergedMessages(merged);
      } else if (!_messagesEqual(merged, state.messages)) {
        _patchMessages(merged);
      }
      if (_pollCycle % 3 == 0) {
        onConversationsChanged();
      }
    } catch (e) {
      _noteHttpFailure();
      if (kDebugMode) debugPrint('[ChatThread] poll failed: $e');
    }
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> existing,
    List<ChatMessage> incoming,
  ) {
    final merged = List<ChatMessage>.from(existing);
    for (final msg in incoming) {
      if (msg.clientTempId != null) {
        final idx = merged.indexWhere((m) => m.clientTempId == msg.clientTempId);
        if (idx >= 0) {
          merged[idx] = msg.copyWith(sendStatus: MessageSendStatus.sent);
          continue;
        }
      }
      if (!merged.any((m) => m.id == msg.id && m.id > 0)) {
        merged.add(msg);
      }
    }
    return sortMessages(merged);
  }

  bool _messagesEqual(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].isRead != b[i].isRead) return false;
      if (a[i].readAt != b[i].readAt) return false;
      if (a[i].deliveredAt != b[i].deliveredAt) return false;
      if (a[i].sendStatus != b[i].sendStatus) return false;
      if (a[i].reactions != b[i].reactions) return false;
      if (a[i].content != b[i].content) return false;
      if (a[i].isDeletedForMe != b[i].isDeletedForMe) return false;
      if (a[i].isDeletedForEveryone != b[i].isDeletedForEveryone) return false;
    }
    return true;
  }

  Future<void> loadEarlier() async {
    if (state.loadingEarlier || !state.hasMore || state.messages.isEmpty) return;
    state = state.copyWith(loadingEarlier: true);
    try {
      final oldest = state.messages.firstWhere((m) => m.id > 0, orElse: () => state.messages.first);
      final page = await repository.getMessages(
        _activeConversationId,
        before: oldest.id.toString(),
        limit: 50,
      );
      if (_disposed) return;
      final merged = sortMessages([...page.results, ...state.messages]);
      _commitMessages(merged);
      state = state.copyWith(
        hasMore: page.hasMore,
        loadingEarlier: false,
      );
      _noteHttpSuccess();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(loadingEarlier: false);
        _noteHttpFailure();
      }
    }
  }

  DateTime? _lastPaginationAt;

  void onScrollNearTop() {
    if (state.loadingEarlier || !state.hasMore) return;
    final now = DateTime.now();
    if (_lastPaginationAt != null &&
        now.difference(_lastPaginationAt!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastPaginationAt = now;
    loadEarlier();
  }

  void markInitialScrollDone() {
    if (state.initialScrollPending) {
      state = state.copyWith(initialScrollPending: false);
    }
  }

  void onTyping() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 2000), () {
      if (_ws.send({'type': 'typing', 'is_typing': true})) return;
      repository.sendTyping(_activeConversationId);
    });
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    await _sendPayload(content: trimmed, replyToId: state.replyingTo?.id);
  }

  Future<void> _sendPayload({
    required String content,
    String imageUrl = '',
    int? replyToId,
  }) async {
    final replyTarget = replyToId != null
        ? state.messages.cast<ChatMessage?>().firstWhere(
              (m) => m?.id == replyToId,
              orElse: () => state.replyingTo,
            )
        : state.replyingTo;

    final tempId = 'tmp-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final optimistic = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      content: content,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      messageType: imageUrl.isNotEmpty
          ? (content == voiceMessageLabel ? 'voice' : 'image')
          : 'text',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      isMine: true,
      clientTempId: tempId,
      sendStatus: MessageSendStatus.pending,
      replyTo: replyTarget == null
          ? null
          : {
              'id': replyTarget.id,
              'content': replyTarget.content,
              'sender_name': replyTarget.senderName ?? '',
            },
    );

    _failedSends[tempId] = _PendingSend(
      content: content,
      imageUrl: imageUrl,
      replyToId: replyToId ?? replyTarget?.id,
    );

    state = _withMessages(
      state.copyWith(
        sending: true,
        clearReplyingTo: true,
        showEmojiPicker: false,
      ),
      sortMessages([...state.messages, optimistic]),
    );
    _touchCache(state.messages);

    try {
      final sentViaWs = _ws.send({
        'type': 'chat_message',
        'content': content,
        'image_url': imageUrl,
        if ((replyToId ?? replyTarget?.id) != null)
          'reply_to_id': replyToId ?? replyTarget?.id,
        'client_temp_id': tempId,
      });

      if (sentViaWs) {
        _schedulePendingAck(tempId);
      } else {
        await _commitViaHttp(tempId);
      }
      _noteHttpSuccess();
      onConversationsChanged();
    } on ApiException catch (e) {
      _markFailed(tempId, e.message);
      _noteHttpFailure();
    } catch (e) {
      _markFailed(tempId, e.toString());
    } finally {
      if (!_disposed) state = state.copyWith(sending: false);
    }
  }

  void _schedulePendingAck(String tempId) {
    _pendingAckTimers[tempId]?.cancel();
    _pendingAckTimers[tempId] = Timer(const Duration(seconds: 8), () async {
      if (_disposed) return;
      final stillPending = state.messages.any(
        (m) => m.clientTempId == tempId && m.sendStatus == MessageSendStatus.pending,
      );
      if (stillPending) {
        try {
          await _commitViaHttp(tempId);
        } catch (e) {
          _markFailed(tempId, e.toString());
        }
      }
    });
  }

  Future<void> _commitViaHttp(String tempId) async {
    final payload = _failedSends[tempId];
    if (payload == null) return;
    final msg = await repository.sendMessage(
      _activeConversationId,
      content: payload.content,
      imageUrl: payload.imageUrl.isEmpty ? null : payload.imageUrl,
      replyToId: payload.replyToId,
    );
    _clearPendingAck(tempId);
    _failedSends.remove(tempId);
    final messages = List<ChatMessage>.from(state.messages);
    final idx = messages.indexWhere((m) => m.clientTempId == tempId);
    if (idx >= 0) {
      messages[idx] = msg.copyWith(sendStatus: MessageSendStatus.sent);
      _commitMessages(messages);
    }
    _noteHttpSuccess();
  }

  void _markFailed(String tempId, String error) {
    _clearPendingAck(tempId);
    _patchMessages(
      state.messages.map((m) {
        if (m.clientTempId == tempId) {
          return m.copyWith(sendStatus: MessageSendStatus.failed);
        }
        return m;
      }).toList(),
      cache: false,
    );
    state = state.copyWith(error: error);
  }

  void _clearPendingAck(String tempId) {
    _pendingAckTimers.remove(tempId)?.cancel();
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    state = state.copyWith(uploading: true);
    try {
      final imageUrl = await repository.uploadChatImage(file.path);
      await _sendPayload(content: '', imageUrl: imageUrl);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    } finally {
      if (!_disposed) state = state.copyWith(uploading: false);
    }
  }

  Future<void> onVoiceListeningChange(bool next) async {
    if (next) {
      if (state.voiceDraftReady && (_voiceRecorder?.isPaused ?? false)) {
        await _resumeVoiceRecording();
      } else {
        await _startVoiceRecording();
      }
    } else if (state.isRecording) {
      await _pauseVoiceRecording();
    }
  }

  Future<bool> _startVoiceRecording() async {
    if (state.isRecording || state.uploading || state.sending) return false;

    if (_voiceRecorder?.isPaused ?? false) {
      return _resumeVoiceRecording();
    }

    final permission = await VoiceRecordingService.ensureMicrophonePermission();
    if (permission == MicrophonePermissionResult.permanentlyDenied) {
      state = state.copyWith(
        micPermissionDenied: true,
        error: 'Microphone permission is required to send voice messages.',
      );
      return false;
    }
    if (permission != MicrophonePermissionResult.granted) {
      state = state.copyWith(
        error: 'Microphone permission is required to send voice messages.',
      );
      return false;
    }

    _voiceRecorder ??= VoiceRecordingService();
    try {
      final path = await _voiceRecorder!.start();
      if (path == null) return false;
      state = state.copyWith(
        isRecording: true,
        voiceDraftReady: true,
        micPermissionDenied: false,
        clearError: true,
      );
      _startVoiceTimer();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Unable to start voice recording.');
      return false;
    }
  }

  Future<bool> _resumeVoiceRecording() async {
    final recorder = _voiceRecorder;
    if (recorder == null || !recorder.isPaused) return false;
    try {
      await recorder.resume();
      state = state.copyWith(isRecording: true, voiceDraftReady: true);
      _startVoiceTimer();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pauseVoiceRecording() async {
    final recorder = _voiceRecorder;
    if (recorder == null) {
      state = state.copyWith(isRecording: false);
      return;
    }

    try {
      if (await recorder.isRecording) {
        await recorder.pause();
      }
    } catch (_) {}

    _stopVoiceTimer();
    state = state.copyWith(isRecording: false, voiceDraftReady: true);
  }

  Future<void> cancelVoiceRecording() async {
    await _voiceRecorder?.cancel();
    _stopVoiceTimer();
    state = state.copyWith(
      isRecording: false,
      voiceDraftReady: false,
      voiceRecordingSeconds: 0,
    );
  }

  Future<void> sendVoiceMessage() async {
    final recorder = _voiceRecorder;
    if (recorder != null && (state.isRecording || recorder.isPaused)) {
      final path = await recorder.stop();
      _stopVoiceTimer();
      state = state.copyWith(isRecording: false);
      if (path == null || !File(path).existsSync()) {
        await cancelVoiceRecording();
        return;
      }
    }

    final path = recorder?.recordingPath;
    if (path == null || !File(path).existsSync()) {
      await cancelVoiceRecording();
      return;
    }

    final file = File(path);
    if (await file.length() == 0) {
      await cancelVoiceRecording();
      return;
    }

    state = state.copyWith(uploading: true);
    try {
      final audioUrl = await repository.uploadChatImage(path);
      await _sendPayload(content: voiceMessageLabel, imageUrl: audioUrl);
      await recorder?.cancel();
      state = state.copyWith(
        voiceDraftReady: false,
        voiceRecordingSeconds: 0,
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, voiceDraftReady: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), voiceDraftReady: true);
    } finally {
      if (!_disposed) state = state.copyWith(uploading: false);
    }
  }

  Future<void> openMicrophoneSettings() {
    return VoiceRecordingService.openSettings();
  }

  void _startVoiceTimer() {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed || !state.isRecording) return;
      state = state.copyWith(voiceRecordingSeconds: state.voiceRecordingSeconds + 1);
    });
  }

  void _stopVoiceTimer() {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
  }

  Future<void> react(ChatMessage msg, String emoji) async {
    try {
      final updated = await repository.reactToMessage(msg.id, emoji);
      _ws.send({'type': 'message_reaction', 'id': msg.id, 'emoji': emoji});
      _patchMessages(
        state.messages
            .map((m) => m.id == msg.id ? updated : m)
            .toList(),
        cache: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> deleteMessage(ChatMessage msg, String deleteType) async {
    try {
      final sentViaWs = _ws.send({
        'type': 'delete_message',
        'id': msg.id,
        'delete_type': deleteType,
      });
      if (!sentViaWs) {
        await repository.deleteMessage(msg.id, deleteType: deleteType);
      }
      if (deleteType == 'for_everyone') {
        _commitMessages(
          state.messages
              .map(
                (m) => m.id == msg.id
                    ? m.copyWith(
                        isDeletedForEveryone: true,
                        content: 'This message was deleted',
                      )
                    : m,
              )
              .toList(),
          cache: false,
        );
      } else {
        _commitMessages(
          state.messages.where((m) => m.id != msg.id).toList(),
          cache: false,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void retryFailed(ChatMessage msg, void Function(String) setText) {
    final payload = msg.clientTempId != null ? _failedSends[msg.clientTempId!] : null;
    _commitMessages(
      state.messages
          .where((m) => m.clientTempId != msg.clientTempId)
          .toList(),
      cache: false,
    );
    if (payload != null) {
      if (payload.imageUrl.isNotEmpty) {
        unawaited(_sendPayload(
          content: payload.content,
          imageUrl: payload.imageUrl,
          replyToId: payload.replyToId,
        ));
      } else {
        setText(payload.content);
        send(payload.content);
      }
    } else {
      setText(msg.content);
      send(msg.content);
    }
  }

  void setReplyingTo(ChatMessage? msg) {
    state = msg == null
        ? state.copyWith(clearReplyingTo: true)
        : state.copyWith(replyingTo: msg);
  }

  void toggleEmojiPicker() {
    state = state.copyWith(showEmojiPicker: !state.showEmojiPicker);
  }

  Future<void> updateSettings({bool? muted, bool? pinned}) async {
    final convo = state.conversation;
    if (convo == null) return;
    try {
      await repository.updateConversationSettings(
        convo.publicId,
        muted: muted,
        pinned: pinned,
      );
      state = state.copyWith(
        conversation: convo.copyWith(
          isMuted: muted ?? convo.isMuted,
          isPinned: pinned ?? convo.isPinned,
        ),
      );
      onConversationsChanged();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> setNickname(String nickname) async {
    final convo = state.conversation;
    if (convo == null) return;
    try {
      await repository.updateConversationSettings(
        convo.publicId,
        nickname: nickname.trim().isEmpty ? '' : nickname.trim(),
      );
      state = state.copyWith(
        conversation: convo.copyWith(
          otherUserNickname: nickname.trim().isEmpty ? null : nickname.trim(),
          clearNickname: nickname.trim().isEmpty,
        ),
      );
      onConversationsChanged();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<bool> unmatch() async {
    try {
      await repository.unmatch(_activeConversationId);
      onConversationsChanged();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> report(String reason) async {
    try {
      await repository.report(_activeConversationId, reason: reason);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      await repository.clearConversationHistory(_activeConversationId);
      state = state.copyWith(
        messages: const [],
        visibleMessages: const [],
        listEntries: const [],
      );
      messageCache.clear(_activeConversationId);
      onConversationsChanged();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  Map<String, int> _parseReactionsMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) {
        if (value is List) return MapEntry('$key', value.length);
        if (value is num) return MapEntry('$key', value.toInt());
        return MapEntry('$key', 0);
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    _typingClearTimer?.cancel();
    _stopVoiceTimer();
    unawaited(_voiceRecorder?.dispose());
    for (final timer in _pendingAckTimers.values) {
      timer.cancel();
    }
    _pendingAckTimers.clear();
    _wsSub?.cancel();
    _connSub?.cancel();
    _ws.dispose();
    super.dispose();
  }
}
