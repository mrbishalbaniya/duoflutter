import '../core/models/user_models.dart';
import '../core/network/dio_client.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final DioClient _client;

  Future<DuoProfile> getMyProfile() async {
    final response = await _client.get<Map<String, dynamic>>('/profiles/me/');
    return DuoProfile.fromJson(response.data!);
  }

  Future<DuoProfile> updateProfile(Map<String, dynamic> payload) async {
    final response = await _client.put<Map<String, dynamic>>('/profiles/me/', data: payload);
    return DuoProfile.fromJson(response.data!);
  }

  Future<List<DuoProfile>> discoverProfiles() async {
    final response = await _client.get<List<dynamic>>('/profiles/discover/');
    return (response.data ?? [])
        .map((e) => DuoProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DuoProfile> getProfile(int profileId) async {
    final response = await _client.get<Map<String, dynamic>>('/profiles/$profileId/');
    return DuoProfile.fromJson(response.data!);
  }

  Future<void> recordVisit(int profileId) async {
    await _client.post('/profiles/$profileId/visit/');
  }
}
