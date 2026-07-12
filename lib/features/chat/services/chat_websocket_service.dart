import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../../../repositories/chat_repository.dart';

/// Parsed WebSocket payloads from DuoBackend chat consumer.
class ChatWsEvent {
  const ChatWsEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic> data;
}

/// Per-conversation WebSocket client aligned with Next.js `useChatWebSocket`.
class ChatWebSocketService {
  ChatWebSocketService(this._repository);

  final ChatRepository _repository;

  static const _reconnectBaseMs = 1000;
  static const _reconnectMaxMs = 15000;
  static const _connectTimeout = Duration(seconds: 15);

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _conversationId;

  final _eventsController = StreamController<ChatWsEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<ChatWsEvent> get events => _eventsController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String conversationId) async {
    if (_disposed) return;
    if (_conversationId == conversationId && (_isConnected || _isConnecting)) {
      return;
    }
    _conversationId = conversationId;
    _reconnectAttempt = 0;
    await _openSocket();
  }

  Future<void> reconnect() async {
    if (_disposed || _conversationId == null) return;
    _reconnectAttempt = 0;
    await _closeCurrentSocket();
    await _openSocket();
  }

  Future<void> _openSocket() async {
    if (_disposed || _conversationId == null) return;
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    _reconnectTimer?.cancel();

    try {
      _log('connecting', {'conversation': _conversationId});
      final ticket = await _repository.getWsTicket(_conversationId!);
      if (_disposed) return;

      await _closeCurrentSocket();

      final uri = Uri.parse(
        '${AppConfig.wsBaseUrl}/ws/chat/$_conversationId/?ticket=$ticket',
      );
      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(_connectTimeout);
      if (_disposed) {
        await channel.sink.close();
        return;
      }

      _channel = channel;
      _isConnecting = false;
      _isConnected = true;
      _reconnectAttempt = 0;
      _connectionController.add(true);
      _stopPolling();
      _log('connected', {'conversation': _conversationId});

      send({'type': 'mark_read'});

      _subscription = channel.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            _log('event_in', {'type': type});
            _eventsController.add(ChatWsEvent(type, data));
          } catch (_) {}
        },
        onError: (error) {
          _log('stream_error', {'error': '$error'});
          _handleDisconnect();
        },
        onDone: () {
          _log('stream_done', {});
          _handleDisconnect();
        },
      );
    } catch (error) {
      _log('connect_failed', {'error': '$error'});
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      await _closeCurrentSocket();
      _scheduleReconnect();
      _startPolling();
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    final wasConnected = _isConnected;
    _isConnected = false;
    _isConnecting = false;
    if (wasConnected) {
      _connectionController.add(false);
      _log('disconnected', {'conversation': _conversationId});
    }
    unawaited(_closeCurrentSocket());
    _scheduleReconnect();
    _startPolling();
  }

  void _scheduleReconnect() {
    if (_disposed || _conversationId == null || _isConnecting || _isConnected) return;
    _reconnectTimer?.cancel();
    final delayMs = (_reconnectBaseMs * (1 << _reconnectAttempt.clamp(0, 4)))
        .clamp(_reconnectBaseMs, _reconnectMaxMs);
    _reconnectAttempt++;
    _log('reconnect_scheduled', {'delayMs': delayMs, 'attempt': _reconnectAttempt});
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_disposed && !_isConnected && !_isConnecting) {
        unawaited(_openSocket());
      }
    });
  }

  void _startPolling() {
    if (_pollTimer != null || _disposed || _conversationId == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!_disposed && !_isConnected) {
        _eventsController.add(const ChatWsEvent('poll_messages', {}));
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool send(Map<String, dynamic> payload) {
    if (!_isConnected) return false;
    final channel = _channel;
    if (channel == null) return false;
    try {
      _log('event_out', {'type': payload['type']});
      channel.sink.add(jsonEncode(payload));
      return true;
    } catch (error) {
      _log('send_failed', {'error': '$error'});
      return false;
    }
  }

  Future<void> _closeCurrentSocket() async {
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _isConnected = false;
    _isConnecting = false;
    _reconnectTimer?.cancel();
    _stopPolling();
    await _closeCurrentSocket();
    await _eventsController.close();
    await _connectionController.close();
  }

  void _log(String event, Map<String, Object?> data) {
    if (kDebugMode) {
      debugPrint('[ChatWS] $event $data');
    }
  }
}
