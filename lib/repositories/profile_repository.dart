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

  /// Offline NLG copy for About step (`POST /api/profile/generate/`).
  Future<GeneratedProfileCopy> generateProfileCopy({
    String style = 'friendly',
    String language = 'en',
    bool force = true,
    bool apply = false,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/profile/generate/',
      data: {
        'style': style,
        'language': language,
        'force': force,
        'apply': apply,
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    return GeneratedProfileCopy.fromJson(data);
  }
}

class GeneratedProfileCopy {
  const GeneratedProfileCopy({
    required this.bio,
    required this.lookingFor,
    required this.futureGoals,
    this.traits = const [],
    this.cached = false,
  });

  factory GeneratedProfileCopy.fromJson(Map<String, dynamic> json) {
    return GeneratedProfileCopy(
      bio: '${json['bio'] ?? ''}',
      lookingFor: '${json['looking_for'] ?? ''}',
      futureGoals: '${json['future_goals'] ?? ''}',
      traits: (json['traits'] as List?)?.map((e) => '$e').toList() ?? const [],
      cached: json['cached'] == true,
    );
  }

  final String bio;
  final String lookingFor;
  final String futureGoals;
  final List<String> traits;
  final bool cached;
}
