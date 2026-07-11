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

  String get displayPhoto {
    if (photoUrl != null && photoUrl!.isNotEmpty) return photoUrl!;
    if (photoUrls.isNotEmpty) return photoUrls.first;
    return '';
  }

  String get displayName => fullName.isNotEmpty ? fullName : (username ?? 'User');

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
