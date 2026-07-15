import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/match_domain.dart';

class DetectedLocation {
  const DetectedLocation({
    required this.label,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.country = 'Nepal',
    this.province = '',
    this.district = '',
    this.municipality = '',
    this.accuracyMeters,
  });

  final String label;
  final String city;
  final double latitude;
  final double longitude;
  final String country;
  final String province;
  final String district;
  final String municipality;
  final double? accuracyMeters;
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

    final details = await _reverseGeocodeDetails(position.latitude, position.longitude);
    final municipality = details?['municipality'] ?? 'Kathmandu';
    final district = details?['district'] ?? municipality;
    final province = details?['province'] ?? 'Bagmati';
    final country = details?['country'] ?? 'Nepal';
    final city = normalizeCityPref(municipality);
    final label = details?['label'] ?? '$city, $country';

    return DetectedLocation(
      label: label,
      city: city,
      latitude: position.latitude,
      longitude: position.longitude,
      country: country,
      province: province,
      district: district,
      municipality: municipality,
      accuracyMeters: position.accuracy,
    );
  }

  Future<Map<String, String>?> _reverseGeocodeDetails(double lat, double lng) async {
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

      String pick(List<String> keys) {
        for (final key in keys) {
          final value = address[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
        return '';
      }

      final municipality = pick(const [
        'city',
        'town',
        'municipality',
        'village',
        'suburb',
        'county',
      ]);
      final district = pick(const ['county', 'district', 'state_district', 'city_district']);
      final province = pick(const ['state', 'province', 'region']);
      final country = pick(const ['country']).isEmpty ? 'Nepal' : pick(const ['country']);
      final city = municipality.isNotEmpty ? municipality : (district.isNotEmpty ? district : 'Kathmandu');

      return {
        'municipality': city,
        'district': district.isNotEmpty ? district : city,
        'province': province.isNotEmpty ? province : 'Bagmati',
        'country': country,
        'label': '$city, $country',
      };
    } catch (_) {
      return null;
    }
  }
}
