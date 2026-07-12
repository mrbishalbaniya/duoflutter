import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../core/models/match_models.dart';
import '../../core/models/user_models.dart';
import 'domain/map_domain.dart';
import 'map_models.dart';

const nepalMapDefaultCenter = LatLng(27.7172, 85.324);

const _nepalCityCoords = <String, LatLng>{
  'kathmandu': LatLng(27.7172, 85.324),
  'lalitpur': LatLng(27.6588, 85.3247),
  'pokhara': LatLng(28.2096, 83.9856),
  'bhaktapur': LatLng(27.671, 85.4298),
  'chitwan': LatLng(27.5291, 84.3542),
  'biratnagar': LatLng(26.4525, 87.2718),
  'dharan': LatLng(26.8147, 87.2848),
  'butwal': LatLng(27.7, 83.4483),
};

int _hashSeed(String value) {
  var hash = 0;
  for (var i = 0; i < value.length; i++) {
    hash = ((hash << 5) - hash) + value.codeUnitAt(i);
    hash &= 0x7fffffff;
  }
  return hash;
}

LatLng findCityCenter(String location) {
  final normalized = location.toLowerCase();
  for (final entry in _nepalCityCoords.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return nepalMapDefaultCenter;
}

LatLng resolveProfileCoordinates({
  required String? location,
  required int? userId,
}) {
  final base = findCityCenter(location?.trim().isNotEmpty == true ? location! : 'Kathmandu, Nepal');
  final seed = _hashSeed('${userId ?? location ?? '0'}');
  final angle = (seed % 360) * (math.pi / 180);
  final radius = 0.008 + (seed % 100) / 10000;
  return LatLng(
    base.latitude + math.cos(angle) * radius,
    base.longitude + math.sin(angle) * radius,
  );
}

double haversineMeters(LatLng from, LatLng to) {
  const r = 6371000.0;
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLat = (to.latitude - from.latitude) * math.pi / 180;
  final dLon = (to.longitude - from.longitude) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String formatDistanceAway(double meters) {
  if (!meters.isFinite || meters < 0) return 'Distance unknown';
  if (meters < 1000) {
    return '${math.max(1, meters.round())} m away from you';
  }
  final km = meters / 1000;
  final label = km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  return '$label away from you';
}

String formatDistanceCompact(double meters) {
  if (!meters.isFinite || meters < 0) return '—';
  if (meters < 1000) return '${math.max(1, meters.round())} m';
  final km = meters / 1000;
  return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}

String mapProfileKey(DuoProfile profile) =>
    '${profile.userId ?? profile.id ?? profile.fullName}';

List<MapProfile> matchesToMapProfiles(
  List<MatchSession> matches,
  LatLng userCoords,
) {
  final profiles = matches.map((match) {
    final profile = match.otherUserProfile;
    final locationShared = profile.locationShared;
    final coordinates = locationShared
        ? resolveProfileCoordinates(
            location: profile.location,
            userId: profile.userId ?? profile.id,
          )
        : null;
    final distanceMeters = coordinates != null
        ? haversineMeters(userCoords, coordinates)
        : null;

    return MapProfile(
      profile: profile,
      matchId: match.id,
      coordinates: coordinates,
      distanceMeters: distanceMeters,
      locationShared: locationShared,
    );
  }).toList();

  profiles.sort((a, b) {
    if (a.locationShared != b.locationShared) {
      return a.locationShared ? -1 : 1;
    }
    return (a.distanceMeters ?? double.infinity)
        .compareTo(b.distanceMeters ?? double.infinity);
  });

  return [
    for (var i = 0; i < profiles.length; i++)
      profiles[i].copyWith(browseOrder: i),
  ];
}

List<MapProfile> filterMapProfiles({
  required List<MapProfile> profiles,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return profiles;
  return profiles.where((p) {
    final name = p.profile.displayName.toLowerCase();
    final location = (p.profile.location ?? '').toLowerCase();
    return name.contains(q) || location.contains(q);
  }).toList();
}

/// Groups nearby profile markers when zoomed out (web has no clustering; mobile improves UX).
List<MapClusterMarker> clusterMapProfiles({
  required List<MapProfile> profiles,
  required double zoom,
}) {
  if (zoom >= 11) {
    return profiles
        .where((p) => p.coordinates != null)
        .map(
          (p) => MapClusterMarker(
            id: mapProfileKey(p.profile),
            position: p.coordinates!,
            count: 1,
            profiles: [p],
          ),
        )
        .toList();
  }

  final cellSize = zoom < 8 ? 0.35 : 0.12;
  final buckets = <String, List<MapProfile>>{};

  for (final profile in profiles) {
    final coords = profile.coordinates;
    if (coords == null) continue;
    final key =
        '${(coords.latitude / cellSize).floor()}_${(coords.longitude / cellSize).floor()}';
    buckets.putIfAbsent(key, () => []).add(profile);
  }

  return buckets.entries.map((entry) {
    final items = entry.value;
    final avgLat = items.map((e) => e.coordinates!.latitude).reduce((a, b) => a + b) /
        items.length;
    final avgLng = items.map((e) => e.coordinates!.longitude).reduce((a, b) => a + b) /
        items.length;
    return MapClusterMarker(
      id: entry.key,
      position: LatLng(avgLat, avgLng),
      count: items.length,
      profiles: items,
    );
  }).toList();
}

ActivityZoneColor activityZoneColor(String level) {
  return switch (level) {
    'viral' => const ActivityZoneColor(0xFFFF4D6D, 0.45),
    'trending' => const ActivityZoneColor(0xFFE84A7A, 0.38),
    'high' => const ActivityZoneColor(0xFF8B5CF6, 0.32),
    'moderate' => const ActivityZoneColor(0xFFD4A574, 0.28),
    _ => const ActivityZoneColor(0xFF60BB46, 0.22),
  };
}

class ActivityZoneColor {
  const ActivityZoneColor(this.argb, this.opacity);
  final int argb;
  final double opacity;
}
