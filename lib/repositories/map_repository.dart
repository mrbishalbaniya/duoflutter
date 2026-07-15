import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../core/models/match_models.dart';
import '../core/models/user_models.dart';
import '../core/network/dio_client.dart';
import '../features/map/domain/map_domain.dart';
import '../features/map/map_models.dart';
import 'activity_repository.dart';

class MapRepository {
  MapRepository(this._client, this._activityRepo);

  final DioClient _client;
  final ActivityRepository _activityRepo;

  Future<List<MatchSession>> getMatches() async {
    final response = await _client.get<List<dynamic>>('/matching/matches/');
    return (response.data ?? [])
        .map((e) => MatchSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityZone>> fetchActivityZones({
    required ActivityFetchBbox bbox,
    required ActivityLayerFlags flags,
    LatLng? userCoords,
  }) {
    return _activityRepo.fetchZones(bbox: bbox, flags: flags, userCoords: userCoords);
  }

  Future<DuoProfile> updateLocationPrivacy(LocationPrivacySettings settings) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/profiles/me/',
      data: settings.toApiPayload(),
    );
    return DuoProfile.fromJson(response.data!);
  }

  Future<void> updateLiveLocation(double latitude, double longitude) async {
    await _client.post<Map<String, dynamic>>(
      '/profiles/me/location/',
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }

  Future<LatLng?> geocodePlace(String query) async {
    final results = await searchPlaces(query, limit: 1);
    return results.isEmpty ? null : results.first.coordinates;
  }

  Future<List<GeocodeSuggestion>> searchPlaces(String query, {int limit = 5}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'User-Agent': 'DuoMobile/1.0'},
      ),
    );

    final response = await dio.get<String>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': trimmed,
        'format': 'json',
        'limit': limit,
        'addressdetails': 0,
      },
    );

    final list = jsonDecode(response.data ?? '[]') as List<dynamic>;
    final suggestions = <GeocodeSuggestion>[];
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lon = double.tryParse(map['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;
      final label = map['display_name'] as String? ?? trimmed;
      suggestions.add(GeocodeSuggestion(label: label, coordinates: LatLng(lat, lon)));
    }
    return suggestions;
  }
}
