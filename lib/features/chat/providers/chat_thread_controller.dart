import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/chat_repository.dart';
import '../chat_utils.dart';
import '../domain/chat_thread_state.dart';
import '../services/chat_websocket_service.dart';
import 'chat_providers.dart';

final chatThreadControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatThreadController, ChatThreadState, String>((ref, conversationId) {
  final controller = ChatThreadController(
    conversationId: conversationId,
    repository: ref.read(chatRepositoryProvider),
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
    required this.onConversationsChanged,
  }) : super(const ChatThreadState()) {
    _ws = ChatWebSocketService(repository);
    unawaited(_init());
  }

  final String conversationId;
  final ChatRepository repository;
  final VoidCallback onConversationsChanged;

  late final ChatWebSocketService _ws;
  final _picker = ImagePicker();
  final _failedSends = <String, _PendingSend>{};
  final _pendingAckTimers = <String, Timer>{};

  Timer? _typingTimer;
  Timer? _typingClearTimer;
  StreamSubscription<ChatWsEvent>? _wsSub;
  StreamSubscription<bool>? _connSub;
  bool _disposed = false;
  int _pollCycle = 0;

  Future<void> _init() async {
    await load();
    await _connectWs();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await Future.wait([
        repository.getConversation(conversationId),
        repository.getMessages(conversationId, limit: 50),
      ]);
      final convo = results[0] as Conversation;
      final page = results[1] as ChatMessagesPage;
      if (_disposed) return;
      state = state.copyWith(
        conversation: convo,
        messages: sortMessages(page.results),
        isOtherUserTyping: convo.isOtherUserTyping,
        hasMore: page.hasMore,
        loading: false,
        initialScrollPending: true,
      );
    } on ApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  Future<void> reconnect() async {
    await _ws.reconnect();
  }

  Future<void> _connectWs() async {
    _wsSub?.cancel();
    _connSub?.cancel();

    _connSub = _ws.connectionStream.listen((connected) {
      if (_disposed) return;
      state = state.copyWith(wsConnected: connected);
      if (connected) {
        _ws.send({'type': 'mark_read'});
      }
    });

    _wsSub = _ws.events.listen(_handleWsEvent);
    await _ws.connect(conversationId);
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
        state = state.copyWith(messages: sortMessages(messages));
        onConversationsChanged();
        return;
      }
    }
    if (messages.any((m) => m.id == msg.id && m.id > 0)) return;
    messages.add(msg);
    state = state.copyWith(messages: sortMessages(messages));
    onConversationsChanged();
  }

  void _onMessageReacted(Map<String, dynamic> data) {
    final messageId = data['id'] as int?;
    if (messageId == null) return;
    final reactions = _parseReactionsMap(data['reactions']);
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(reactions: reactions);
      }).toList(),
    );
  }

  void _onMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['id'] as int?;
    final deleteType = data['delete_type'] as String? ?? 'for_me';
    if (messageId == null) return;
    state = state.copyWith(
      messages: state.messages
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
    );
  }

  void _onMessagesRead(Map<String, dynamic> data) {
    final ids = (data['message_ids'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final now = DateTime.now().toUtc().toIso8601String();
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (!m.isMine) return m;
        if (ids.isNotEmpty && !ids.contains(m.id)) return m;
        return m.copyWith(
          isRead: true,
          readAt: m.readAt ?? now,
          deliveredAt: m.deliveredAt ?? now,
        );
      }).toList(),
    );
  }

  Future<void> _pollLatestMessages() async {
    try {
      _pollCycle++;
      final page = await repository.getMessages(conversationId, limit: 50);
      if (_disposed || page.results.isEmpty) return;
      final merged = _mergeMessages(state.messages, page.results);
      state = state.copyWith(messages: merged);
      if (_pollCycle % 3 == 0) {
        onConversationsChanged();
      }
    } catch (_) {}
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

  Future<void> loadEarlier() async {
    if (state.loadingEarlier || !state.hasMore || state.messages.isEmpty) return;
    state = state.copyWith(loadingEarlier: true);
    try {
      final oldest = state.messages.firstWhere((m) => m.id > 0, orElse: () => state.messages.first);
      final page = await repository.getMessages(
        conversationId,
        before: oldest.id.toString(),
        limit: 50,
      );
      if (_disposed) return;
      state = state.copyWith(
        messages: sortMessages([...page.results, ...state.messages]),
        hasMore: page.hasMore,
        loadingEarlier: false,
      );
    } catch (_) {
      if (!_disposed) state = state.copyWith(loadingEarlier: false);
    }
  }

  void onScrollNearTop() {
    if (!state.loadingEarlier && state.hasMore) {
      loadEarlier();
    }
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
      repository.sendTyping(conversationId);
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
      messageType: imageUrl.isNotEmpty ? 'image' : 'text',
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

    state = state.copyWith(
      sending: true,
      messages: sortMessages([...state.messages, optimistic]),
      clearReplyingTo: true,
      showEmojiPicker: false,
    );

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
      onConversationsChanged();
    } on ApiException catch (e) {
      _markFailed(tempId, e.message);
    } catch (e) {
      _markFailed(tempId, e.toString());
    } finally {
      if (!_disposed) state = state.copyWith(sending: false);
    }
  }

  void _schedulePendingAck(String tempId) {
    _pendingAckTimers[tempId]?.cancel();
    _pendingAckTimers[tempId] = Timer(const Duration(seconds: 10), () async {
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
      conversationId,
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
      state = state.copyWith(messages: sortMessages(messages));
    }
  }

  void _markFailed(String tempId, String error) {
    _clearPendingAck(tempId);
    final messages = state.messages.map((m) {
      if (m.clientTempId == tempId) {
        return m.copyWith(sendStatus: MessageSendStatus.failed);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: messages, error: error);
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

  Future<void> react(ChatMessage msg, String emoji) async {
    try {
      final updated = await repository.reactToMessage(msg.id, emoji);
      _ws.send({'type': 'message_reaction', 'id': msg.id, 'emoji': emoji});
      state = state.copyWith(
        messages: state.messages
            .map((m) => m.id == msg.id ? updated : m)
            .toList(),
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
        state = state.copyWith(
          messages: state.messages
              .map(
                (m) => m.id == msg.id
                    ? m.copyWith(
                        isDeletedForEveryone: true,
                        content: 'This message was deleted',
                      )
                    : m,
              )
              .toList(),
        );
      } else {
        state = state.copyWith(
          messages: state.messages.where((m) => m.id != msg.id).toList(),
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  void retryFailed(ChatMessage msg, void Function(String) setText) {
    final payload = msg.clientTempId != null ? _failedSends[msg.clientTempId!] : null;
    state = state.copyWith(
      messages: state.messages
          .where((m) => m.clientTempId != msg.clientTempId)
          .toList(),
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
      await repository.unmatch(conversationId);
      onConversationsChanged();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> report(String reason) async {
    try {
      await repository.report(conversationId, reason: reason);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      await repository.clearConversationHistory(conversationId);
      state = state.copyWith(messages: []);
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
