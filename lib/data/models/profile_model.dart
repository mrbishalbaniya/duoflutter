import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    int? id,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'full_name') required String fullName,
    int? age,
    String? gender,
    String? bio,
    String? location,
    String? education,
    String? occupation,
    String? religion,
    @JsonKey(name: 'work_preference') String? workPreference,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'photo_urls') List<String>? photoUrls,
    @JsonKey(name: 'lifestyle_tags') List<String>? lifestyleTags,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'is_premium') @Default(false) bool isPremium,
    @JsonKey(name: 'relationship_goal') String? relationshipGoal,
    @JsonKey(name: 'preview_distance_km') double? previewDistanceKm,
    @JsonKey(name: 'location_shared') bool? locationShared,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}
