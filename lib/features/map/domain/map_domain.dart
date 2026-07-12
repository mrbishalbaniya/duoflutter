import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../map_models.dart';

class GeocodeSuggestion extends Equatable {
  const GeocodeSuggestion({required this.label, required this.coordinates});

  final String label;
  final LatLng coordinates;

  @override
  List<Object?> get props => [label, coordinates];
}

/// Screen-level state for the Friends Map feature.
class MapScreenState extends Equatable {
  const MapScreenState({
    this.focusProfileId,
    this.selectedZone,
    this.searchQuery = '',
    this.friendsSearchQuery = '',
    this.isMapReady = false,
    this.followMe = false,
    this.isFullscreen = false,
    this.flyToTarget,
  });

  final String? focusProfileId;
  final ActivityZone? selectedZone;
  final String searchQuery;
  final String friendsSearchQuery;
  final bool isMapReady;
  final bool followMe;
  final bool isFullscreen;
  final LatLng? flyToTarget;

  MapScreenState copyWith({
    String? focusProfileId,
    bool clearFocus = false,
    ActivityZone? selectedZone,
    bool clearSelectedZone = false,
    String? searchQuery,
    String? friendsSearchQuery,
    bool? isMapReady,
    bool? followMe,
    bool? isFullscreen,
    LatLng? flyToTarget,
    bool clearFlyTo = false,
  }) {
    return MapScreenState(
      focusProfileId: clearFocus ? null : (focusProfileId ?? this.focusProfileId),
      selectedZone: clearSelectedZone ? null : (selectedZone ?? this.selectedZone),
      searchQuery: searchQuery ?? this.searchQuery,
      friendsSearchQuery: friendsSearchQuery ?? this.friendsSearchQuery,
      isMapReady: isMapReady ?? this.isMapReady,
      followMe: followMe ?? this.followMe,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      flyToTarget: clearFlyTo ? null : (flyToTarget ?? this.flyToTarget),
    );
  }

  @override
  List<Object?> get props => [
        focusProfileId,
        selectedZone,
        searchQuery,
        friendsSearchQuery,
        isMapReady,
        followMe,
        isFullscreen,
        flyToTarget,
      ];
}

class MapViewport extends Equatable {
  const MapViewport({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
    required this.zoom,
    required this.center,
  });

  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;
  final double zoom;
  final LatLng center;

  @override
  List<Object?> get props => [latMin, latMax, lonMin, lonMax, zoom, center];
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  usingFallback,
}

enum LocationVisibilityMode { friends, friendsExcept, onlyThese }

extension LocationVisibilityModeApi on LocationVisibilityMode {
  String get apiValue => switch (this) {
        LocationVisibilityMode.friends => 'friends',
        LocationVisibilityMode.friendsExcept => 'friends_except',
        LocationVisibilityMode.onlyThese => 'only_these',
      };

  static LocationVisibilityMode fromApi(String? value) => switch (value) {
        'friends_except' => LocationVisibilityMode.friendsExcept,
        'only_these' => LocationVisibilityMode.onlyThese,
        _ => LocationVisibilityMode.friends,
      };
}

class LocationPrivacySettings extends Equatable {
  const LocationPrivacySettings({
    this.ghostMode = false,
    this.visibility = LocationVisibilityMode.friends,
    this.visibilityFriendIds = const [],
  });

  final bool ghostMode;
  final LocationVisibilityMode visibility;
  final List<int> visibilityFriendIds;

  LocationPrivacySettings copyWith({
    bool? ghostMode,
    LocationVisibilityMode? visibility,
    List<int>? visibilityFriendIds,
  }) {
    return LocationPrivacySettings(
      ghostMode: ghostMode ?? this.ghostMode,
      visibility: visibility ?? this.visibility,
      visibilityFriendIds: visibilityFriendIds ?? this.visibilityFriendIds,
    );
  }

  Map<String, dynamic> toApiPayload() => {
        'location_ghost_mode': ghostMode,
        'location_visibility': visibility.apiValue,
        'location_visibility_friends': visibilityFriendIds,
      };

  @override
  List<Object?> get props => [ghostMode, visibility, visibilityFriendIds];
}

class MapClusterMarker extends Equatable {
  const MapClusterMarker({
    required this.id,
    required this.position,
    required this.count,
    required this.profiles,
  });

  final String id;
  final LatLng position;
  final int count;
  final List<MapProfile> profiles;

  bool get isCluster => count > 1;

  @override
  List<Object?> get props => [id, position, count];
}
