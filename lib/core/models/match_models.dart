import 'package:equatable/equatable.dart';

import 'user_models.dart';

enum SwipeAction { like, skip, superlike }

extension SwipeActionApi on SwipeAction {
  String get apiValue => switch (this) {
        SwipeAction.like => 'LIKE',
        SwipeAction.skip => 'SKIP',
        SwipeAction.superlike => 'SUPERLIKE',
      };
}

class MatchSession extends Equatable {
  const MatchSession({
    required this.id,
    required this.otherUserProfile,
    this.matchedAt,
    this.compatibilityScore,
  });

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    return MatchSession(
      id: json['id'] as int,
      otherUserProfile: DuoProfile.fromJson(
        json['other_user_profile'] as Map<String, dynamic>,
      ),
      matchedAt: json['matched_at'] as String?,
      compatibilityScore: (json['compatibility_score'] as num?)?.toDouble(),
    );
  }

  final int id;
  final DuoProfile otherUserProfile;
  final String? matchedAt;
  final double? compatibilityScore;

  @override
  List<Object?> get props => [id];
}

class SwipeResult extends Equatable {
  const SwipeResult({
    this.isMatch = false,
    this.match,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      isMatch: json['is_match'] as bool? ?? json['matched'] as bool? ?? false,
      match: json['match'] != null
          ? MatchSession.fromJson(json['match'] as Map<String, dynamic>)
          : null,
    );
  }

  final bool isMatch;
  final MatchSession? match;

  @override
  List<Object?> get props => [isMatch, match];
}

class LikedProfileEntry extends Equatable {
  const LikedProfileEntry({
    required this.profile,
    this.likedAt,
    this.locked = false,
  });

  factory LikedProfileEntry.fromJson(Map<String, dynamic> json) {
    return LikedProfileEntry(
      profile: DuoProfile.fromJson(json['profile'] as Map<String, dynamic>),
      likedAt: json['liked_at'] as String?,
      locked: json['locked'] as bool? ?? false,
    );
  }

  final DuoProfile profile;
  final String? likedAt;
  final bool locked;

  @override
  List<Object?> get props => [profile.userId, locked];
}

class PaywalledList<T> extends Equatable {
  const PaywalledList({
    required this.isPremium,
    required this.premiumRequired,
    required this.count,
    required this.results,
  });

  factory PaywalledList.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    return PaywalledList(
      isPremium: json['is_premium'] as bool? ?? false,
      premiumRequired: json['premium_required'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final bool isPremium;
  final bool premiumRequired;
  final int count;
  final List<T> results;

  @override
  List<Object?> get props => [count, results.length];
}
