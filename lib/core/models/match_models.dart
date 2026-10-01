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
    this.valuesScore,
    this.lifestyleScore,
    this.careerScore,
    this.hobbiesScore,
    this.sparkFactors = const [],
    this.sharedInterests = const [],
    this.visionInsight,
    this.communicationInsight,
    this.insightSummary,
    this.pillarNotes = const {},
    this.conversationStarters = const [],
    this.thingsToTalkAbout = const [],
    this.aiGenerated = false,
    this.aiProvider,
    this.modelSamples,
    this.conversationId,
  });

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    final other = json['other_user_profile'] as Map<String, dynamic>?;
    return MatchSession(
      id: (json['id'] ?? json['match_id'] ?? 0) as int,
      otherUserProfile: other != null
          ? DuoProfile.fromJson(other)
          : const DuoProfile(),
      matchedAt: json['matched_at'] as String?,
      compatibilityScore: (json['compatibility_score'] as num?)?.toDouble(),
      valuesScore: (json['values_score'] as num?)?.toDouble(),
      lifestyleScore: (json['lifestyle_score'] as num?)?.toDouble(),
      careerScore: (json['career_score'] as num?)?.toDouble(),
      hobbiesScore: (json['hobbies_score'] as num?)?.toDouble(),
      sparkFactors: _stringList(json['spark_factors']),
      sharedInterests: _stringList(json['shared_interests']),
      visionInsight: json['vision_insight'] as String?,
      communicationInsight: json['communication_insight'] as String?,
      insightSummary: json['insight_summary'] as String?,
      pillarNotes: json['pillar_notes'] is Map
          ? (json['pillar_notes'] as Map).map((k, v) => MapEntry('$k', '${v ?? ''}'))
          : const {},
      conversationStarters: _stringList(json['conversation_starters']),
      thingsToTalkAbout: _stringList(json['things_to_talk_about']),
      aiGenerated: json['ai_generated'] as bool? ?? false,
      aiProvider: json['ai_provider'] as String?,
      modelSamples: (json['model_info'] is Map) ? ((json['model_info'] as Map)['samples'] as num?)?.toInt() : null,
      conversationId: json['conversation_id']?.toString(),
    );
  }

  final int id;
  final DuoProfile otherUserProfile;
  final String? matchedAt;
  final double? compatibilityScore;

  // Compatibility breakdown shown on the Insights screen (web /insights).
  final double? valuesScore;
  final double? lifestyleScore;
  final double? careerScore;
  final double? hobbiesScore;
  final List<String> sparkFactors;
  final List<String> sharedInterests;
  final String? visionInsight;
  final String? communicationInsight;

  // From GET /matching/insights/<id>/ (web MatchInsightsPanel).
  final String? insightSummary;
  final Map<String, String> pillarNotes;
  final List<String> conversationStarters;
  final List<String> thingsToTalkAbout;
  final bool aiGenerated;

  /// 'duo' (own model) | 'claude' | null
  final String? aiProvider;
  final int? modelSamples;
  final String? conversationId;

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
    this.swipeId,
    this.likedAt,
    this.action,
    this.locked = false,
  });

  factory LikedProfileEntry.fromJson(Map<String, dynamic> json) {
    return LikedProfileEntry(
      profile: DuoProfile.fromJson(json['profile'] as Map<String, dynamic>),
      swipeId: json['swipe_id'] as int?,
      likedAt: json['liked_at'] as String?,
      action: _parseSwipeAction(json['action'] as String?),
      locked: json['locked'] as bool? ?? false,
    );
  }

  final DuoProfile profile;
  final int? swipeId;
  final String? likedAt;
  final SwipeAction? action;
  final bool locked;

  @override
  List<Object?> get props => [profile.userId, swipeId, locked];
}

class VisitedProfileEntry extends Equatable {
  const VisitedProfileEntry({
    required this.profile,
    this.visitId,
    this.visitedAt,
    this.locked = false,
  });

  factory VisitedProfileEntry.fromJson(Map<String, dynamic> json) {
    return VisitedProfileEntry(
      profile: DuoProfile.fromJson(json['profile'] as Map<String, dynamic>),
      visitId: json['visit_id'] as int?,
      visitedAt: json['visited_at'] as String?,
      locked: json['locked'] as bool? ?? false,
    );
  }

  final DuoProfile profile;
  final int? visitId;
  final String? visitedAt;
  final bool locked;

  @override
  List<Object?> get props => [profile.userId, visitId, locked];
}

SwipeAction? _parseSwipeAction(String? value) {
  if (value == null) return null;
  return switch (value.toUpperCase()) {
    'SKIP' => SwipeAction.skip,
    'SUPERLIKE' => SwipeAction.superlike,
    _ => SwipeAction.like,
  };
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

List<String> _stringList(Object? value) =>
    value is List ? value.whereType<Object>().map((e) => e.toString()).toList() : const [];
