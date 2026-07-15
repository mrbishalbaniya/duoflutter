import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/lifecycle/app_lifecycle_service.dart';

import '../../../core/models/match_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/local_storage.dart';
import '../../../repositories/activity_repository.dart';
import '../../../repositories/map_repository.dart';
import '../../auth/auth_controller.dart';
import '../domain/map_domain.dart';
import '../domain/map_layer_catalog.dart';
import '../map_models.dart';
import '../map_utils.dart';
import '../services/activity_websocket_service.dart';
import '../map_weather_models.dart';
import '../services/location_service.dart';
import '../services/map_weather_service.dart';
import '../../chat/providers/chat_providers.dart';
import 'map_screen_controller.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(
    ref.watch(dioClientProvider),
    ActivityRepository(ref.watch(dioClientProvider)),
  );
});

final mapScreenControllerProvider =
    StateNotifierProvider.autoDispose<MapScreenController, MapScreenState>((ref) {
  return MapScreenController();
});

final userLocationProvider =
    FutureProvider.autoDispose<LocationResult>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  final fallback = resolveProfileCoordinates(
    location: user?.profile.location,
    userId: user?.id,
  );
  return ref.read(locationServiceProvider).getCurrentPosition(fallback: fallback);
});

final userCoordinatesProvider = FutureProvider.autoDispose<LatLng>((ref) async {
  final result = await ref.watch(userLocationProvider.future);
  return result.coordinates;
});

final mapMatchesProvider =
    FutureProvider.autoDispose<List<MapProfile>>((ref) async {
  final userCoords = await ref.watch(userCoordinatesProvider.future);
  final matches = await ref.read(mapRepositoryProvider).getMatches();
  return matchesToMapProfiles(matches, userCoords);
});

final rawMatchesProvider = FutureProvider.autoDispose<List<MatchSession>>((ref) {
  return ref.read(mapRepositoryProvider).getMatches();
});

final matchConversationIdsProvider =
    FutureProvider.autoDispose<Map<int, String>>((ref) async {
  final cache = ref.read(chatCacheServiceProvider);
  final filterKey = cache.filterKey(archived: false, unreadOnly: false);
  final cached = cache.readConversationList(filterKey);
  if (cached != null && cached.conversations.isNotEmpty) {
    return {
      for (final c in cached.conversations)
        if (c.matchId != null) c.matchId!: c.publicId,
    };
  }
  final conversations = await ref.read(chatRepositoryProvider).getConversations();
  cache.writeConversationList(filterKey, conversations);
  return {
    for (final c in conversations)
      if (c.matchId != null) c.matchId!: c.publicId,
  };
});

final mapLayerStateProvider =
    StateNotifierProvider<MapLayerNotifier, MapLayerState>((ref) {
  return MapLayerNotifier(ref.watch(localStorageProvider));
});

class MapLayerNotifier extends StateNotifier<MapLayerState> {
  MapLayerNotifier(this._storage) : super(_load(_storage));

  static const _prefsKey = 'duo_map_layers';

  final LocalStorage _storage;

  static MapLayerState _load(LocalStorage storage) {
    final raw = storage.settings.get(_prefsKey);
    if (raw is! Map) {
      return MapLayerState(enabled: buildDefaultEnabledLayers());
    }

    final enabledRaw = raw['enabled'];
    if (enabledRaw is Map) {
      return MapLayerState(
        enabled: sanitizeEnabledLayers(enabledRaw.cast<String, dynamic>()),
        favorites: (raw['favorites'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
    }

    // Migrate legacy shape.
    final enabled = buildDefaultEnabledLayers();
    final baseStyle = raw['baseStyle'] as String?;
    if (baseStyle != null) {
      for (final layer in baseMapStyles()) {
        enabled[layer.id] = false;
      }
      enabled[baseStyle == 'satellite'
          ? 'base-satellite'
          : baseStyle == 'light'
              ? 'base-standard-street'
              : 'base-night'] = true;
    }
    final activity = raw['activity'];
    if (activity is Map) {
      enabled['duo-activity-heatmap'] = activity['live'] as bool? ?? true;
      enabled['duo-activity-trending'] = activity['trending'] as bool? ?? false;
      enabled['duo-activity-nearby'] = activity['nearby'] as bool? ?? true;
      enabled['duo-activity-events'] = activity['events'] as bool? ?? false;
      enabled['duo-activity-friends'] = activity['friends'] as bool? ?? true;
    }
    return MapLayerState(enabled: sanitizeEnabledLayers(enabled));
  }

  void _persist() {
    _storage.settings.put(_prefsKey, {
      'enabled': state.enabled,
      'favorites': state.favorites,
    });
  }

  void toggleLayer(String layerId) {
    final layer = layerById(layerId);
    if (layer == null) return;
    final next = Map<String, bool>.from(state.enabled);
    if (layer.categoryId == MapLayerCategoryId.base) {
      for (final style in baseMapStyles()) {
        next[style.id] = style.id == layerId;
      }
    } else {
      next[layerId] = !(next[layerId] ?? false);
    }
    state = state.copyWith(enabled: sanitizeEnabledLayers(next));
    _persist();
  }

  void setBaseMap(String layerId) => toggleLayer(layerId);

  void toggleFavorite(String layerId) {
    final favorites = List<String>.from(state.favorites);
    if (favorites.contains(layerId)) {
      favorites.remove(layerId);
    } else {
      favorites.add(layerId);
    }
    state = state.copyWith(favorites: favorites);
    _persist();
  }

  void setSettingsSearchQuery(String query) {
    state = state.copyWith(settingsSearchQuery: query);
  }

  void setSettingsOpen(bool open) {
    state = state.copyWith(settingsOpen: open);
  }

  void toggleSettingsOpen() {
    state = state.copyWith(settingsOpen: !state.settingsOpen);
  }
}

final mapWeatherServiceProvider = Provider<MapWeatherService>((ref) {
  return MapWeatherService(ref.watch(dioClientProvider));
});

final mapWeatherAmbienceProvider =
    FutureProvider.autoDispose<MapWeatherAmbience>((ref) async {
  final coords = await ref.watch(userCoordinatesProvider.future);
  final layers = ref.watch(mapLayerStateProvider);
  if (!isLayerEnabled(layers.enabled, 'weather-live')) {
    return const MapWeatherAmbience();
  }
  return ref.read(mapWeatherServiceProvider).fetchCurrent(coords);
});

final mapViewportProvider =
    StateProvider.autoDispose<MapViewport?>((ref) => null);

final activityZonesNotifierProvider = StateNotifierProvider.autoDispose<
    ActivityZonesNotifier, AsyncValue<List<ActivityZone>>>((ref) {
  final notifier = ActivityZonesNotifier(repository: ref.read(mapRepositoryProvider));
  ref.listen(appLifecycleProvider, (_, next) {
    notifier.setAppInBackground(next != AppLifecycleState.resumed);
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

class ActivityZonesNotifier extends StateNotifier<AsyncValue<List<ActivityZone>>> {
  ActivityZonesNotifier({required this.repository}) : super(const AsyncValue.loading()) {
    _ws = ActivityWebSocketService();
    _init();
  }

  final MapRepository repository;
  ActivityZonesRequest? _request;

  late final ActivityWebSocketService _ws;
  StreamSubscription? _wsSub;
  Timer? _restTimer;
  Timer? _debounceTimer;
  bool _wsHealthy = false;

  Future<void> _init() async {
    _wsSub = _ws.events.listen((event) {
      if (event.type == 'zones' || event.type == 'activity_zones') {
        _wsHealthy = true;
        state = AsyncValue.data(parseActivityZones(event.data));
      } else if (event.type == 'connected' || event.type == 'pong') {
        _wsHealthy = true;
      }
    });

    await _ws.connect();
    _restTimer = Timer.periodic(const Duration(seconds: 120), (_) {
      if (!_wsHealthy) _fetchRest();
    });
  }

  void updateRequest(ActivityZonesRequest next) {
    _request = next;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_request == null || !_request!.flags.live) {
        state = const AsyncValue.data([]);
        return;
      }
      _pushViewport();
      _fetchRest();
    });
  }

  void _pushViewport() {
    final request = _request;
    if (request == null) return;
    _wsHealthy = false;
    _ws.sendViewport(
      latMin: request.bbox.latMin,
      latMax: request.bbox.latMax,
      lonMin: request.bbox.lonMin,
      lonMax: request.bbox.lonMax,
      zoom: request.bbox.zoom,
      flags: request.flags,
      userCoords: request.userCoords,
    );
  }

  Future<void> _fetchRest() async {
    final request = _request;
    if (request == null || !request.flags.live) return;
    try {
      final zones = await repository.fetchActivityZones(
        bbox: request.bbox,
        flags: request.flags,
        userCoords: request.userCoords,
      );
      state = AsyncValue.data(zones);
    } catch (e, st) {
      if (!state.hasValue) state = AsyncValue.error(e, st);
    }
  }

  void setAppInBackground(bool inBackground) {
    _ws.setAppInBackground(inBackground);
    if (inBackground) {
      _restTimer?.cancel();
      _restTimer = null;
      return;
    }
    _restTimer ??= Timer.periodic(const Duration(seconds: 120), (_) {
      if (!_wsHealthy) _fetchRest();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _restTimer?.cancel();
    _wsSub?.cancel();
    _ws.dispose();
    super.dispose();
  }
}

class ActivityZonesRequest {
  const ActivityZonesRequest({
    required this.bbox,
    required this.flags,
    this.userCoords,
  });

  final ActivityFetchBbox bbox;
  final ActivityLayerFlags flags;
  final LatLng? userCoords;

  @override
  bool operator ==(Object other) =>
      other is ActivityZonesRequest &&
      other.bbox.latMin == bbox.latMin &&
      other.bbox.latMax == bbox.latMax &&
      other.bbox.lonMin == bbox.lonMin &&
      other.bbox.lonMax == bbox.lonMax &&
      other.bbox.zoom == bbox.zoom &&
      other.flags == flags &&
      other.userCoords == userCoords;

  @override
  int get hashCode => Object.hash(
        bbox.latMin,
        bbox.latMax,
        bbox.lonMin,
        bbox.lonMax,
        bbox.zoom,
        flags,
        userCoords,
      );
}

final mapRecentSearchesProvider =
    StateNotifierProvider<MapRecentSearchesNotifier, List<String>>((ref) {
  return MapRecentSearchesNotifier(ref.watch(localStorageProvider));
});

class MapRecentSearchesNotifier extends StateNotifier<List<String>> {
  MapRecentSearchesNotifier(this._storage) : super(_load(_storage));

  static const _key = 'duo_map_recent_searches';
  final LocalStorage _storage;

  static List<String> _load(LocalStorage storage) {
    final raw = storage.settings.get(_key);
    if (raw is List) return raw.map((e) => e.toString()).take(8).toList();
    return const [];
  }

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final next = [trimmed, ...state.where((s) => s != trimmed)].take(8).toList();
    state = next;
    _storage.settings.put(_key, next);
  }

  void clear() {
    state = const [];
    _storage.settings.delete(_key);
  }
}

final liveUserPositionProvider = StreamProvider.autoDispose<LatLng>((ref) {
  return ref.read(locationServiceProvider).watchPosition();
});

/// Uploads device GPS to backend for real-time friend map sharing.
final liveLocationSyncProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.profile.locationGhostMode) return;

  final repo = ref.read(mapRepositoryProvider);
  LatLng? lastUploaded;
  DateTime? lastUploadAt;

  ref.listen<AsyncValue<LatLng>>(liveUserPositionProvider, (_, next) {
    final coords = next.valueOrNull;
    if (coords == null) return;
    final now = DateTime.now();
    final moved = lastUploaded == null ||
        (coords.latitude - lastUploaded!.latitude).abs() > 0.00015 ||
        (coords.longitude - lastUploaded!.longitude).abs() > 0.00015;
    final due = lastUploadAt == null || now.difference(lastUploadAt!) > const Duration(seconds: 30);
    if (!moved && !due) return;
    lastUploaded = coords;
    lastUploadAt = now;
    repo.updateLiveLocation(coords.latitude, coords.longitude).catchError((_) {});
  });
});

final mapMatchRefreshProvider = Provider.autoDispose<void>((ref) {
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidate(mapMatchesProvider);
  });
  ref.onDispose(timer.cancel);
});

final mapGeocodeSuggestionsProvider =
    FutureProvider.autoDispose.family<List<GeocodeSuggestion>, String>((ref, query) async {
  if (query.trim().length < 2) return const [];
  return ref.read(mapRepositoryProvider).searchPlaces(query);
});

final mapGeocodeProvider =
    FutureProvider.autoDispose.family<LatLng?, String>((ref, query) async {
  if (query.trim().length < 2) return null;
  return ref.read(mapRepositoryProvider).geocodePlace(query);
});
