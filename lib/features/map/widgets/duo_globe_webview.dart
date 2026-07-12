import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/map_layer_catalog.dart';
import '../map_models.dart';
import '../map_utils.dart';
import '../map_weather_models.dart';

typedef GlobeViewportCallback = void Function({
  required double latMin,
  required double latMax,
  required double lonMin,
  required double lonMax,
  required double zoom,
  required LatLng center,
  double bearing,
  double pitch,
});

typedef GlobeMarkerTapCallback = ValueChanged<String>;
typedef GlobeClusterTapCallback = void Function(String id, LatLng position);
typedef GlobeZoneTapCallback = ValueChanged<String>;
typedef GlobeReadyCallback = VoidCallback;
typedef GlobeDebugCallback = void Function({double? fps, String? cameraInfo});

/// MapLibre GL JS globe renderer — same engine family as DuoFrontend `/map`.
class DuoGlobeWebView extends StatefulWidget {
  const DuoGlobeWebView({
    super.key,
    required this.userCoordinates,
    required this.markers,
    required this.zones,
    required this.enabledLayers,
    required this.themeBrightness,
    this.weather,
    this.focusProfileId,
    this.currentZoom = 11,
    this.onViewportChanged,
    this.onMarkerTap,
    this.onClusterTap,
    this.onZoneTap,
    this.onReady,
    this.onDebug,
    this.flyToCommand,
    this.cameraCommand,
    this.followCenter,
  });

  final LatLng userCoordinates;
  final List<MapProfile> markers;
  final List<ActivityZone> zones;
  final Map<String, bool> enabledLayers;
  final Brightness themeBrightness;
  final MapWeatherAmbience? weather;
  final String? focusProfileId;
  final double currentZoom;
  final GlobeViewportCallback? onViewportChanged;
  final GlobeMarkerTapCallback? onMarkerTap;
  final GlobeClusterTapCallback? onClusterTap;
  final GlobeZoneTapCallback? onZoneTap;
  final GlobeReadyCallback? onReady;
  final GlobeDebugCallback? onDebug;
  final GlobeFlyToCommand? flyToCommand;
  final GlobeCameraCommand? cameraCommand;
  final LatLng? followCenter;

  @override
  State<DuoGlobeWebView> createState() => DuoGlobeWebViewState();
}

class GlobeFlyToCommand {
  const GlobeFlyToCommand({
    required this.target,
    required this.zoom,
    required this.token,
    this.pitch = 52,
  });

  final LatLng target;
  final double zoom;
  final int token;
  final double pitch;
}

class GlobeCameraCommand {
  const GlobeCameraCommand({required this.action, required this.token});

  final GlobeCameraAction action;
  final int token;
}

enum GlobeCameraAction { zoomIn, zoomOut, resetNorth, recenter }

class DuoGlobeWebViewState extends State<DuoGlobeWebView> {
  late final WebViewController _controller;
  bool _pageLoaded = false;
  bool _notifiedReady = false;
  GlobeFlyToCommand? _lastFlyCommand;
  GlobeCameraCommand? _lastCameraCommand;
  LatLng? _lastFollowCenter;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF05050F))
      ..addJavaScriptChannel(
        'DuoGlobeBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _pageLoaded = true;
            _bootstrapEngine();
          },
          onWebResourceError: (error) {
            debugPrint('DuoGlobe WebView error: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/map/duo_globe.html');
  }

  @override
  void didUpdateWidget(covariant DuoGlobeWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.flyToCommand != null &&
        widget.flyToCommand!.token != _lastFlyCommand?.token) {
      _lastFlyCommand = widget.flyToCommand;
      _pushState(flyTo: widget.flyToCommand);
    }

    if (widget.cameraCommand != null &&
        widget.cameraCommand!.token != _lastCameraCommand?.token) {
      _lastCameraCommand = widget.cameraCommand;
      _pushState(camera: widget.cameraCommand);
    }

    if (widget.followCenter != null &&
        widget.followCenter != _lastFollowCenter &&
        widget.followCenter != oldWidget.followCenter) {
      _lastFollowCenter = widget.followCenter;
      _pushState(recenter: widget.followCenter);
    }

    final markersChanged = !listEquals(widget.markers, oldWidget.markers) ||
        widget.focusProfileId != oldWidget.focusProfileId;
    final zonesChanged = !listEquals(widget.zones, oldWidget.zones);
    final layersChanged = !mapEquals(widget.enabledLayers, oldWidget.enabledLayers);
    final weatherChanged = widget.weather != oldWidget.weather;
    final userMoved = widget.userCoordinates != oldWidget.userCoordinates;

    if (markersChanged ||
        zonesChanged ||
        layersChanged ||
        weatherChanged ||
        userMoved ||
        widget.themeBrightness != oldWidget.themeBrightness) {
      _pushState();
    }
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    final raw = message.message;
    if (raw.isEmpty) return;

    Map<String, dynamic>? payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (payload['type']) {
      case 'ready':
        if (!_notifiedReady) {
          _notifiedReady = true;
          widget.onReady?.call();
        }
        _pushState(fitInitial: true);
      case 'viewport':
        widget.onViewportChanged?.call(
          latMin: (payload['latMin'] as num).toDouble(),
          latMax: (payload['latMax'] as num).toDouble(),
          lonMin: (payload['lonMin'] as num).toDouble(),
          lonMax: (payload['lonMax'] as num).toDouble(),
          zoom: (payload['zoom'] as num).toDouble(),
          center: LatLng(
            (payload['centerLat'] as num).toDouble(),
            (payload['centerLng'] as num).toDouble(),
          ),
          bearing: (payload['bearing'] as num?)?.toDouble() ?? 0,
          pitch: (payload['pitch'] as num?)?.toDouble() ?? 0,
        );
      case 'debug':
        widget.onDebug?.call(
          fps: (payload['fps'] as num?)?.toDouble(),
          cameraInfo: payload['cameraInfo'] as String?,
        );
      case 'markerTap':
        final id = payload['id']?.toString();
        if (id != null) widget.onMarkerTap?.call(id);
      case 'clusterTap':
        final id = payload['id']?.toString();
        final lat = (payload['lat'] as num?)?.toDouble();
        final lng = (payload['lng'] as num?)?.toDouble();
        if (id != null && lat != null && lng != null) {
          widget.onClusterTap?.call(id, LatLng(lat, lng));
        }
      case 'zoneTap':
        final id = payload['id']?.toString();
        if (id != null) widget.onZoneTap?.call(id);
      default:
        break;
    }
  }

  Future<void> _bootstrapEngine() async {
    if (!_pageLoaded) return;
    final init = jsonEncode({
      'center': [
        widget.userCoordinates.longitude,
        widget.userCoordinates.latitude,
      ],
      'zoom': 2.2,
      'styleKey': baseMapIdToStyleKey(activeBaseMapId(widget.enabledLayers)),
      'themeBrightness':
          widget.themeBrightness == Brightness.dark ? 'dark' : 'light',
      'layers': widget.enabledLayers,
    });
    await _controller.runJavaScript('window.duoGlobe.init($init);');
  }

  List<Map<String, dynamic>> _markerPayload() {
    final showProfiles = isLayerEnabled(widget.enabledLayers, 'duo-profiles');
    final showUser = isLayerEnabled(widget.enabledLayers, 'duo-user-location');
    final payload = <Map<String, dynamic>>[];

    if (showUser) {
      payload.add({
        'id': 'user',
        'kind': 'user',
        'lat': widget.userCoordinates.latitude,
        'lng': widget.userCoordinates.longitude,
      });
    }

    if (!showProfiles) return payload;

    final clusters =
        clusterMapProfiles(profiles: widget.markers, zoom: widget.currentZoom);
    for (final cluster in clusters) {
      if (cluster.isCluster) {
        payload.add({
          'id': cluster.id,
          'isCluster': true,
          'count': cluster.count,
          'lat': cluster.position.latitude,
          'lng': cluster.position.longitude,
        });
      } else {
        final profile = cluster.profiles.first;
        final key = mapProfileKey(profile.profile);
        payload.add({
          'id': key,
          'profileId': key,
          'lat': cluster.position.latitude,
          'lng': cluster.position.longitude,
          'photoUrl': profile.profile.displayPhoto,
          'initials': profile.profile.displayName.isNotEmpty
              ? profile.profile.displayName[0].toUpperCase()
              : '?',
          'distanceLabel': profile.distanceMeters == null
              ? null
              : formatDistanceCompact(profile.distanceMeters!),
          'isActive': key == widget.focusProfileId,
        });
      }
    }
    return payload;
  }

  List<Map<String, dynamic>> _zonePayload() {
    if (!isLayerEnabled(widget.enabledLayers, 'duo-activity-heatmap')) {
      return const [];
    }
    return [
      for (final zone in widget.zones)
        {
          'id': zone.id,
          'lat': zone.lat,
          'lng': zone.lng,
          'level': zone.level,
          'radiusKm': zone.radiusKm,
          'score': zone.score,
          'name': zone.name,
        },
    ];
  }

  Future<void> _pushState({
    GlobeFlyToCommand? flyTo,
    GlobeCameraCommand? camera,
    LatLng? recenter,
    bool fitInitial = false,
  }) async {
    if (!_pageLoaded) return;

    final state = <String, dynamic>{
      'styleKey': baseMapIdToStyleKey(activeBaseMapId(widget.enabledLayers)),
      'themeBrightness':
          widget.themeBrightness == Brightness.dark ? 'dark' : 'light',
      'layers': widget.enabledLayers,
      'markers': _markerPayload(),
      'zones': _zonePayload(),
      'weather': widget.weather?.toGlobePayload(),
    };

    if (fitInitial) {
      state['fitBounds'] = {
        'lat': widget.userCoordinates.latitude,
        'lng': widget.userCoordinates.longitude,
        'radiusKm': 20,
      };
    }

    if (flyTo != null) {
      state['flyTo'] = {
        'lat': flyTo.target.latitude,
        'lng': flyTo.target.longitude,
        'zoom': flyTo.zoom,
        'pitch': flyTo.pitch,
      };
    }

    if (camera != null) {
      state['command'] = switch (camera.action) {
        GlobeCameraAction.zoomIn => 'zoomIn',
        GlobeCameraAction.zoomOut => 'zoomOut',
        GlobeCameraAction.resetNorth => 'resetNorth',
        GlobeCameraAction.recenter => null,
      };
      if (camera.action == GlobeCameraAction.recenter) {
        state['recenter'] = {
          'lat': widget.userCoordinates.latitude,
          'lng': widget.userCoordinates.longitude,
          'zoom': 13.5,
        };
      }
    }

    if (recenter != null) {
      state['recenter'] = {
        'lat': recenter.latitude,
        'lng': recenter.longitude,
        'zoom': 11,
      };
    }

    final encoded = jsonEncode(state);
    await _controller.runJavaScript('window.duoGlobe.applyState($encoded);');
  }

  @override
  void dispose() {
    if (_pageLoaded) {
      _controller.runJavaScript('window.duoGlobe.dispose();');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
