import 'package:latlong2/latlong.dart';

import '../core/network/dio_client.dart';
import '../features/map/map_models.dart';

class ActivityFetchBbox {
  const ActivityFetchBbox({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
    required this.zoom,
  });

  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;
  final double zoom;
}

class ActivityRepository {
  ActivityRepository(this._client);

  final DioClient _client;

  Future<List<ActivityZone>> fetchZones({
    required ActivityFetchBbox bbox,
    required ActivityLayerFlags flags,
    LatLng? userCoords,
  }) async {
    final query = <String, dynamic>{
      'lat_min': bbox.latMin,
      'lat_max': bbox.latMax,
      'lon_min': bbox.lonMin,
      'lon_max': bbox.lonMax,
      'zoom': bbox.zoom,
    };

    if (flags.trending) query['trending'] = '1';
    if (flags.events) query['events'] = '1';
    if (flags.friends) query['friends'] = '1';
    if (flags.nearby && userCoords != null) {
      query['nearby'] = '1';
      query['user_lat'] = userCoords.latitude;
      query['user_lng'] = userCoords.longitude;
      query['nearby_km'] = '140';
    }

    final response = await _client.get<Map<String, dynamic>>(
      '/activity/zones/',
      queryParameters: query,
    );
    final zones = response.data?['zones'] as List<dynamic>? ?? [];
    return zones
        .map((e) => ActivityZone.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
