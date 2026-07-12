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

  String get apiBaseUrl => AppConfig.apiBaseUrl;
}
