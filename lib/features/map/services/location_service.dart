import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/map_domain.dart';

class LocationResult {
  const LocationResult({
    required this.coordinates,
    required this.status,
    this.usingFallback = false,
  });

  final LatLng coordinates;
  final LocationPermissionStatus status;
  final bool usingFallback;
}

class LocationService {
  Future<LocationPermissionStatus> checkStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationPermissionStatus.serviceDisabled;

    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      _ => LocationPermissionStatus.denied,
    };
  }

  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
      _ => LocationPermissionStatus.denied,
    };
  }

  Future<LocationResult> getCurrentPosition({
    required LatLng fallback,
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return LocationResult(
          coordinates: fallback,
          status: LocationPermissionStatus.serviceDisabled,
          usingFallback: true,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return LocationResult(
          coordinates: fallback,
          status: LocationPermissionStatus.denied,
          usingFallback: true,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          coordinates: fallback,
          status: LocationPermissionStatus.deniedForever,
          usingFallback: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(
        coordinates: LatLng(position.latitude, position.longitude),
        status: LocationPermissionStatus.granted,
      );
    } catch (_) {
      return LocationResult(
        coordinates: fallback,
        status: LocationPermissionStatus.denied,
        usingFallback: true,
      );
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Stream<LatLng> watchPosition() async* {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 12,
      ),
    ).map((p) => LatLng(p.latitude, p.longitude));
  }
}
