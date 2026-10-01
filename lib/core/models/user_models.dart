import 'package:equatable/equatable.dart';

import 'package:duo_mobile/core/media/cloudinary_url.dart';

class DuoProfile extends Equatable {
  const DuoProfile({
    this.id,
    this.userId,
    this.username,
    this.email,
    this.fullName = '',
    this.age,
    this.gender,
    this.location,
    this.bio,
    this.photoUrl,
    this.photoUrls = const [],
    this.isVerified = false,
    this.isOnboarded = false,
    this.isPremium = false,
    this.subscriptionExpiresAt,
    this.walletBalance,
    this.profileCompleteness = 0,
    this.profileChecklist = const [],
    this.previewDistanceKm,
    this.distanceKm,
    this.locked = false,
    this.locationShared = true,
    this.locationGhostMode = false,
    this.locationVisibility = 'friends',
    this.locationVisibilityFriends = const [],
    this.mapLatitude,
    this.mapLongitude,
    this.locationIsLive = false,
    this.liveLocationUpdatedAt,
    this.education,
    this.occupation,
    this.religion,
    this.workPreference,
    this.lifestyleTags = const [],
    this.relationshipGoal,
    this.prefAgeMin,
    this.prefAgeMax,
    this.prefLocation,
    this.prefMaxDistanceKm,
    this.prefGender,
    this.prefRelationshipGoal,
    this.prefVerifiedOnly = false,
    this.prefExpandDistance = true,
    this.prefExpandAge = true,
    this.phoneCountryCode,
    this.phoneNumber,
    this.prefMinHeight,
    this.prefOccupation,
    this.prefValues,
    this.appLanguage = 'en',
    this.appRegion = 'Nepal',
  });

  factory DuoProfile.fromJson(Map<String, dynamic> json) {
    return DuoProfile(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      fullName: json['full_name'] as String? ?? '',
      age: json['age'],
      gender: json['gender'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isVerified: json['is_verified'] as bool? ?? false,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      subscriptionExpiresAt: json['subscription_expires_at'] as String?,
      walletBalance: json['wallet_balance'] as int?,
      profileCompleteness: json['profile_completeness'] as int? ?? 0,
      profileChecklist: (json['profile_checklist'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProfileChecklistItem.fromJson)
          .toList(),
      previewDistanceKm: (json['preview_distance_km'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toInt(),
      locked: json['locked'] as bool? ?? false,
      locationShared: json['location_shared'] as bool? ?? true,
      locationGhostMode: json['location_ghost_mode'] as bool? ?? false,
      locationVisibility: json['location_visibility'] as String? ?? 'friends',
      locationVisibilityFriends: (json['location_visibility_friends'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      // ProfileSerializer (profile fetch/update responses) exposes these as
      // live_latitude/live_longitude/live_location_updated_at, while
      // LiveLocationView's POST response uses map_latitude/map_longitude/
      // location_is_live instead. Accept both so either response shape parses.
      mapLatitude: (json['live_latitude'] as num?)?.toDouble() ??
          (json['map_latitude'] as num?)?.toDouble(),
      mapLongitude: (json['live_longitude'] as num?)?.toDouble() ??
          (json['map_longitude'] as num?)?.toDouble(),
      locationIsLive: json['location_is_live'] as bool? ??
          json['live_latitude'] != null,
      liveLocationUpdatedAt: json['live_location_updated_at'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      religion: json['religion'] as String?,
      workPreference: json['work_preference'] as String?,
      lifestyleTags: (json['lifestyle_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      relationshipGoal: json['relationship_goal'] as String?,
      prefAgeMin: json['pref_age_min'] as int?,
      prefAgeMax: json['pref_age_max'] as int?,
      prefLocation: json['pref_location'] as String?,
      prefMaxDistanceKm: json['pref_max_distance_km'] as int?,
      prefGender: json['pref_gender'] as String?,
      prefRelationshipGoal: json['pref_relationship_goal'] as String?,
      prefVerifiedOnly: json['pref_verified_only'] as bool? ?? false,
      prefExpandDistance: json['pref_expand_distance'] as bool? ?? true,
      prefExpandAge: json['pref_expand_age'] as bool? ?? true,
      phoneCountryCode: json['phone_country_code'] as String?,
      phoneNumber: json['phone_number'] as String?,
      prefMinHeight: json['pref_min_height'] as String?,
      prefOccupation: json['pref_occupation'] as String?,
      prefValues: json['pref_values'] as String?,
      appLanguage: json['app_language'] as String? ?? 'en',
      appRegion: (json['app_region'] as String?)?.trim().isNotEmpty == true
          ? (json['app_region'] as String).trim()
          : 'Nepal',
    );
  }

  Map<String, dynamic> toJson() => {
        if (fullName.isNotEmpty) 'full_name': fullName,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (location != null) 'location': location,
        if (bio != null) 'bio': bio,
      };

  final int? id;
  final int? userId;
  final String? username;
  final String? email;
  final String fullName;
  final dynamic age;
  final String? gender;
  final String? location;
  final String? bio;
  final String? photoUrl;
  final List<String> photoUrls;
  final bool isVerified;
  final bool isOnboarded;
  final bool isPremium;
  final String? subscriptionExpiresAt;
  final int? walletBalance;
  final int profileCompleteness;

  /// Backend completeness checklist, grouped by profile section (web ProfileChecklist).
  final List<ProfileChecklistItem> profileChecklist;
  final double? previewDistanceKm;

  /// Real rounded distance from the viewer on Match results (0 = under 1 km);
  /// null when unknown or the person is in ghost mode.
  final int? distanceKm;
  final bool locked;
  final bool locationShared;
  final bool locationGhostMode;
  final String locationVisibility;
  final List<int> locationVisibilityFriends;
  final double? mapLatitude;
  final double? mapLongitude;
  final bool locationIsLive;
  final String? liveLocationUpdatedAt;
  final String? education;
  final String? occupation;
  final String? religion;
  final String? workPreference;
  final List<String> lifestyleTags;
  final String? relationshipGoal;
  final int? prefAgeMin;
  final int? prefAgeMax;
  final String? prefLocation;
  final int? prefMaxDistanceKm;
  final String? prefGender;
  final String? prefRelationshipGoal;
  final bool prefVerifiedOnly;

  /// Let the server widen distance / age when nobody matches exactly.
  final bool prefExpandDistance;
  final bool prefExpandAge;
  final String? phoneCountryCode;
  final String? phoneNumber;
  final String? prefMinHeight;
  final String? prefOccupation;
  final String? prefValues;

  /// Synced with web Settings → Language & region (`app_language`: en | ne).
  final String appLanguage;
  final String appRegion;

  String get displayPhoto {
    if (photoUrl != null && photoUrl!.isNotEmpty) return photoUrl!;
    if (photoUrls.isNotEmpty) return photoUrls.first;
    return '';
  }

  String get displayName => fullName.isNotEmpty ? fullName : (username ?? 'User');

  List<String> get profilePhotos => allPhotos.take(3).toList();

  List<String> get allPhotos {
    final photos = <String>[];
    if (photoUrl != null && photoUrl!.isNotEmpty) photos.add(photoUrl!);
    for (final url in photoUrls) {
      if (url.isNotEmpty && !photos.contains(url)) photos.add(url);
    }
    return photos;
  }

  /// Cloudinary-optimized delivery URL for discover/match cards.
  String get optimizedDisplayPhoto =>
      cloudinaryDeliveryUrl(displayPhoto, preset: CloudinaryPreset.discoverCard);

  /// Cloudinary-optimized avatar URL for lists and headers.
  String get optimizedAvatarPhoto =>
      cloudinaryDeliveryUrl(displayPhoto, preset: CloudinaryPreset.avatar);

  List<String> get optimizedProfilePhotos => profilePhotos
      .map((url) => cloudinaryDeliveryUrl(url, preset: CloudinaryPreset.gallery))
      .toList();

  int? get resolvedUserId => userId ?? id;

  @override
  List<Object?> get props => [userId, fullName, photoUrl, isPremium];
}

class DuoUser extends Equatable {
  const DuoUser({
    required this.id,
    required this.username,
    this.email,
    required this.profile,
  });

  factory DuoUser.fromJson(Map<String, dynamic> json) {
    return DuoUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String?,
      profile: DuoProfile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
    );
  }

  final int id;
  final String username;
  final String? email;
  final DuoProfile profile;

  @override
  List<Object?> get props => [id, username, profile];
}

class AuthTokens extends Equatable {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  @override
  List<Object?> get props => [access, refresh];
}

/// One `profile_checklist` entry: {section, key, label, done}.
class ProfileChecklistItem {
  const ProfileChecklistItem({required this.section, required this.key, required this.label, required this.done});

  factory ProfileChecklistItem.fromJson(Map<String, dynamic> json) => ProfileChecklistItem(
        section: json['section'] as String? ?? '',
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        done: json['done'] == true,
      );

  final String section;
  final String key;
  final String label;
  final bool done;
}
