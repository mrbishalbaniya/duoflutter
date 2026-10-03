import 'package:flutter/material.dart';

import '../map_models.dart';

/// Mirrors `DuoFrontend/lib/mapLayers/catalog.ts`.
enum MapLayerCategoryId {
  base,
  globeFx,
  weather,
  geographic,
  duo,
  developer,
}

class MapLayerCategory {
  const MapLayerCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.singleSelect,
  });

  final MapLayerCategoryId id;
  final String label;
  final IconData icon;
  final bool singleSelect;
}

class MapLayerDefinition {
  const MapLayerDefinition({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.icon,
    this.defaultOn = false,
    this.description,
    this.keywords = const [],
  });

  final String id;
  final MapLayerCategoryId categoryId;
  final String label;
  final IconData icon;
  final bool defaultOn;
  final String? description;
  final List<String> keywords;
}

const mapLayerCategories = <MapLayerCategory>[
  MapLayerCategory(
    id: MapLayerCategoryId.base,
    label: 'Map Style',
    icon: Icons.map_outlined,
    singleSelect: true,
  ),
  MapLayerCategory(
    id: MapLayerCategoryId.globeFx,
    label: 'Globe Effects',
    icon: Icons.blur_on,
    singleSelect: false,
  ),
  MapLayerCategory(
    id: MapLayerCategoryId.weather,
    label: 'Weather',
    icon: Icons.wb_cloudy_outlined,
    singleSelect: false,
  ),
  MapLayerCategory(
    id: MapLayerCategoryId.geographic,
    label: 'Geographic',
    icon: Icons.terrain_outlined,
    singleSelect: false,
  ),
  MapLayerCategory(
    id: MapLayerCategoryId.duo,
    label: 'Duo',
    icon: Icons.favorite_outline,
    singleSelect: false,
  ),
  MapLayerCategory(
    id: MapLayerCategoryId.developer,
    label: 'Developer',
    icon: Icons.code_outlined,
    singleSelect: false,
  ),
];

const defaultBaseMapId = 'base-standard-street';

const mapLayerCatalog = <MapLayerDefinition>[
  // "Map" follows the app theme: dark map in dark mode, light map in light mode.
  MapLayerDefinition(
    id: 'base-standard-street',
    categoryId: MapLayerCategoryId.base,
    label: 'Map',
    icon: Icons.map_outlined,
    defaultOn: true,
    keywords: ['street', 'standard', 'dark', 'light', 'night'],
  ),
  MapLayerDefinition(
    id: 'base-satellite',
    categoryId: MapLayerCategoryId.base,
    label: 'Satellite',
    icon: Icons.satellite_alt_outlined,
  ),
  MapLayerDefinition(
    id: 'globe-atmosphere',
    categoryId: MapLayerCategoryId.globeFx,
    label: 'Atmosphere',
    icon: Icons.blur_on,
    defaultOn: true,
  ),
  MapLayerDefinition(
    id: 'globe-earth-glow',
    categoryId: MapLayerCategoryId.globeFx,
    label: 'Earth Glow',
    icon: Icons.flare_outlined,
    defaultOn: true,
  ),
  MapLayerDefinition(
    id: 'globe-starfield',
    categoryId: MapLayerCategoryId.globeFx,
    label: 'Starfield',
    icon: Icons.star_outline,
    defaultOn: true,
  ),
  MapLayerDefinition(
    id: 'weather-live',
    categoryId: MapLayerCategoryId.weather,
    label: 'Live Weather',
    icon: Icons.wb_cloudy_outlined,
    defaultOn: true,
    description: 'Animated weather across the globe',
  ),
  MapLayerDefinition(
    id: 'geo-country-borders',
    categoryId: MapLayerCategoryId.geographic,
    label: 'Country Borders',
    icon: Icons.flag_outlined,
  ),
  MapLayerDefinition(
    id: 'geo-state-borders',
    categoryId: MapLayerCategoryId.geographic,
    label: 'State Borders',
    icon: Icons.map_outlined,
  ),
  MapLayerDefinition(
    id: 'geo-coastlines',
    categoryId: MapLayerCategoryId.geographic,
    label: 'Coastlines',
    icon: Icons.waves_outlined,
  ),
  MapLayerDefinition(
    id: 'duo-profiles',
    categoryId: MapLayerCategoryId.duo,
    label: 'Match Photos',
    icon: Icons.favorite_outline,
    defaultOn: true,
  ),
  MapLayerDefinition(
    id: 'duo-user-location',
    categoryId: MapLayerCategoryId.duo,
    label: 'Your Location',
    icon: Icons.my_location,
    defaultOn: true,
  ),
  MapLayerDefinition(
    id: 'dev-tile-grid',
    categoryId: MapLayerCategoryId.developer,
    label: 'Tile Grid',
    icon: Icons.grid_3x3,
  ),
  MapLayerDefinition(
    id: 'dev-fps',
    categoryId: MapLayerCategoryId.developer,
    label: 'FPS Counter',
    icon: Icons.speed_outlined,
  ),
  MapLayerDefinition(
    id: 'dev-camera-info',
    categoryId: MapLayerCategoryId.developer,
    label: 'Camera Info',
    icon: Icons.videocam_outlined,
  ),
];

Map<String, bool> buildDefaultEnabledLayers() {
  final enabled = <String, bool>{};
  for (final layer in mapLayerCatalog) {
    if (layer.defaultOn) enabled[layer.id] = true;
  }
  enabled[defaultBaseMapId] = true;
  for (final layer in mapLayerCatalog.where((l) => l.categoryId == MapLayerCategoryId.base)) {
    enabled[layer.id] = layer.id == defaultBaseMapId;
  }
  return enabled;
}

Map<String, bool> sanitizeEnabledLayers(Map<String, dynamic>? raw) {
  final next = buildDefaultEnabledLayers();
  if (raw == null) return next;
  for (final layer in mapLayerCatalog) {
    final value = raw[layer.id];
    if (value is bool) next[layer.id] = value;
  }
  final styleIds = mapLayerCatalog
      .where((l) => l.categoryId == MapLayerCategoryId.base)
      .map((l) => l.id)
      .toList();
  final active = styleIds.firstWhere((id) => next[id] == true, orElse: () => defaultBaseMapId);
  for (final id in styleIds) {
    next[id] = id == active;
  }
  return next;
}

List<MapLayerDefinition> layersForCategory(MapLayerCategoryId categoryId) {
  return mapLayerCatalog.where((l) => l.categoryId == categoryId).toList();
}

List<MapLayerDefinition> baseMapStyles() =>
    layersForCategory(MapLayerCategoryId.base);

MapLayerDefinition? layerById(String id) {
  for (final layer in mapLayerCatalog) {
    if (layer.id == id) return layer;
  }
  return null;
}

String activeBaseMapId(Map<String, bool> enabled) {
  for (final layer in baseMapStyles()) {
    if (enabled[layer.id] == true) return layer.id;
  }
  return defaultBaseMapId;
}

bool isLayerEnabled(Map<String, bool> enabled, String id, {bool fallback = true}) {
  return enabled[id] ?? fallback;
}

/// Activity overlays (heatmap, trending, nearby, events, friends) were removed
/// from Map settings, so they are always off.
ActivityLayerFlags activityFlagsFromLayers(Map<String, bool> enabled) {
  return const ActivityLayerFlags(
    live: false,
    trending: false,
    nearby: false,
    events: false,
    friends: false,
  );
}

/// Satellite is the only manual choice; otherwise the map matches the app theme.
String baseMapIdToStyleKey(String baseMapId, {required bool dark}) {
  if (baseMapId == 'base-satellite') return 'satellite';
  return dark ? 'dark' : 'voyager';
}
