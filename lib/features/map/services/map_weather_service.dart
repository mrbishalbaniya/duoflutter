import 'package:latlong2/latlong.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../map_weather_models.dart';

class MapWeatherService {
  MapWeatherService(this._client);

  final DioClient _client;

  Future<MapWeatherAmbience> fetchCurrent(LatLng coords) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/weather/current/',
        queryParameters: {
          'lat': coords.latitude,
          'lon': coords.longitude,
        },
      );
      return MapWeatherAmbience.fromJson(response.data ?? const {});
    } catch (_) {
      return const MapWeatherAmbience();
    }
  }

  /// Temperature + condition for display; null when the request fails.
  Future<({double temperature, String main, String description})?> fetchTemperature(LatLng coords) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/weather/current/',
        queryParameters: {'lat': coords.latitude, 'lon': coords.longitude},
      );
      final data = response.data ?? const {};
      final main = data['main'] is Map ? data['main'] as Map : const {};
      final temp = (main['temp'] as num?)?.toDouble() ?? (data['temperature'] as num?)?.toDouble();
      if (temp == null) return null;
      final w = (data['weather'] is List && (data['weather'] as List).isNotEmpty)
          ? (data['weather'] as List).first as Map
          : const {};
      return (
        temperature: temp,
        main: '${w['main'] ?? data['condition'] ?? ''}',
        description: '${w['description'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  String get apiBaseUrl => AppConfig.apiBaseUrl;
}
