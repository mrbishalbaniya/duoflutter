import '../core/models/match_models.dart';
import '../core/models/user_models.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../features/match/domain/match_domain.dart';

class MatchingRepository {
  MatchingRepository(this._client);

  final DioClient _client;

  /// Swipe on a profile. A Like past the free limit throws
  /// [LikeLimitException] (HTTP 429 `like_limit_reached`), like web.
  Future<(SwipeResult, LikeQuota?)> swipe({
    required int toUserId,
    required SwipeAction action,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/matching/swipe/',
        data: {'to_user_id': toUserId, 'action': action.apiValue},
      );
      final data = response.data!;
      final likes = data['likes'];
      return (
        SwipeResult.fromJson(data),
        likes is Map<String, dynamic> ? LikeQuota.fromJson(likes) : null,
      );
    } on ApiException catch (e) {
      final raw = e.raw;
      if (e.statusCode == 429 && raw is Map && raw['code'] == 'like_limit_reached') {
        final likes = raw['likes'];
        throw LikeLimitException(
          e.message,
          likes is Map<String, dynamic> ? LikeQuota.fromJson(likes) : null,
        );
      }
      rethrow;
    }
  }

  Future<LikeQuota> getLikeQuota() async {
    final response = await _client.get<Map<String, dynamic>>('/matching/likes/quota/');
    return LikeQuota.fromJson(response.data ?? const {});
  }

  /// Undo the last swipe on [toUserId] (premium Rewind). Returns the restored
  /// profile when the server sends one.
  Future<DuoProfile?> rewind({int? toUserId}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/matching/rewind/',
      data: toUserId != null ? {'to_user_id': toUserId} : <String, dynamic>{},
    );
    final profile = response.data?['profile'];
    return profile is Map<String, dynamic> ? DuoProfile.fromJson(profile) : null;
  }

  Future<void> unlike({required int toUserId}) async {
    await _client.post('/matching/unlike/', data: {'to_user_id': toUserId});
  }

  Future<List<MatchSession>> getMatches() async {
    final response = await _client.get<List<dynamic>>('/matching/matches/');
    return (response.data ?? [])
        .map((e) => MatchSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Full insights for one match; [refresh] regenerates them (web "Refresh insights").
  Future<MatchSession> getMatchInsights(int matchId, {bool refresh = false}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/matching/insights/$matchId/',
      queryParameters: refresh ? {'refresh': '1'} : null,
    );
    return MatchSession.fromJson(response.data!);
  }

  Future<List<LikedProfileEntry>> getLikedByYou() async {
    final response = await _client.get<List<dynamic>>('/matching/liked-by-you/');
    return (response.data ?? [])
        .map((e) => LikedProfileEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaywalledList<LikedProfileEntry>> getLikesYou() async {
    final response = await _client.get<Map<String, dynamic>>('/matching/likes-you/');
    return PaywalledList.fromJson(
      response.data!,
      LikedProfileEntry.fromJson,
    );
  }

  Future<PaywalledList<VisitedProfileEntry>> getProfileVisitors() async {
    final response = await _client.get<Map<String, dynamic>>('/matching/profile-visitors/');
    return PaywalledList.fromJson(
      response.data!,
      VisitedProfileEntry.fromJson,
    );
  }

}
