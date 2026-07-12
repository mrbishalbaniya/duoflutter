import '../core/models/match_models.dart';
import '../core/network/dio_client.dart';

class MatchingRepository {
  MatchingRepository(this._client);

  final DioClient _client;

  Future<SwipeResult> swipe({
    required int toUserId,
    required SwipeAction action,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/matching/swipe/',
      data: {'to_user_id': toUserId, 'action': action.apiValue},
    );
    return SwipeResult.fromJson(response.data!);
  }

  Future<List<MatchSession>> getMatches() async {
    final response = await _client.get<List<dynamic>>('/matching/matches/');
    return (response.data ?? [])
        .map((e) => MatchSession.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<Map<String, dynamic>> getMatchInsights(int matchId) async {
    final response = await _client.get<Map<String, dynamic>>('/matching/insights/$matchId/');
    return response.data ?? {};
  }
}
