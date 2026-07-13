import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/lifecycle/app_lifecycle_service.dart';
import '../../../core/models/chat_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/chat_repository.dart';
import '../../auth/auth_controller.dart';
import '../chat_utils.dart';
import '../data/chat_cache_service.dart';
import '../domain/chat_cache_serialization.dart';
import '../domain/chat_message_selectors.dart';
import '../domain/chat_thread_state.dart';
import '../services/chat_debug_log.dart';
import '../services/chat_screen_capture_service.dart';
import '../services/chat_websocket_service.dart';
import '../services/voice_recording_service.dart';
import 'chat_providers.dart';

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, ChatThreadState, String>((ref, conversationId) {
  final currentUserId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  final controller = ChatThreadController(
    conversationId: conversationId,
    currentUserId: currentUserId,
    repository: ref.read(chatRepositoryProvider),
    chatCache: ref.read(chatCacheServiceProvider),
    onConversationsChanged: () => ref
        .read(conversationsListProvider(const ConversationListFilter()).notifier)
        .scheduleRefresh(),
  );
  ref.onDispose(controller.dispose);
  ref.listen(appLifecycleProvider, (_, next) {
    controller.setAppInBackground(next != AppLifecycleState.resumed);
  });
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
    required this.currentUserId,
    required this.repository,
    required this.chatCache,
    required this.onConversationsChanged,
  }) : super(const ChatThreadState()) {
    _ws = ChatWebSocketService(repository);
    _connSub = _ws.connectionStream.listen(_onConnectionState);
    _wsSub = _ws.events.listen(_handleWsEvent);
    unawaited(_init());
  }

  final String conversationId;
  final int? currentUserId;
  final ChatRepository repository;
  final ChatCacheService chatCache;
  final VoidCallback onConversationsChanged;

  late final ChatWebSocketService _ws;
  final _picker = ImagePicker();
  final _failedSends = <String, _PendingSend>{};
  final _pendingAckTimers = <String, Timer>{};

  Timer? _typingTimer;
  Timer? _typingStopTimer;
  Timer? _typingClearTimer;
  Timer? _conversationsInvalidateTimer;
  Timer? _voiceRecordingTimer;
  VoiceRecordingService? _voiceRecorder;
  StreamSubscription<ChatWsEvent>? _wsSub;
  StreamSubscription<WsConnectionState>? _connSub;
  ChatScreenCaptureService? _screenCapture;
  bool _disposed = false;
  bool _isTypingActive = false;
  DateTime? _lastTypingSignalAt;
  int _pollCycle = 0;
  static const _ackTimeout = Duration(seconds: 3);

  Future<void> _init() async {
    final routeId = conversationId.trim();
    if (routeId.length >= 10) {
      unawaited(_connectWs(routeId));
    }
    await load();
    if (!_ws.isConnected) {
      unawaited(_connectWs());
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

  void _touchCache(List<ChatMessage> messages, {bool? hasMore}) {
    final key = _activeConversationId;
    if (key.isEmpty) return;
    chatCache.writeMessages(
      key,
      messages,
      hasMore: hasMore ?? state.hasMore,
    );
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
      messagesByKey: buildMessagesByKey(visible),
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
    state = state.copyWith(
      messages: messages,
      visibleMessages: visible,
      messagesByKey: buildMessagesByKey(visible),
    );
    if (cache) _touchCache(messages);
  }

  void _scheduleConversationsChanged() {
    _conversationsInvalidateTimer?.cancel();
    _conversationsInvalidateTimer = Timer(const Duration(seconds: 2), () {
      if (!_disposed) onConversationsChanged();
    });
  }

  void _touchConversationPreview(ChatMessage msg, {required bool fromMe}) {
    final convo = state.conversation;
    if (convo == null) return;
    final patched = convo.copyWith(
      lastMessage: msg,
      lastMessageAt: msg.timestamp,
      unreadCount: 0,
      isOtherUserTyping: false,
    );
    state = state.copyWith(conversation: patched);
    chatCache.writeConversation(patched);
    chatCache.patchConversationPreview(
      conversationKey: convo.publicId,
      lastMessage: msg,
      lastMessageAt: msg.timestamp,
    );
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

  void _applyCachedSnapshot({
    required List<ChatMessage> messages,
    Conversation? conversation,
    required bool hasMore,
    bool initialScroll = true,
  }) {
    final visible = messages.where((m) => m.isVisible).toList(growable: false);
    state = state.copyWith(
      conversation: conversation ?? state.conversation,
      messages: messages,
      visibleMessages: visible,
      listEntries: buildMessageListEntries(visible),
      messagesByKey: buildMessagesByKey(visible),
      isOtherUserTyping: conversation?.isOtherUserTyping ?? state.isOtherUserTyping,
      hasMore: hasMore,
      loading: false,
      initialScrollPending: initialScroll && visible.isNotEmpty,
      httpDeliveryOk: true,
      clearError: true,
    );
    _syncScreenCapture();
  }

  void _syncScreenCapture() {
    final convo = state.conversation;
    if (convo == null) return;
    _screenCapture ??= ChatScreenCaptureService(
      onSecurityEvent: _onLocalSecurityEvent,
    );
    _screenCapture!.start(
      notifyEnabled: convo.notifyScreenshots,
      secureEnabled: convo.secureChat,
    );
  }

  void _onLocalSecurityEvent(String eventCode) {
    unawaited(reportSecurityEvent(eventCode));
  }

  Future<void> reportSecurityEvent(String eventCode) async {
    final convo = state.conversation;
    if (convo == null || !convo.notifyScreenshots) return;

    ChatDebugLog.securityEventOut(
      eventCode: eventCode,
      conversationId: _activeConversationId,
      channel: 'websocket',
    );
    ChatDebugLog.messageOut(
      type: 'security_event',
      conversationId: _activeConversationId,
    );

    final sent = _ws.send({
      'type': 'security_event',
      'event_code': eventCode,
    });
    if (sent) return;

    try {
      final msg = await repository.reportSecurityEvent(
        _activeConversationId,
        eventCode: eventCode,
      );
      ChatDebugLog.securityEventAck(
        eventCode: eventCode,
        conversationId: _activeConversationId,
        messageId: msg.id,
        channel: 'http',
      );
      ChatDebugLog.systemMessageCreated(
        messageId: msg.id,
        conversationId: _activeConversationId,
        eventCode: eventCode,
      );
      _onIncomingMessage(msg.copyWith(isMine: true));
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> load() async {
    final candidates = _conversationIdCandidates();
    final cacheKeys = [
      if (conversationId.trim().isNotEmpty) conversationId.trim(),
      if (_activeConversationId.isNotEmpty) _activeConversationId,
      ...candidates,
    ];

    CachedMessagePage? cachedPage;
    Conversation? cachedConvo;
    for (final key in cacheKeys) {
      cachedPage ??= chatCache.readMessages(key);
      cachedConvo ??= chatCache.readConversation(key);
      if (cachedPage != null && cachedConvo != null) break;
    }

    final hadCache = cachedPage != null;
    if (cachedPage != null) {
      _applyCachedSnapshot(
        messages: cachedPage.messages,
        conversation: cachedConvo,
        hasMore: cachedPage.hasMore,
      );
    } else if (cachedConvo != null) {
      state = state.copyWith(
        conversation: cachedConvo,
        loading: false,
        clearError: true,
      );
    } else {
      state = state.copyWith(loading: true, clearError: true);
    }

    if (hadCache) {
      if (!chatCache.isMessagesStale(cachedPage)) {
        unawaited(_refreshFromNetwork(silent: true));
        return;
      }
    }

    await _refreshFromNetwork(silent: hadCache);
  }

  Future<void> _refreshFromNetwork({required bool silent}) async {
    final errors = <String>[];
    ChatMessagesPage? page;
    Conversation? convo;
    final candidates = _conversationIdCandidates();
    final pageSize = ChatCacheService.messagePageSize;

    if (candidates.isNotEmpty) {
      final primary = candidates.first;

      Future<ChatMessagesPage?> fetchMessages() async {
        final sw = Stopwatch()..start();
        ChatDebugLog.apiRequest(
          endpoint: 'messages',
          conversationId: primary,
        );
        try {
          final result = await repository.getMessages(primary, limit: pageSize);
          ChatDebugLog.apiResponse(
            endpoint: 'messages',
            latencyMs: sw.elapsedMilliseconds,
            count: result.results.length,
          );
          return result;
        } on ApiException catch (e) {
          errors.add(e.message);
          _noteHttpFailure();
          return null;
        }
      }

      Future<Conversation?> fetchConversation() async {
        final sw = Stopwatch()..start();
        ChatDebugLog.apiRequest(
          endpoint: 'conversation',
          conversationId: primary,
        );
        try {
          final result = await repository.getConversation(primary);
          ChatDebugLog.apiResponse(
            endpoint: 'conversation',
            latencyMs: sw.elapsedMilliseconds,
          );
          return result;
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
          page = await repository.getMessages(id, limit: pageSize);
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
        page = await repository.getMessages(convo.publicId, limit: pageSize);
        errors.clear();
      } on ApiException catch (e) {
        errors.add(e.message);
        _noteHttpFailure();
      }
    }

    if (_disposed) return;

    if (convo != null) {
      chatCache.writeConversation(convo);
    }

    if (page != null) {
      final merged = _mergeMessages(state.messages, page.results);
      final hadMessages = state.messages.isNotEmpty;
      if (hadMessages) {
        _applyMergedMessages(merged);
        state = state.copyWith(
          conversation: convo ?? state.conversation,
          hasMore: page.hasMore,
          loading: false,
          error: errors.isEmpty ? null : errors.first,
        );
      } else {
        _applyCachedSnapshot(
          messages: sortMessages(page.results),
          conversation: convo,
          hasMore: page.hasMore,
        );
        state = state.copyWith(error: errors.isEmpty ? null : errors.first);
      }
      _touchCache(state.messages, hasMore: page.hasMore);
    } else if (!silent || state.messages.isEmpty) {
      state = state.copyWith(
        conversation: convo ?? state.conversation,
        loading: false,
        error: errors.isEmpty ? null : errors.first,
      );
    }

    ChatDebugLog.cacheStats(
      memoryHits: chatCache.memoryHits,
      diskHits: chatCache.diskHits,
      misses: chatCache.misses,
      hitRatio: chatCache.hitRatio,
    );

    _noteHttpSuccess();
    if (_ws.isConnected) _markRead();
    _syncScreenCapture();
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

  Future<void> _connectWs([String? publicIdOverride]) async {
    final publicId = publicIdOverride ?? _wsPublicId;
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
        _onIncomingMessage(ChatMessage.fromWsJson(event.data, currentUserId: currentUserId));
      case 'typing_status':
        final userId = event.data['user_id'] as int?;
        if (userId != null && userId == currentUserId) return;
        final typing = event.data['is_typing'] as bool? ?? false;
        ChatDebugLog.typing(
          isTyping: typing,
          conversationId: _activeConversationId,
          incoming: true,
        );
        state = state.copyWith(isOtherUserTyping: typing);
        chatCache.setTyping(_activeConversationId, typing);
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
    ChatDebugLog.messageIn(
      type: 'chat_message',
      conversationId: _activeConversationId,
      tempId: msg.clientTempId,
      messageId: msg.id > 0 ? msg.id : null,
    );

    final messages = List<ChatMessage>.from(state.messages);
    if (msg.clientTempId != null) {
      _clearPendingAck(msg.clientTempId!);
      final idx = messages.indexWhere((m) => m.clientTempId == msg.clientTempId);
      if (idx >= 0) {
        final optimistic = messages[idx];
        messages[idx] = ChatMessage.fromWsJson(
          {
            'id': msg.id,
            'content': msg.content,
            'image_url': msg.imageUrl,
            'message_type': msg.messageType,
            'timestamp': msg.timestamp,
            'sender_id': msg.senderId,
            'sender_name': msg.senderName,
            'reply_to': msg.replyTo,
            'client_temp_id': msg.clientTempId,
            'event_code': msg.eventCode,
          },
          currentUserId: currentUserId,
          optimistic: optimistic,
        );
        _failedSends.remove(msg.clientTempId);
        ChatDebugLog.sendSuccess(
          tempId: msg.clientTempId!,
          latencyMs: 0,
          channel: 'websocket',
        );
        _commitMessages(messages);
        _touchConversationPreview(messages[idx], fromMe: messages[idx].isMine);
        _scheduleConversationsChanged();
        _markRead();
        return;
      }
    }
    if (messages.any((m) => m.id == msg.id && m.id > 0)) {
      ChatDebugLog.duplicateEvent(
        type: 'chat_message',
        conversationId: _activeConversationId,
        tempId: msg.clientTempId,
      );
      return;
    }
    messages.add(msg);
    _commitMessages(messages);
    _touchConversationPreview(msg, fromMe: msg.isMine);
    if (msg.isSystemMessage && msg.id > 0) {
      ChatDebugLog.systemMessageCreated(
        messageId: msg.id,
        conversationId: _activeConversationId,
        eventCode: msg.eventCode ?? '',
      );
      ChatDebugLog.conversationUpdated(
        conversationId: _activeConversationId,
        reason: 'system_message',
      );
    }
    _scheduleConversationsChanged();
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
      final page = await repository.getMessages(
        _activeConversationId,
        limit: ChatCacheService.messagePageSize,
      );
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
        _scheduleConversationsChanged();
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
        limit: ChatCacheService.messagePageSize,
      );
      if (_disposed) return;
      final merged = sortMessages([...page.results, ...state.messages]);
      _commitMessages(merged);
      state = state.copyWith(
        hasMore: page.hasMore,
        loadingEarlier: false,
      );
      _touchCache(merged, hasMore: page.hasMore);
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
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 2500), stopTyping);

    final now = DateTime.now();
    final shouldSignal = !_isTypingActive ||
        _lastTypingSignalAt == null ||
        now.difference(_lastTypingSignalAt!) >= const Duration(seconds: 2);

    if (shouldSignal) {
      _isTypingActive = true;
      _lastTypingSignalAt = now;
      _emitTyping(true);
    }
  }

  void stopTyping() {
    if (!_isTypingActive) return;
    _isTypingActive = false;
    _typingStopTimer?.cancel();
    _typingTimer?.cancel();
    _emitTyping(false);
  }

  void _emitTyping(bool isTyping) {
    ChatDebugLog.typing(isTyping: isTyping, conversationId: _activeConversationId);
    final payload = <String, dynamic>{
      'type': 'typing',
      'is_typing': isTyping,
      if (currentUserId != null) 'user_id': currentUserId,
    };
    if (_ws.send(payload)) return;
    if (isTyping) {
      unawaited(repository.sendTyping(_activeConversationId));
    }
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    stopTyping();
    await _sendPayload(content: trimmed, replyToId: state.replyingTo?.id);
  }

  Future<void> _sendPayload({
    required String content,
    String imageUrl = '',
    int? replyToId,
    String? existingTempId,
    Stopwatch? started,
  }) async {
    final replyTarget = replyToId != null
        ? state.messages.cast<ChatMessage?>().firstWhere(
              (m) => m?.id == replyToId,
              orElse: () => state.replyingTo,
            )
        : state.replyingTo;

    final tempId = existingTempId ??
        'tmp-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final sendStarted = started ?? (Stopwatch()..start());

    if (existingTempId == null) {
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

      ChatDebugLog.sendStart(
        conversationId: _activeConversationId,
        tempId: tempId,
        channel: _ws.isConnected ? 'websocket' : 'http',
      );

      state = _withMessages(
        state.copyWith(
          clearReplyingTo: true,
          showEmojiPicker: false,
        ),
        sortMessages([...state.messages, optimistic]),
      );
      _touchCache(state.messages);
      _touchConversationPreview(optimistic, fromMe: true);
    } else {
      _failedSends[tempId] = _PendingSend(
        content: content,
        imageUrl: imageUrl,
        replyToId: replyToId ?? replyTarget?.id,
      );
    }

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
        _schedulePendingAck(tempId, sendStarted);
      } else {
        await _commitViaHttp(tempId, sendStarted);
      }
      _noteHttpSuccess();
      _scheduleConversationsChanged();
    } on ApiException catch (e) {
      _markFailed(tempId, e.message, sendStarted);
      _noteHttpFailure();
    } catch (e) {
      _markFailed(tempId, e.toString(), sendStarted);
    }
  }

  void _schedulePendingAck(String tempId, Stopwatch started) {
    _pendingAckTimers[tempId]?.cancel();
    _pendingAckTimers[tempId] = Timer(_ackTimeout, () async {
      if (_disposed) return;
      final stillPending = state.messages.any(
        (m) => m.clientTempId == tempId && m.sendStatus == MessageSendStatus.pending,
      );
      if (stillPending) {
        try {
          await _commitViaHttp(tempId, started);
        } catch (e) {
          _markFailed(tempId, e.toString(), started);
        }
      }
    });
  }

  Future<void> _commitViaHttp(String tempId, Stopwatch started) async {
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
    ChatDebugLog.sendSuccess(
      tempId: tempId,
      latencyMs: started.elapsedMilliseconds,
      channel: 'http',
    );
    _noteHttpSuccess();
  }

  void _markFailed(String tempId, String error, Stopwatch started) {
    _clearPendingAck(tempId);
    ChatDebugLog.sendFailure(
      tempId: tempId,
      error: error,
      latencyMs: started.elapsedMilliseconds,
    );
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

    final tempId = 'tmp-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final optimistic = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      content: '',
      messageType: 'image',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      isMine: true,
      clientTempId: tempId,
      sendStatus: MessageSendStatus.pending,
      localMediaPath: file.path,
    );
    _failedSends[tempId] = const _PendingSend(content: '', imageUrl: '');

    final sendStarted = Stopwatch()..start();
    state = _withMessages(
      state.copyWith(uploading: true),
      sortMessages([...state.messages, optimistic]),
    );
    _touchConversationPreview(optimistic, fromMe: true);

    try {
      final imageUrl = await repository.uploadChatImage(file.path);
      _failedSends[tempId] = _PendingSend(content: '', imageUrl: imageUrl);
      final messages = List<ChatMessage>.from(state.messages);
      final idx = messages.indexWhere((m) => m.clientTempId == tempId);
      if (idx >= 0) {
        messages[idx] = messages[idx].copyWith(
          imageUrl: imageUrl,
          localMediaPath: file.path,
        );
        _patchMessages(messages);
      }
      await _sendPayload(content: '', imageUrl: imageUrl, existingTempId: tempId, started: sendStarted);
    } on ApiException catch (e) {
      _markFailed(tempId, e.message, sendStarted);
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
    if (state.isRecording || state.uploading) return false;

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
        ? state.copyWith(clearReplyingTo: true, showEmojiPicker: false)
        : state.copyWith(replyingTo: msg, showEmojiPicker: false);
  }

  void openEmojiPicker() {
    if (state.showEmojiPicker) return;
    ChatDebugLog.emojiPickerOpened();
    state = state.copyWith(showEmojiPicker: true);
  }

  void closeEmojiPicker() {
    if (!state.showEmojiPicker) return;
    ChatDebugLog.emojiPickerClosed();
    state = state.copyWith(showEmojiPicker: false);
  }

  void toggleEmojiPicker() {
    if (state.showEmojiPicker) {
      closeEmojiPicker();
    } else {
      openEmojiPicker();
    }
  }

  Future<void> updateSettings({
    bool? muted,
    bool? pinned,
    bool? notifyScreenshots,
    bool? secureChat,
  }) async {
    final convo = state.conversation;
    if (convo == null) return;
    try {
      await repository.updateConversationSettings(
        convo.publicId,
        muted: muted,
        pinned: pinned,
        notifyScreenshots: notifyScreenshots,
        secureChat: secureChat,
      );
      state = state.copyWith(
        conversation: convo.copyWith(
          isMuted: muted ?? convo.isMuted,
          isPinned: pinned ?? convo.isPinned,
          notifyScreenshots: notifyScreenshots ?? convo.notifyScreenshots,
          secureChat: secureChat ?? convo.secureChat,
        ),
      );
      _syncScreenCapture();
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

  Future<bool> block() async {
    try {
      await repository.block(_activeConversationId);
      onConversationsChanged();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> unmatchAndBlock() async {
    try {
      await repository.unmatchAndBlock(_activeConversationId);
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
      await chatCache.clearMessages(_activeConversationId);
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

  void setAppInBackground(bool inBackground) {
    _ws.setAppInBackground(inBackground);
  }

  @override
  void dispose() {
    _disposed = true;
    stopTyping();
    _typingTimer?.cancel();
    _typingStopTimer?.cancel();
    _typingClearTimer?.cancel();
    _conversationsInvalidateTimer?.cancel();
    _stopVoiceTimer();
    unawaited(_voiceRecorder?.dispose());
    for (final timer in _pendingAckTimers.values) {
      timer.cancel();
    }
    _pendingAckTimers.clear();
    _wsSub?.cancel();
    _connSub?.cancel();
    _screenCapture?.stop();
    _ws.dispose();
    super.dispose();
  }
}
