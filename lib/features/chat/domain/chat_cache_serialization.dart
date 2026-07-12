import '../../../core/models/chat_models.dart';

/// JSON helpers for Hive chat cache (not API payloads).
abstract final class ChatCacheSerialization {
  static Map<String, dynamic> messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      if (message.imageUrl != null) 'image_url': message.imageUrl,
      'message_type': message.messageType,
      if (message.eventCode != null) 'event_code': message.eventCode,
      'timestamp': message.timestamp,
      if (message.senderId != null) 'sender_id': message.senderId,
      if (message.senderName != null) 'sender_name': message.senderName,
      'is_mine': message.isMine,
      'is_read': message.isRead,
      if (message.deliveredAt != null) 'delivered_at': message.deliveredAt,
      if (message.readAt != null) 'read_at': message.readAt,
      'is_deleted_for_everyone': message.isDeletedForEveryone,
      'is_deleted_for_me': message.isDeletedForMe,
      if (message.reactions.isNotEmpty) 'reactions': message.reactions,
      if (message.replyTo != null) 'reply_to': message.replyTo,
      if (message.clientTempId != null) 'client_temp_id': message.clientTempId,
      'send_status': message.sendStatus.name,
    };
  }

  static ChatMessage messageFromJson(Map<String, dynamic> json) {
    final statusRaw = json['send_status'] as String?;
    final status = MessageSendStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => MessageSendStatus.sent,
    );
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      eventCode: json['event_code'] as String?,
      timestamp: (json['timestamp'] ?? '').toString(),
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      deliveredAt: json['delivered_at'] as String?,
      readAt: json['read_at'] as String?,
      isDeletedForEveryone: json['is_deleted_for_everyone'] as bool? ?? false,
      isDeletedForMe: json['is_deleted_for_me'] as bool? ?? false,
      reactions: _parseReactions(json['reactions']),
      replyTo: json['reply_to'] is Map<String, dynamic>
          ? json['reply_to'] as Map<String, dynamic>
          : null,
      clientTempId: json['client_temp_id'] as String?,
      sendStatus: status,
    );
  }

  static Map<String, dynamic> conversationToJson(Conversation conversation) {
    final profile = conversation.otherUserProfile;
    return {
      'id': conversation.id,
      'public_id': conversation.publicId,
      if (conversation.matchId != null) 'match_id': conversation.matchId,
      if (conversation.matchCreatedAt != null) 'match_created_at': conversation.matchCreatedAt,
      'other_user_profile': {
        if (profile.id != null) 'id': profile.id,
        if (profile.userId != null) 'user_id': profile.userId,
        'full_name': profile.fullName,
        if (profile.photoUrl != null) 'photo_url': profile.photoUrl,
        if (profile.photoUrls.isNotEmpty) 'photo_urls': profile.photoUrls,
        'is_verified': profile.isVerified,
        if (profile.age != null) 'age': profile.age,
        if (profile.location != null) 'location': profile.location,
      },
      if (conversation.otherUserNickname != null)
        'other_user_nickname': conversation.otherUserNickname,
      if (conversation.lastMessage != null)
        'last_message': messageToJson(conversation.lastMessage!),
      if (conversation.lastMessageAt != null) 'last_message_at': conversation.lastMessageAt,
      'unread_count': conversation.unreadCount,
      'is_other_user_typing': conversation.isOtherUserTyping,
      'is_archived': conversation.isArchived,
      'is_muted': conversation.isMuted,
      'is_pinned': conversation.isPinned,
      'notify_screenshots': conversation.notifyScreenshots,
      'secure_chat': conversation.secureChat,
    };
  }

  static Conversation conversationFromJson(Map<String, dynamic> json) {
    return Conversation.fromJson(json);
  }

  static Map<String, dynamic> messagesPageToJson({
    required List<ChatMessage> messages,
    required bool hasMore,
    required int cachedAtMs,
  }) {
    return {
      'messages': messages.map(messageToJson).toList(),
      'has_more': hasMore,
      'cached_at_ms': cachedAtMs,
    };
  }

  static CachedMessagePage? messagesPageFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final list = map['messages'] as List<dynamic>? ?? const [];
    final messages = list
        .whereType<Map>()
        .map((e) => messageFromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (messages.isEmpty) return null;
    return CachedMessagePage(
      messages: messages,
      hasMore: map['has_more'] as bool? ?? true,
      cachedAtMs: map['cached_at_ms'] as int? ?? 0,
    );
  }

  static Map<String, int> _parseReactions(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) {
        if (value is num) return MapEntry('$key', value.toInt());
        return MapEntry('$key', 0);
      },
    );
  }
}

class CachedMessagePage {
  const CachedMessagePage({
    required this.messages,
    required this.hasMore,
    required this.cachedAtMs,
  });

  final List<ChatMessage> messages;
  final bool hasMore;
  final int cachedAtMs;
}

class CachedConversationList {
  const CachedConversationList({
    required this.conversations,
    required this.cachedAtMs,
  });

  final List<Conversation> conversations;
  final int cachedAtMs;
}
