import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../../../repositories/call_repository.dart';
import '../../../repositories/notification_repository.dart';

class CallSignalEvent {
  const CallSignalEvent(this.type, this.data);
  final String type;
  final Map<String, dynamic> data;
}

/// WebRTC signaling over Django Channels `ws/call/<conversation_id>/`
/// (port of DuoFrontend `lib/call/callWebSocket.ts`).
class CallSignalingService {
  CallSignalingService(this._repository);

  final CallRepository _repository;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _events = StreamController<CallSignalEvent>.broadcast();
  final _closed = StreamController<void>.broadcast();

  Stream<CallSignalEvent> get events => _events.stream;

  /// Fires when the current call socket closes unexpectedly.
  Stream<void> get closed => _closed.stream;

  bool get isOpen => _channel != null;

  Future<void> connect(String conversationId) async {
    await disconnect();
    final ticket = await _repository.getCallWsTicket(conversationId);
    final uri = AppConfig.webSocketUri(
      '/ws/call/$conversationId/',
      queryParameters: {'ticket': ticket},
    );
    final channel = WebSocketChannel.connect(uri);
    await channel.ready.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException('Call connection timed out.'),
    );
    _channel = channel;
    _subscription = channel.stream.listen(
      (raw) {
        try {
          final data = Map<String, dynamic>.from(jsonDecode(raw as String) as Map);
          final type = '${data['type']}';
          if (type == 'call_signal') {
            _events.add(CallSignalEvent('${data['event']}', data));
          } else {
            _events.add(CallSignalEvent(type, data));
          }
        } catch (_) {}
      },
      onError: (_) {},
      onDone: () {
        if (identical(_channel, channel)) {
          _channel = null;
          _closed.add(null);
        }
      },
    );
  }

  Future<void> disconnect() async {
    final channel = _channel;
    _channel = null; // mark intentional so onDone does not report a drop
    await _subscription?.cancel();
    _subscription = null;
    try {
      await channel?.sink.close();
    } catch (_) {}
  }

  bool send(String type, String callId, [Map<String, dynamic> extra = const {}]) {
    final channel = _channel;
    if (channel == null) return false;
    channel.sink.add(jsonEncode({'type': type, 'call_id': callId, ...extra}));
    return true;
  }

  void dispose() {
    disconnect();
    _events.close();
    _closed.close();
  }
}

/// App-wide inbox socket for `call_incoming` and call lifecycle events, with
/// exponential-backoff reconnect (web `useCallManager` inbox effect).
class InboxWebSocketService {
  InboxWebSocketService(this._notifications);

  final NotificationRepository _notifications;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _retryTimer;
  int _retry = 0;
  bool _wanted = false;
  final _events = StreamController<CallSignalEvent>.broadcast();

  Stream<CallSignalEvent> get events => _events.stream;

  Future<void> connect() async {
    _wanted = true;
    _retryTimer?.cancel();
    await _close();
    try {
      final ticket = await _notifications.getInboxWsTicket();
      if (!_wanted) return;
      final uri = AppConfig.webSocketUri('/ws/inbox/', queryParameters: {'ticket': ticket});
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _retry = 0;
      _subscription = channel.stream.listen(
        (raw) {
          try {
            final data = Map<String, dynamic>.from(jsonDecode(raw as String) as Map);
            _events.add(CallSignalEvent('${data['type']}', data));
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {
          if (identical(_channel, channel)) {
            _channel = null;
            _schedule();
          }
        },
      );
    } catch (_) {
      _schedule();
    }
  }

  void _schedule() {
    if (!_wanted) return;
    _retryTimer?.cancel();
    final delay = Duration(milliseconds: (1000 * (1 << _retry.clamp(0, 5))).clamp(1000, 30000));
    _retry++;
    _retryTimer = Timer(delay, () => connect());
  }

  Future<void> _close() async {
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await channel?.sink.close();
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    await _close();
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}
