import '../../../core/models/user_models.dart';

enum SwipeDirection { left, right }

class DiscoveryFilters {
  const DiscoveryFilters({
    required this.prefAgeMin,
    required this.prefAgeMax,
    required this.prefLocation,
    required this.prefMaxDistanceKm,
    required this.prefGender,
    required this.prefRelationshipGoal,
    required this.prefVerifiedOnly,
    this.prefExpandDistance = true,
    this.prefExpandAge = true,
  });

  final int prefAgeMin;
  final int prefAgeMax;
  final String prefLocation;
  final int prefMaxDistanceKm;
  final String prefGender;
  final String prefRelationshipGoal;
  final bool prefVerifiedOnly;
  final bool prefExpandDistance;
  final bool prefExpandAge;

  static const defaults = DiscoveryFilters(
    prefAgeMin: 22,
    prefAgeMax: 35,
    prefLocation: '',
    prefMaxDistanceKm: 50,
    prefGender: 'everyone',
    prefRelationshipGoal: 'everyone',
    prefVerifiedOnly: false,
  );

  factory DiscoveryFilters.fromProfile(DuoProfile profile) {
    return DiscoveryFilters(
      prefAgeMin: profile.prefAgeMin ?? defaults.prefAgeMin,
      prefAgeMax: profile.prefAgeMax ?? defaults.prefAgeMax,
      prefLocation: normalizeCityPref(
        profile.prefLocation ?? profile.location ?? '',
      ),
      prefMaxDistanceKm: profile.prefMaxDistanceKm ?? defaults.prefMaxDistanceKm,
      prefGender: profile.prefGender ?? defaults.prefGender,
      prefRelationshipGoal:
          profile.prefRelationshipGoal ?? defaults.prefRelationshipGoal,
      prefVerifiedOnly: profile.prefVerifiedOnly,
      prefExpandDistance: profile.prefExpandDistance,
      prefExpandAge: profile.prefExpandAge,
    );
  }

  Map<String, dynamic> toApiPayload() => {
        'pref_age_min': prefAgeMin,
        'pref_age_max': prefAgeMax,
        'pref_location': prefLocation.trim(),
        'pref_max_distance_km': prefMaxDistanceKm,
        'pref_gender': prefGender,
        'pref_relationship_goal': prefRelationshipGoal,
        'pref_verified_only': prefVerifiedOnly,
        'pref_expand_distance': prefExpandDistance,
        'pref_expand_age': prefExpandAge,
      };

  /// Same rule as web `countActiveFilters`: non-default filters shown as a badge.
  int get activeCount {
    const d = defaults;
    var count = 0;
    if (prefGender != 'everyone') count++;
    if (prefRelationshipGoal != 'everyone') count++;
    if (prefVerifiedOnly) count++;
    if (prefAgeMin != d.prefAgeMin || prefAgeMax != d.prefAgeMax) count++;
    if (prefMaxDistanceKm != d.prefMaxDistanceKm) count++;
    return count;
  }
}

String normalizeCityPref(String location) {
  final value = location.trim();
  if (value.isEmpty) return '';

  final first = value.split(',').first.trim();
  return first
      .replaceAll(RegExp(r'\s+metropolitan city$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+metropolitan$', caseSensitive: false), '')
      .trim();
}

String formatLocationLabel(String location) {
  final normalized = normalizeCityPref(location);
  if (normalized.length <= 28) return normalized;
  return '${normalized.substring(0, 26).trimRight()}…';
}

bool isDefaultLocation(String? location) {
  final value = location?.trim().toLowerCase() ?? '';
  return value.isEmpty || value == 'kathmandu, nepal' || value == 'kathmandu';
}

String matchProfileHeroTag(DuoProfile profile) =>
    'match-profile-${profile.resolvedUserId ?? profile.displayName}';

String emptyDeckMessage(DuoProfile? prefs) {
  if (prefs == null) {
    return 'No one matches your current filters, or you have swiped through everyone nearby. Try adjusting filters or check back later.';
  }
  if (prefs.prefVerifiedOnly) {
    return 'No verified profiles match your filters. Try turning off "Verified only".';
  }
  final min = prefs.prefAgeMin;
  final max = prefs.prefAgeMax;
  if (min != null && max != null && max - min <= 5) {
    return 'Your age range may be too narrow. Widen it in discovery filters.';
  }
  return 'No one matches your current filters, or you have swiped through everyone nearby. Try adjusting filters or check back later.';
}

/// Free-tier Like allowance from `/matching/likes/quota/`.
class LikeQuota {
  const LikeQuota({
    required this.unlimited,
    this.limit,
    this.used = 0,
    this.likesRemaining,
    this.resetAt,
    this.windowHours = 24,
  });

  factory LikeQuota.fromJson(Map<String, dynamic> json) {
    return LikeQuota(
      unlimited: json['unlimited'] as bool? ?? false,
      limit: (json['limit'] as num?)?.toInt(),
      used: (json['used'] as num?)?.toInt() ?? 0,
      likesRemaining: (json['likes_remaining'] as num?)?.toInt(),
      resetAt: DateTime.tryParse(json['reset_at'] as String? ?? ''),
      windowHours: (json['window_hours'] as num?)?.toInt() ?? 24,
    );
  }

  final bool unlimited;
  final int? limit;
  final int used;
  final int? likesRemaining;
  final DateTime? resetAt;
  final int windowHours;

  /// Out of free Likes right now (the backend is the source of truth).
  bool get exhausted {
    if (unlimited) return false;
    if ((likesRemaining ?? 0) > 0) return false;
    return resetAt == null || resetAt!.isAfter(DateTime.now());
  }
}

/// Thrown when a free user is out of Likes (HTTP 429 `like_limit_reached`).
class LikeLimitException implements Exception {
  const LikeLimitException(this.message, this.quota);

  final String message;
  final LikeQuota? quota;

  @override
  String toString() => message;
}
