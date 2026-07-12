import 'package:equatable/equatable.dart';

import 'user_models.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    this.content = '',
    this.imageUrl,
    this.messageType = 'text',
    required this.timestamp,
    this.senderId,
    this.senderName,
    this.isMine = false,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.isDeletedForEveryone = false,
    this.isDeletedForMe = false,
    this.reactions = const {},
    this.replyTo,
    this.clientTempId,
    this.sendStatus = MessageSendStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      timestamp: (json['timestamp'] ?? json['created_at'] ?? '').toString(),
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      deliveredAt: json['delivered_at'] as String?,
      readAt: json['read_at'] as String?,
      isDeletedForEveryone: json['is_deleted_for_everyone'] as bool? ?? false,
      isDeletedForMe: json['is_deleted_for_me'] as bool? ?? false,
      reactions: _parseReactions(json['reactions']),
      replyTo: json['reply_to'] as Map<String, dynamic>?,
      clientTempId: json['client_temp_id'] as String?,
    );
  }

  final int id;
  final String content;
  final String? imageUrl;
  final String messageType;
  final String timestamp;
  final int? senderId;
  final String? senderName;
  final bool isMine;
  final bool isRead;
  final String? deliveredAt;
  final String? readAt;
  final bool isDeletedForEveryone;
  final bool isDeletedForMe;
  final Map<String, int> reactions;
  final Map<String, dynamic>? replyTo;
  final String? clientTempId;
  final MessageSendStatus sendStatus;

  bool get isVisible => !isDeletedForMe;

  ChatMessage copyWith({
    int? id,
    String? content,
    String? imageUrl,
    String? messageType,
    String? timestamp,
    bool? isMine,
    bool? isRead,
    String? deliveredAt,
    String? readAt,
    bool? isDeletedForEveryone,
    bool? isDeletedForMe,
    Map<String, int>? reactions,
    Map<String, dynamic>? replyTo,
    MessageSendStatus? sendStatus,
    String? clientTempId,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        messageType: messageType ?? this.messageType,
        timestamp: timestamp ?? this.timestamp,
        senderId: senderId,
        senderName: senderName,
        isMine: isMine ?? this.isMine,
        isRead: isRead ?? this.isRead,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
        isDeletedForMe: isDeletedForMe ?? this.isDeletedForMe,
        reactions: reactions ?? this.reactions,
        replyTo: replyTo ?? this.replyTo,
        clientTempId: clientTempId ?? this.clientTempId,
        sendStatus: sendStatus ?? this.sendStatus,
      );

  @override
  List<Object?> get props =>
      [id, content, timestamp, isRead, deliveredAt, readAt, reactions, sendStatus];
}

Map<String, int> _parseReactions(dynamic raw) {
  if (raw is! Map) return const {};
  return raw.map(
    (key, value) {
      if (value is List) return MapEntry('$key', value.length);
      if (value is num) return MapEntry('$key', value.toInt());
      return MapEntry('$key', 0);
    },
  );
}

class ChatMessagesPage extends Equatable {
  const ChatMessagesPage({
    required this.results,
    required this.hasMore,
    this.nextBefore,
  });

  final List<ChatMessage> results;
  final bool hasMore;
  final int? nextBefore;

  @override
  List<Object?> get props => [results.length, hasMore, nextBefore];
}

enum MessageSendStatus { pending, sent, failed }

ChatMessage? _parseLastMessage(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    return ChatMessage(
      id: 0,
      content: raw,
      timestamp: '',
      isMine: false,
    );
  }
  if (raw is Map<String, dynamic>) {
    return ChatMessage.fromJson(raw);
  }
  return null;
}

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.publicId,
    this.matchId,
    required this.otherUserProfile,
    this.otherUserNickname,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOtherUserTyping = false,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.matchCreatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['other_user_profile'];
    return Conversation(
      id: json['id'] as int? ?? 0,
      publicId: json['public_id']?.toString() ?? json['id'].toString(),
      matchId: json['match_id'] as int?,
      matchCreatedAt: json['match_created_at'] as String?,
      otherUserProfile: profileRaw is Map<String, dynamic>
          ? DuoProfile.fromJson(profileRaw)
          : const DuoProfile(fullName: 'Chat'),
      otherUserNickname: json['other_user_nickname'] as String?,
      lastMessage: _parseLastMessage(json['last_message']),
      lastMessageAt: json['last_message_at'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isOtherUserTyping: json['is_other_user_typing'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  final int id;
  final String publicId;
  final int? matchId;
  final DuoProfile otherUserProfile;
  final String? otherUserNickname;
  final ChatMessage? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final bool isOtherUserTyping;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final String? matchCreatedAt;

  String get displayName =>
      (otherUserNickname != null && otherUserNickname!.isNotEmpty)
          ? otherUserNickname!
          : otherUserProfile.displayName;

  Conversation copyWith({
    String? otherUserNickname,
    bool clearNickname = false,
    int? unreadCount,
    bool? isOtherUserTyping,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    ChatMessage? lastMessage,
    String? lastMessageAt,
  }) =>
      Conversation(
        id: id,
        publicId: publicId,
        matchId: matchId,
        otherUserProfile: otherUserProfile,
        otherUserNickname: clearNickname ? null : (otherUserNickname ?? this.otherUserNickname),
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
        isArchived: isArchived ?? this.isArchived,
        isMuted: isMuted ?? this.isMuted,
        isPinned: isPinned ?? this.isPinned,
        matchCreatedAt: matchCreatedAt,
      );

  @override
  List<Object?> get props => [publicId, unreadCount, lastMessageAt];
}
