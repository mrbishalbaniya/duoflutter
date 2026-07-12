import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../repositories/activity_repository.dart';
import '../domain/map_domain.dart';
import '../domain/map_layer_catalog.dart';
import '../map_models.dart';
import '../map_utils.dart';
import '../providers/map_providers.dart';
import 'duo_globe_webview.dart';
import 'map_floating_controls.dart';
import 'map_layer_settings_sheet.dart';
import 'zone_popup_card.dart';

class DuoMapView extends ConsumerStatefulWidget {
  const DuoMapView({
    super.key,
    required this.profiles,
    required this.userCoordinates,
    this.focusProfileId,
    required this.onProfileFocus,
    this.onZoneSelected,
    this.flyToTarget,
    this.locateNonce = 0,
    this.followMe = false,
    this.isFullscreen = false,
    this.onToggleFollowMe,
    this.onToggleFullscreen,
  });

  final List<MapProfile> profiles;
  final LatLng userCoordinates;
  final String? focusProfileId;
  final ValueChanged<String> onProfileFocus;
  final ValueChanged<ActivityZone>? onZoneSelected;
  final LatLng? flyToTarget;
  final int locateNonce;
  final bool followMe;
  final bool isFullscreen;
  final VoidCallback? onToggleFollowMe;
  final VoidCallback? onToggleFullscreen;

  @override
  ConsumerState<DuoMapView> createState() => _DuoMapViewState();
}

class _DuoMapViewState extends ConsumerState<DuoMapView> {
  LatLng? _lastFocused;
  LatLng? _lastFlyTarget;
  LatLng? _lastLivePosition;
  int _lastLocateNonce = 0;
  int _commandToken = 0;
  GlobeFlyToCommand? _flyCommand;
  GlobeCameraCommand? _cameraCommand;
  LatLng? _followCenter;
  double _currentZoom = 11;
  ActivityZone? _selectedZonePopup;
  String? _debugCameraInfo;
  double? _debugFps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapScreenControllerProvider.notifier).setMapReady(true);
    });
  }

  @override
  void didUpdateWidget(covariant DuoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusProfileId != oldWidget.focusProfileId) {
      _flyToFocusedProfile();
    }
    if (widget.flyToTarget != null &&
        widget.flyToTarget != oldWidget.flyToTarget &&
        widget.flyToTarget != _lastFlyTarget) {
      _lastFlyTarget = widget.flyToTarget;
      _issueFlyTo(widget.flyToTarget!, 12);
    }
    if (widget.followMe && widget.userCoordinates != oldWidget.userCoordinates) {
      _maybeFollowUser(widget.userCoordinates);
    }
    if (widget.locateNonce != oldWidget.locateNonce &&
        widget.locateNonce != _lastLocateNonce) {
      _lastLocateNonce = widget.locateNonce;
      _centerOnUser();
    }
  }

  void _centerOnUser() {
    final coords = _effectiveUserCoords;
    _lastFlyTarget = coords;
    _issueFlyTo(coords, 13.5);
    _issueCamera(GlobeCameraAction.recenter);
  }

  void _maybeFollowUser(LatLng coords) {
    if (!widget.followMe) return;
    if (_lastLivePosition == coords) return;
    _lastLivePosition = coords;
    setState(() => _followCenter = coords);
  }

  LatLng get _effectiveUserCoords {
    final live = ref.watch(liveUserPositionProvider).valueOrNull;
    return live ?? widget.userCoordinates;
  }

  void _flyToFocusedProfile() {
    final id = widget.focusProfileId;
    if (id == null) return;
    MapProfile? found;
    for (final profile in widget.profiles) {
      if (mapProfileKey(profile.profile) == id) {
        found = profile;
        break;
      }
    }
    if (found?.coordinates == null) return;
    final target = found!.coordinates!;
    if (_lastFocused == target) return;
    _lastFocused = target;
    _issueFlyTo(target, 13.5);
  }

  void _issueFlyTo(LatLng target, double zoom) {
    setState(() {
      _flyCommand = GlobeFlyToCommand(
        target: target,
        zoom: zoom,
        token: ++_commandToken,
      );
    });
  }

  void _issueCamera(GlobeCameraAction action) {
    setState(() {
      _cameraCommand = GlobeCameraCommand(
        action: action,
        token: ++_commandToken,
      );
    });
  }

  void _onViewportChanged({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    required double zoom,
    required LatLng center,
    double bearing = 0,
    double pitch = 0,
  }) {
    _currentZoom = zoom;
    ref.read(mapViewportProvider.notifier).state = MapViewport(
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
      zoom: zoom,
      center: center,
    );
  }

  ActivityFetchBbox _bboxFromViewport() {
    final viewport = ref.read(mapViewportProvider);
    if (viewport != null) {
      return ActivityFetchBbox(
        latMin: viewport.latMin,
        latMax: viewport.latMax,
        lonMin: viewport.lonMin,
        lonMax: viewport.lonMax,
        zoom: viewport.zoom,
      );
    }
    return ActivityFetchBbox(
      latMin: widget.userCoordinates.latitude - 0.5,
      latMax: widget.userCoordinates.latitude + 0.5,
      lonMin: widget.userCoordinates.longitude - 0.5,
      lonMax: widget.userCoordinates.longitude + 0.5,
      zoom: 10,
    );
  }

  void _onClusterTap(String id, LatLng position) {
    _issueFlyTo(position, _currentZoom + 2);
  }

  void _onZoneTap(String zoneId, List<ActivityZone> zones) {
    for (final zone in zones) {
      if (zone.id == zoneId) {
        setState(() => _selectedZonePopup = zone);
        return;
      }
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MapLayerSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userCoords = _effectiveUserCoords;
    if (widget.followMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFollowUser(userCoords));
    }

    final layerState = ref.watch(mapLayerStateProvider);
    final brightness = Theme.of(context).brightness;
    final activityFlags = activityFlagsFromLayers(layerState.enabled);
    final bbox = _bboxFromViewport();
    final zonesRequest = ActivityZonesRequest(
      bbox: bbox,
      flags: activityFlags,
      userCoords: userCoords,
    );

    final zonesNotifier = ref.read(activityZonesNotifierProvider.notifier);
    zonesNotifier.updateRequest(zonesRequest);
    final zonesAsync = ref.watch(activityZonesNotifierProvider);
    final zones = activityFlags.live
        ? zonesAsync.valueOrNull ?? const <ActivityZone>[]
        : const <ActivityZone>[];
    final weather = ref.watch(mapWeatherAmbienceProvider).valueOrNull;

    final showDebugHud = isLayerEnabled(layerState.enabled, 'dev-fps') ||
        isLayerEnabled(layerState.enabled, 'dev-camera-info');

    return Stack(
      children: [
        DuoGlobeWebView(
          userCoordinates: userCoords,
          markers: widget.profiles,
          zones: zones,
          enabledLayers: layerState.enabled,
          themeBrightness: brightness,
          weather: weather,
          focusProfileId: widget.focusProfileId,
          currentZoom: _currentZoom,
          flyToCommand: _flyCommand,
          cameraCommand: _cameraCommand,
          followCenter: widget.followMe ? _followCenter : null,
          onViewportChanged: _onViewportChanged,
          onMarkerTap: widget.onProfileFocus,
          onClusterTap: _onClusterTap,
          onZoneTap: (id) => _onZoneTap(id, zones),
          onDebug: showDebugHud
              ? ({fps, cameraInfo}) {
                  setState(() {
                    _debugFps = fps;
                    _debugCameraInfo = cameraInfo;
                  });
                }
              : null,
        ),
        Positioned(
          left: 8,
          bottom: 120,
          child: Text(
            '© OpenStreetMap · CARTO · Esri',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
          ),
        ),
        if (_selectedZonePopup != null)
          Positioned(
            left: 16,
            right: 72,
            top: MediaQuery.paddingOf(context).top + 12,
            child: Align(
              alignment: Alignment.topCenter,
              child: ZonePopupCard(
                zone: _selectedZonePopup!,
                onClose: () => setState(() => _selectedZonePopup = null),
                onOpenDetails: () {
                  final zone = _selectedZonePopup!;
                  setState(() => _selectedZonePopup = null);
                  widget.onZoneSelected?.call(zone);
                },
              ),
            ),
          ),
        if (showDebugHud && (_debugFps != null || _debugCameraInfo != null))
          Positioned(
            left: 8,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                [
                  if (isLayerEnabled(layerState.enabled, 'dev-fps') && _debugFps != null)
                    'FPS ${_debugFps!.toStringAsFixed(0)}',
                  if (isLayerEnabled(layerState.enabled, 'dev-camera-info') &&
                      _debugCameraInfo != null)
                    _debugCameraInfo!,
                ].join(' · '),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        Positioned(
          right: 16,
          top: MediaQuery.paddingOf(context).top + 12,
          child: SafeArea(
            bottom: false,
            child: MapFloatingControls(
              onRecenterNorth: () => _issueCamera(GlobeCameraAction.resetNorth),
              onOpenSettings: _openSettingsSheet,
            ),
          ),
        ),
      ],
    );
  }
}
