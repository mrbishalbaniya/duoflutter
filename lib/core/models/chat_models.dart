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
    this.reactions = const {},
    this.replyTo,
    this.clientTempId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      timestamp: json['timestamp'] as String? ?? '',
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      reactions: Map<String, int>.from(
        (json['reactions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      ),
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
  final Map<String, int> reactions;
  final Map<String, dynamic>? replyTo;
  final String? clientTempId;

  ChatMessage copyWith({int? id, bool? isRead}) => ChatMessage(
        id: id ?? this.id,
        content: content,
        imageUrl: imageUrl,
        messageType: messageType,
        timestamp: timestamp,
        senderId: senderId,
        senderName: senderName,
        isMine: isMine,
        isRead: isRead ?? this.isRead,
        reactions: reactions,
        replyTo: replyTo,
        clientTempId: clientTempId,
      );

  @override
  List<Object?> get props => [id, content, timestamp, isRead];
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
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      publicId: json['public_id']?.toString() ?? json['id'].toString(),
      matchId: json['match_id'] as int?,
      otherUserProfile: DuoProfile.fromJson(
        json['other_user_profile'] as Map<String, dynamic>,
      ),
      otherUserNickname: json['other_user_nickname'] as String?,
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
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

  String get displayName =>
      (otherUserNickname != null && otherUserNickname!.isNotEmpty)
          ? otherUserNickname!
          : otherUserProfile.displayName;

  @override
  List<Object?> get props => [publicId, unreadCount, lastMessageAt];
}
