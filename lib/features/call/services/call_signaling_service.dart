import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../../../repositories/notification_repository.dart';
import '../../../repositories/call_repository.dart';

class CallSignalEvent {
  const CallSignalEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic> data;
}

/// WebRTC signaling over Django Channels `ws/call/<conversation_id>/`.
class CallSignalingService {
  CallSignalingService(this._repository);

  final CallRepository _repository;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _events = StreamController<CallSignalEvent>.broadcast();

  Stream<CallSignalEvent> get events => _events.stream;

  Future<void> connect(String conversationId) async {
    await disconnect();
    final ticket = await _repository.getCallWsTicket(conversationId);
    final uri = AppConfig.webSocketUri(
      '/ws/call/$conversationId/',
      queryParameters: {'ticket': ticket},
    );
    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen(
      (raw) {
        try {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final type = '${data['type']}';
          if (type == 'call_signal') {
            _events.add(CallSignalEvent('${data['event']}', Map<String, dynamic>.from(data)));
          } else {
            _events.add(CallSignalEvent(type, data));
          }
        } catch (_) {}
      },
      onError: (_) {},
    );
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  void send({
    required String type,
    required String callId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? extra,
  }) {
    final message = {
      'type': type,
      'call_id': callId,
      if (payload != null) 'payload': payload,
      ...?extra,
    };
    _channel?.sink.add(jsonEncode(message));
  }

  void sendOffer(String callId, String sdp, String sdpType) {
    send(type: 'call_offer', callId: callId, extra: {'sdp': sdp, 'sdp_type': sdpType});
  }

  void sendAnswer(String callId, String sdp, String sdpType) {
    send(type: 'call_answer', callId: callId, extra: {'sdp': sdp, 'sdp_type': sdpType});
  }

  void sendIceCandidate(String callId, Map<String, dynamic> candidate) {
    send(
      type: 'ice_candidate',
      callId: callId,
      extra: {
        'candidate': candidate['candidate'],
        'sdp_mid': candidate['sdpMid'],
        'sdp_mline_index': candidate['sdpMLineIndex'],
      },
    );
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}

/// App-wide inbox socket for `call_incoming` when user is not in chat.
class InboxWebSocketService {
  InboxWebSocketService(this._notifications);

  final NotificationRepository _notifications;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _events = StreamController<CallSignalEvent>.broadcast();

  Stream<CallSignalEvent> get events => _events.stream;

  Future<void> connect() async {
    await disconnect();
    final ticket = await _notifications.getInboxWsTicket();
    final uri = AppConfig.webSocketUri(
      '/ws/inbox/',
      queryParameters: {'ticket': ticket},
    );
    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen((raw) {
      try {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        _events.add(CallSignalEvent('${data['type']}', data));
      } catch (_) {}
    });
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}
