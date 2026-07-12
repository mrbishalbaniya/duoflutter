import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../../../repositories/chat_repository.dart';
import 'chat_debug_log.dart';

/// Parsed WebSocket payloads from DuoBackend chat consumer.
class ChatWsEvent {
  const ChatWsEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic> data;
}

/// Connection state aligned with Next.js `useChatWebSocket` semantics.
class WsConnectionState {
  const WsConnectionState({
    required this.connected,
    required this.reconnecting,
  });

  final bool connected;
  final bool reconnecting;

  static const idle = WsConnectionState(connected: false, reconnecting: false);
}

/// Per-conversation WebSocket client — one socket per open thread.
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
  bool _isReconnecting = false;
  String? _conversationId;

  final _eventsController = StreamController<ChatWsEvent>.broadcast();
  final _connectionController = StreamController<WsConnectionState>.broadcast();

  Stream<ChatWsEvent> get events => _eventsController.stream;
  Stream<WsConnectionState> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;

  /// Connect using the conversation **public_id** (must match WS ticket).
  Future<void> connect(String publicConversationId) async {
    if (_disposed) return;

    final id = publicConversationId.trim();
    if (id.isEmpty) return;

    if (_conversationId == id && _isConnected) {
      _emitState();
      return;
    }
    if (_conversationId == id && _isConnecting) {
      return;
    }

    _conversationId = id;
    _reconnectAttempt = 0;
    await _openSocket();
  }

  Future<void> reconnect() async {
    if (_disposed || _conversationId == null) return;
    _log('reconnect_manual', {'conversation': _conversationId});
    _reconnectAttempt = 0;
    _isConnected = false;
    _isConnecting = false;
    _isReconnecting = true;
    _emitState();
    await _tearDownSocket(cancelReconnect: true);
    await _openSocket();
  }

  Future<void> _openSocket() async {
    if (_disposed || _conversationId == null) return;
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    _isReconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _emitState();

    final sw = Stopwatch()..start();
    try {
      _log('connecting', {'conversation': _conversationId});
      ChatDebugLog.wsStatus(status: 'connecting', conversationId: _conversationId!);
      final ticket = await _repository.getWsTicket(_conversationId!);
      if (_disposed) return;

      await _tearDownSocket(cancelReconnect: true);

      final uri = AppConfig.webSocketUri(
        '/ws/chat/$_conversationId/',
        queryParameters: {'ticket': ticket},
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
      _isReconnecting = false;
      _reconnectAttempt = 0;
      _emitState();
      _stopPolling();
      _log('connected', {
        'conversation': _conversationId,
        'latencyMs': sw.elapsedMilliseconds,
      });
      ChatDebugLog.wsStatus(
        status: 'connected',
        conversationId: _conversationId!,
        latencyMs: sw.elapsedMilliseconds,
      );

      send({'type': 'mark_read'});

      _subscription = channel.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            _log('event_in', {'type': type});
            ChatDebugLog.messageIn(
              type: type,
              conversationId: _conversationId ?? '',
            );
            _eventsController.add(ChatWsEvent(type, data));
          } catch (error) {
            _log('event_parse_error', {'error': '$error'});
          }
        },
        onError: (error) {
          _log('stream_error', {'error': '$error'});
          _handleDisconnect();
        },
        onDone: () {
          _log('stream_done', {});
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } catch (error) {
      _log('connect_failed', {
        'error': '$error',
        'latencyMs': sw.elapsedMilliseconds,
      });
      _isConnecting = false;
      _isConnected = false;
      _emitState();
      await _tearDownSocket(cancelReconnect: true);
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
      _log('disconnected', {'conversation': _conversationId});
    }
    _emitState();
    unawaited(_tearDownSocket(cancelReconnect: false));
    _scheduleReconnect();
    _startPolling();
  }

  void _scheduleReconnect() {
    if (_disposed || _conversationId == null || _isConnecting || _isConnected) {
      return;
    }
    _reconnectTimer?.cancel();
    final delayMs = (_reconnectBaseMs * (1 << _reconnectAttempt.clamp(0, 4)))
        .clamp(_reconnectBaseMs, _reconnectMaxMs);
    _reconnectAttempt++;
    _isReconnecting = true;
    _emitState();
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

  /// Tear down socket. [cancelReconnect] false when disconnect handler will reschedule.
  Future<void> _tearDownSocket({required bool cancelReconnect}) async {
    if (cancelReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
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

  void _emitState() {
    if (_disposed) return;
    _connectionController.add(
      WsConnectionState(
        connected: _isConnected,
        reconnecting: _isReconnecting && !_isConnected,
      ),
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _isConnected = false;
    _isConnecting = false;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _stopPolling();
    await _tearDownSocket(cancelReconnect: true);
    await _eventsController.close();
    await _connectionController.close();
  }

  void _log(String event, Map<String, Object?> data) {
    if (kDebugMode) {
      debugPrint('[ChatWS] $event $data');
    }
  }
}
