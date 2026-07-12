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
  });

  final int prefAgeMin;
  final int prefAgeMax;
  final String prefLocation;
  final int prefMaxDistanceKm;
  final String prefGender;
  final String prefRelationshipGoal;
  final bool prefVerifiedOnly;

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
      };
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
