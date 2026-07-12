import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('voice')
  voice,
}

enum SendStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}

@freezed
class MessageReplyPreview with _$MessageReplyPreview {
  const factory MessageReplyPreview({
    required int id,
    required String content,
    @JsonKey(name: 'sender_name') required String senderName,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'message_type') String? messageType,
  }) = _MessageReplyPreview;

  factory MessageReplyPreview.fromJson(Map<String, dynamic> json) =>
      _$MessageReplyPreviewFromJson(json);
}

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required int id,
    @JsonKey(name: 'sender_id') required int senderId,
    @JsonKey(name: 'sender_name') String? senderName,
    @JsonKey(name: 'sender_photo') String? senderPhoto,
    required String content,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'message_type') @Default(MessageType.text) MessageType messageType,
    required String timestamp,
    @JsonKey(name: 'delivered_at') String? deliveredAt,
    @JsonKey(name: 'read_at') String? readAt,
    @JsonKey(name: 'edited_at') String? editedAt,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'is_mine') @Default(false) bool isMine,
    @JsonKey(name: 'is_deleted_for_me') @Default(false) bool isDeletedForMe,
    @JsonKey(name: 'is_deleted_for_everyone') @Default(false) bool isDeletedForEveryone,
    @JsonKey(name: 'reply_to') MessageReplyPreview? replyTo,
    @Default({}) Map<String, dynamic> reactions,
    @JsonKey(name: 'client_temp_id') String? clientTempId,
    @JsonKey(name: 'send_status') SendStatus? sendStatus,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

@freezed
class MessagesResponse with _$MessagesResponse {
  const factory MessagesResponse({
    required List<MessageModel> results,
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'next_before') int? nextBefore,
  }) = _MessagesResponse;

  factory MessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesResponseFromJson(json);
}
