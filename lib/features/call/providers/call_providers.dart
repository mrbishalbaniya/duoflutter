import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/call_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../services/call_signaling_service.dart';
import '../services/webrtc_service.dart';

enum CallPhase { idle, outgoing, incoming, connecting, active, ended }

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.conversationId,
    this.callType = 'voice',
    this.remoteName = '',
    this.remotePhoto,
    this.isOutgoing = false,
    this.connectionQuality = 'new',
    this.error,
  });

  final CallPhase phase;
  final String? callId;
  final String? conversationId;
  final String callType;
  final String remoteName;
  final String? remotePhoto;
  final bool isOutgoing;
  final String connectionQuality;
  final String? error;

  bool get isVideo => callType == 'video';

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    String? conversationId,
    String? callType,
    String? remoteName,
    String? remotePhoto,
    bool? isOutgoing,
    String? connectionQuality,
    String? error,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      conversationId: conversationId ?? this.conversationId,
      callType: callType ?? this.callType,
      remoteName: remoteName ?? this.remoteName,
      remotePhoto: remotePhoto ?? this.remotePhoto,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      error: error,
    );
  }
}

class CallController extends StateNotifier<CallState> {
  CallController(this._repository, this._signaling, this._webrtc, this._inbox)
      : super(const CallState()) {
    _signalingSub = _signaling.events.listen(_onSignal);
    _inboxSub = _inbox.events.listen(_onInbox);
    _qualitySub = _webrtc.connectionQuality.listen((q) {
      state = state.copyWith(connectionQuality: q);
    });
  }

  final CallRepository _repository;
  final CallSignalingService _signaling;
  final WebRtcCallService _webrtc;
  final InboxWebSocketService _inbox;

  late final StreamSubscription _signalingSub;
  late final StreamSubscription _inboxSub;
  late final StreamSubscription _qualitySub;

  WebRtcCallService get webrtc => _webrtc;
  Stream<dynamic> get remoteStream => _webrtc.remoteStream;

  Future<void> connectInbox() => _inbox.connect();

  Future<void> startOutgoingCall({
    required String conversationId,
    required String callType,
    required String remoteName,
    String? remotePhoto,
  }) async {
    state = state.copyWith(
      phase: CallPhase.outgoing,
      conversationId: conversationId,
      callType: callType,
      remoteName: remoteName,
      remotePhoto: remotePhoto,
      isOutgoing: true,
    );
    try {
      final session = await _repository.initiateCall(
        conversationId: conversationId,
        callType: callType,
      );
      state = state.copyWith(callId: session.id, phase: CallPhase.connecting);
      await _signaling.connect(conversationId);
      await _webrtc.initialize(
        iceServers: session.iceServers,
        video: callType == 'video',
        onIceCandidate: (c) => _signaling.sendIceCandidate(session.id, c.toMap()),
      );
      final sdp = await _webrtc.createOffer();
      _signaling.sendOffer(session.id, sdp, 'offer');
    } catch (e) {
      state = state.copyWith(phase: CallPhase.ended, error: '$e');
    }
  }

  Future<void> handleIncoming({
    required String callId,
    required String conversationId,
    required String callType,
    required String remoteName,
    String? remotePhoto,
  }) async {
    if (state.phase != CallPhase.idle) return;
    state = state.copyWith(
      phase: CallPhase.incoming,
      callId: callId,
      conversationId: conversationId,
      callType: callType,
      remoteName: remoteName,
      remotePhoto: remotePhoto,
      isOutgoing: false,
    );
  }

  Future<void> acceptIncoming() async {
    final callId = state.callId;
    final conversationId = state.conversationId;
    if (callId == null || conversationId == null) return;
    state = state.copyWith(phase: CallPhase.connecting);
    try {
      final session = await _repository.acceptCall(callId);
      await _signaling.connect(conversationId);
      await _webrtc.initialize(
        iceServers: session.iceServers,
        video: state.isVideo,
        onIceCandidate: (c) => _signaling.sendIceCandidate(callId, c.toMap()),
      );
      state = state.copyWith(phase: CallPhase.active);
    } catch (e) {
      state = state.copyWith(phase: CallPhase.ended, error: '$e');
    }
  }

  Future<void> rejectIncoming() async {
    final callId = state.callId;
    if (callId != null) await _repository.rejectCall(callId);
    await _cleanup();
    state = const CallState(phase: CallPhase.ended);
  }

  Future<void> hangup() async {
    final callId = state.callId;
    if (callId != null) {
      if (state.phase == CallPhase.outgoing) {
        await _repository.cancelCall(callId);
      } else {
        await _repository.hangupCall(callId);
      }
    }
    await _cleanup();
    state = const CallState(phase: CallPhase.ended);
  }

  Future<void> _cleanup() async {
    await _webrtc.dispose();
    await _signaling.disconnect();
  }

  void reset() {
    state = const CallState();
  }

  Future<void> _onSignal(CallSignalEvent event) async {
    final callId = state.callId;
    if (callId == null) return;
    switch (event.type) {
      case 'call_accepted':
        state = state.copyWith(phase: CallPhase.active);
      case 'call_offer':
        final sdp = '${event.data['payload']?['sdp'] ?? event.data['sdp']}';
        final sdpType = '${event.data['payload']?['type'] ?? event.data['sdp_type'] ?? 'offer'}';
        if (!state.isOutgoing && sdp.isNotEmpty) {
          await _webrtc.applyRemoteOffer(sdp, sdpType);
          final answer = await _webrtc.createAnswer();
          _signaling.sendAnswer(callId, answer, 'answer');
          state = state.copyWith(phase: CallPhase.active);
        }
      case 'call_answer':
        final sdp = '${event.data['payload']?['sdp'] ?? event.data['sdp']}';
        final sdpType = '${event.data['payload']?['type'] ?? event.data['sdp_type'] ?? 'answer'}';
        if (sdp.isNotEmpty) {
          await _webrtc.applyRemoteAnswer(sdp, sdpType);
          state = state.copyWith(phase: CallPhase.active);
        }
      case 'ice_candidate':
        final payload = event.data['payload'] as Map<String, dynamic>? ?? event.data;
        await _webrtc.addIceCandidate(Map<String, dynamic>.from(payload));
      case 'call_ended':
      case 'call_rejected':
      case 'call_cancelled':
      case 'call_missed':
      case 'call_busy':
        await _cleanup();
        state = const CallState(phase: CallPhase.ended);
      default:
        break;
    }
  }

  void _onInbox(CallSignalEvent event) {
    if (event.type != 'call_incoming') return;
    handleIncoming(
      callId: '${event.data['call_id']}',
      conversationId: '${event.data['conversation_id']}',
      callType: '${event.data['call_type'] ?? 'voice'}',
      remoteName: '${event.data['caller_name'] ?? 'Someone'}',
      remotePhoto: event.data['caller_photo'] as String?,
    );
  }

  @override
  void dispose() {
    _signalingSub.cancel();
    _inboxSub.cancel();
    _qualitySub.cancel();
    _webrtc.dispose();
    _signaling.dispose();
    _inbox.dispose();
    super.dispose();
  }
}

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(ref.watch(dioClientProvider));
});

final callSignalingServiceProvider = Provider<CallSignalingService>((ref) {
  return CallSignalingService(ref.watch(callRepositoryProvider));
});

final inboxWebSocketServiceProvider = Provider<InboxWebSocketService>((ref) {
  return InboxWebSocketService(ref.watch(notificationRepositoryProvider));
});

final webRtcCallServiceProvider = Provider<WebRtcCallService>((ref) {
  final service = WebRtcCallService();
  ref.onDispose(service.closeControllers);
  return service;
});

final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
  return CallController(
    ref.watch(callRepositoryProvider),
    ref.watch(callSignalingServiceProvider),
    ref.watch(webRtcCallServiceProvider),
    ref.watch(inboxWebSocketServiceProvider),
  );
});
