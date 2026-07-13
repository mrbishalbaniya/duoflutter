import 'dart:async';
import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../map_models.dart';

class ActivityWsEvent {
  const ActivityWsEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}

class ActivityWebSocketService {
  static const _reconnectBaseMs = 1500;
  static const _reconnectMaxMs = 20000;
  static const _connectTimeout = Duration(seconds: 15);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _appInBackground = false;

  final _eventsController = StreamController<ActivityWsEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<ActivityWsEvent> get events => _eventsController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> connect() async {
    _disposed = false;
    _reconnectAttempt = 0;
    await _openSocket();
  }

  Future<void> _openSocket() async {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    try {
      await _subscription?.cancel();
      await _channel?.sink.close();

      final uri = AppConfig.webSocketUri('/ws/activity/');
      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(_connectTimeout);
      if (_disposed) {
        await channel.sink.close();
        return;
      }

      _channel = channel;
      _connectionController.add(true);
      _reconnectAttempt = 0;

      _subscription = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            _eventsController.add(ActivityWsEvent(type, data));
          } catch (_) {}
        },
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
    } catch (_) {
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _connectionController.add(false);
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _appInBackground) return;
    _reconnectTimer?.cancel();
    final delayMs = (_reconnectBaseMs * (1 << _reconnectAttempt.clamp(0, 4)))
        .clamp(_reconnectBaseMs, _reconnectMaxMs);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _openSocket);
  }

  bool sendViewport({
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
    required double zoom,
    required ActivityLayerFlags flags,
    LatLng? userCoords,
  }) {
    return send({
      'type': 'viewport',
      'lat_min': latMin,
      'lat_max': latMax,
      'lon_min': lonMin,
      'lon_max': lonMax,
      'zoom': zoom,
      'trending': flags.trending,
      'events': flags.events,
      'friends': flags.friends,
      'nearby': flags.nearby,
      if (userCoords != null) ...{
        'user_lat': userCoords.latitude,
        'user_lng': userCoords.longitude,
        'nearby_km': 140,
      },
    });
  }

  void setAppInBackground(bool inBackground) {
    _appInBackground = inBackground;
    if (inBackground) _reconnectTimer?.cancel();
  }

  bool send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) return false;
    try {
      channel.sink.add(jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    await _eventsController.close();
    await _connectionController.close();
  }
}

List<ActivityZone> parseActivityZones(Map<String, dynamic> data) {
  final zones = data['zones'] as List<dynamic>? ?? [];
  return zones
      .map((e) => ActivityZone.fromJson(e as Map<String, dynamic>))
      .toList();
}
