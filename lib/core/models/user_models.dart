import 'package:equatable/equatable.dart';

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
    this.previewDistanceKm,
    this.locked = false,
    this.locationShared = true,
    this.locationGhostMode = false,
    this.locationVisibility = 'friends',
    this.locationVisibilityFriends = const [],
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
    this.phoneCountryCode,
    this.phoneNumber,
    this.prefMinHeight,
    this.prefOccupation,
    this.prefValues,
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
      previewDistanceKm: (json['preview_distance_km'] as num?)?.toDouble(),
      locked: json['locked'] as bool? ?? false,
      locationShared: json['location_shared'] as bool? ?? true,
      locationGhostMode: json['location_ghost_mode'] as bool? ?? false,
      locationVisibility: json['location_visibility'] as String? ?? 'friends',
      locationVisibilityFriends: (json['location_visibility_friends'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
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
      phoneCountryCode: json['phone_country_code'] as String?,
      phoneNumber: json['phone_number'] as String?,
      prefMinHeight: json['pref_min_height'] as String?,
      prefOccupation: json['pref_occupation'] as String?,
      prefValues: json['pref_values'] as String?,
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
  final double? previewDistanceKm;
  final bool locked;
  final bool locationShared;
  final bool locationGhostMode;
  final String locationVisibility;
  final List<int> locationVisibilityFriends;
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
  final String? phoneCountryCode;
  final String? phoneNumber;
  final String? prefMinHeight;
  final String? prefOccupation;
  final String? prefValues;

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
