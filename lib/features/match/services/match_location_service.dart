import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/match_domain.dart';

class DetectedLocation {
  const DetectedLocation({
    required this.label,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final String city;
  final double latitude;
  final double longitude;
}

class MatchLocationService {
  MatchLocationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DetectedLocation> detectUserLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied. Enable it in settings.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    final reverseLabel = await _reverseGeocodeLabel(
      position.latitude,
      position.longitude,
    );
    final city = normalizeCityPref(reverseLabel ?? 'Kathmandu, Nepal');
    final label = reverseLabel ?? '$city, Nepal';

    return DetectedLocation(
      label: label,
      city: city,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<String?> _reverseGeocodeLabel(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(
          headers: {'Accept': 'application/json', 'User-Agent': 'DuoMobile/1.0'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'] ??
          address['state'];
      if (city == null) return null;

      final country = address['country'] ?? 'Nepal';
      return '$city, $country';
    } catch (_) {
      return null;
    }
  }
}
