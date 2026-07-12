import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/user_models.dart';
import 'domain/map_layer_catalog.dart';

class MapProfile extends Equatable {
  const MapProfile({
    required this.profile,
    required this.matchId,
    this.coordinates,
    this.distanceMeters,
    this.locationShared = true,
    this.browseOrder,
  });

  final DuoProfile profile;
  final int matchId;
  final LatLng? coordinates;
  final double? distanceMeters;
  final bool locationShared;
  final int? browseOrder;

  bool get canFocusOnMap => locationShared && coordinates != null;

  MapProfile copyWith({
    LatLng? coordinates,
    double? distanceMeters,
    bool? locationShared,
    int? browseOrder,
  }) {
    return MapProfile(
      profile: profile,
      matchId: matchId,
      coordinates: coordinates ?? this.coordinates,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      locationShared: locationShared ?? this.locationShared,
      browseOrder: browseOrder ?? this.browseOrder,
    );
  }

  @override
  List<Object?> get props => [profile.userId, matchId, coordinates, locationShared];
}

class ActivityZone extends Equatable {
  const ActivityZone({
    required this.id,
    required this.lat,
    required this.lng,
    required this.score,
    required this.level,
    required this.activeUsers,
    required this.friendsActive,
    required this.radiusKm,
    required this.name,
    this.badges = const [],
    this.trending = false,
  });

  factory ActivityZone.fromJson(Map<String, dynamic> json) {
    return ActivityZone(
      id: json['id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      level: json['level'] as String? ?? 'low',
      activeUsers: json['active_users'] as int? ?? 0,
      friendsActive: json['friends_active'] as int? ?? 0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 1,
      name: json['name'] as String? ?? '',
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      trending: json['trending'] as bool? ?? false,
    );
  }

  final String id;
  final double lat;
  final double lng;
  final double score;
  final String level;
  final int activeUsers;
  final int friendsActive;
  final double radiusKm;
  final String name;
  final List<String> badges;
  final bool trending;

  LatLng get position => LatLng(lat, lng);

  @override
  List<Object?> get props => [id, lat, lng];
}

class ActivityLayerFlags extends Equatable {
  const ActivityLayerFlags({
    this.live = true,
    this.trending = false,
    this.nearby = true,
    this.events = false,
    this.friends = true,
  });

  final bool live;
  final bool trending;
  final bool nearby;
  final bool events;
  final bool friends;

  ActivityLayerFlags copyWith({
    bool? live,
    bool? trending,
    bool? nearby,
    bool? events,
    bool? friends,
  }) {
    return ActivityLayerFlags(
      live: live ?? this.live,
      trending: trending ?? this.trending,
      nearby: nearby ?? this.nearby,
      events: events ?? this.events,
      friends: friends ?? this.friends,
    );
  }

  @override
  List<Object?> get props => [live, trending, nearby, events, friends];
}

/// Legacy enum kept for migration from older persisted prefs.
enum MapBaseStyle { dark, light, satellite }

class MapLayerState extends Equatable {
  MapLayerState({
    Map<String, bool>? enabled,
    this.favorites = const [],
    this.settingsSearchQuery = '',
    this.settingsOpen = false,
  }) : enabled = enabled ?? buildDefaultEnabledLayers();

  final Map<String, bool> enabled;
  final List<String> favorites;
  final String settingsSearchQuery;
  final bool settingsOpen;

  MapLayerState copyWith({
    Map<String, bool>? enabled,
    List<String>? favorites,
    String? settingsSearchQuery,
    bool? settingsOpen,
  }) {
    return MapLayerState(
      enabled: enabled ?? this.enabled,
      favorites: favorites ?? this.favorites,
      settingsSearchQuery: settingsSearchQuery ?? this.settingsSearchQuery,
      settingsOpen: settingsOpen ?? this.settingsOpen,
    );
  }

  @override
  List<Object?> get props => [enabled, favorites, settingsSearchQuery, settingsOpen];
}
