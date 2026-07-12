import 'package:freezed_annotation/freezed_annotation.dart';
import 'profile_model.dart';
import 'message_model.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required int id,
    @JsonKey(name: 'public_id') String? publicId,
    @JsonKey(name: 'match_id') int? matchId,
    @JsonKey(name: 'match_created_at') String? matchCreatedAt,
    @JsonKey(name: 'other_user_nickname') String? otherUserNickname,
    @JsonKey(name: 'other_user_profile') ProfileModel? otherUserProfile,
    @JsonKey(name: 'last_message') MessageModel? lastMessage,
    @JsonKey(name: 'last_message_at') String? lastMessageAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'is_muted') @Default(false) bool isMuted,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @JsonKey(name: 'is_other_user_typing') @Default(false) bool isOtherUserTyping,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);
}

@freezed
class ConversationDetail with _$ConversationDetail {
  const factory ConversationDetail({
    required int id,
    @JsonKey(name: 'public_id') String? publicId,
    @JsonKey(name: 'match_id') int? matchId,
    @JsonKey(name: 'match_created_at') String? matchCreatedAt,
    @JsonKey(name: 'other_user_nickname') String? otherUserNickname,
    @JsonKey(name: 'other_user_profile') ProfileModel? otherUserProfile,
    @JsonKey(name: 'last_message') MessageModel? lastMessage,
    @JsonKey(name: 'last_message_at') String? lastMessageAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'is_muted') @Default(false) bool isMuted,
    @JsonKey(name: 'is_pinned') @Default(false) bool isPinned,
    @JsonKey(name: 'is_other_user_typing') @Default(false) bool isOtherUserTyping,
  }) = _ConversationDetail;

  factory ConversationDetail.fromJson(Map<String, dynamic> json) =>
      _$ConversationDetailFromJson(json);
}
