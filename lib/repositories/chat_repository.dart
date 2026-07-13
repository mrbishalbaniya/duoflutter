import 'package:dio/dio.dart';

import '../core/models/chat_models.dart';
import '../core/network/dio_client.dart';

class ChatRepository {
  ChatRepository(this._client);

  final DioClient _client;

  Future<List<Conversation>> getConversations({bool archived = false, bool unread = false}) async {
    final response = await _client.get<List<dynamic>>(
      '/chat/conversations/',
      queryParameters: {
        if (archived) 'archived': 'true',
        if (unread) 'unread': 'true',
      },
    );
    return (response.data ?? [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> getConversation(String conversationId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/',
    );
    return Conversation.fromJson(response.data!);
  }

  Future<ChatMessagesPage> getMessages(
    String conversationId, {
    int limit = 50,
    String? before,
  }) async {
    final response = await _client.get<dynamic>(
      '/chat/conversations/$conversationId/messages/',
      queryParameters: {
        'limit': limit,
        if (before != null) 'before': before,
      },
    );
    return _parseMessagesPage(response.data, limit: limit);
  }

  ChatMessagesPage _parseMessagesPage(dynamic data, {int limit = 50}) {
    if (data is List) {
      final results = data
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return ChatMessagesPage(
        results: results,
        hasMore: results.length >= limit,
      );
    }

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final results = (map['results'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return ChatMessagesPage(
      results: results,
      hasMore: map['has_more'] as bool? ?? false,
      nextBefore: map['next_before'] as int?,
    );
  }

  Future<ChatMessage> sendMessage(
    String conversationId, {
    String? content,
    String? imageUrl,
    int? replyToId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/messages/',
      data: {
        'content': content ?? '',
        'image_url': imageUrl ?? '',
        if (replyToId != null) 'reply_to_id': replyToId,
      },
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> sendTyping(String conversationId) async {
    await _client.post('/chat/conversations/$conversationId/typing/');
  }

  Future<String> getWsTicket(String conversationId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/ws-ticket/',
    );
    return response.data!['ticket'] as String;
  }

  Future<String> uploadChatImage(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _client.upload<Map<String, dynamic>>('/chat/upload/', form);
    return response.data!['image_url'] as String;
  }

  Future<ChatMessage> reactToMessage(int messageId, String emoji) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/chat/messages/$messageId/react/',
      data: {'emoji': emoji},
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> deleteMessage(int messageId, {required String deleteType}) async {
    await _client.post('/chat/messages/$messageId/delete/', data: {
      'delete_type': deleteType,
    });
  }

  Future<void> updateConversationSettings(
    String conversationId, {
    String? nickname,
    bool? archived,
    bool? muted,
    bool? pinned,
    bool? notifyScreenshots,
    bool? secureChat,
  }) async {
    await _client.patch('/chat/conversations/$conversationId/settings/', data: {
      if (nickname != null) 'nickname': nickname,
      if (archived != null) 'is_archived': archived,
      if (muted != null) 'is_muted': muted,
      if (pinned != null) 'is_pinned': pinned,
      if (notifyScreenshots != null) 'notify_screenshots': notifyScreenshots,
      if (secureChat != null) 'secure_chat': secureChat,
    });
  }

  Future<ChatMessage> reportSecurityEvent(
    String conversationId, {
    required String eventCode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/security-events/',
      data: {'event_code': eventCode},
    );
    return ChatMessage.fromJson(response.data!);
  }

  Future<void> unmatch(String conversationId) async {
    await _client.post('/chat/conversations/$conversationId/unmatch/');
  }

  Future<void> block(String conversationId) async {
    await _client.post('/chat/conversations/$conversationId/block/');
  }

  Future<void> unmatchAndBlock(String conversationId) async {
    await _client.post('/chat/conversations/$conversationId/unmatch-and-block/');
  }

  Future<void> report(String conversationId, {required String reason}) async {
    await _client.post('/chat/conversations/$conversationId/report/', data: {
      'reason': reason,
    });
  }

  Future<void> clearConversationHistory(String conversationId) async {
    await _client.post('/chat/conversations/$conversationId/clear/');
  }
}
