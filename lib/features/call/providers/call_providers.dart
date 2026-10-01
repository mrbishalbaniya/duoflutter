import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/providers/core_providers.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../../repositories/call_repository.dart';
import '../../auth/auth_controller.dart';
import '../services/call_signaling_service.dart';
import '../services/call_tone_player.dart';
import '../services/webrtc_service.dart';

enum CallPhase { idle, outgoing, incoming, connecting, active, ended }

const _ringTimeout = Duration(seconds: 45);
const _connectTimeout = Duration(seconds: 30);
const _disconnectGrace = Duration(seconds: 10);
const _endedScreen = Duration(milliseconds: 2200);

const _terminalEvents = {
  'call_ended',
  'call_rejected',
  'call_cancelled',
  'call_missed',
  'call_busy',
};

const _endMessages = {
  'call_ended': 'Call ended',
  'call_rejected': 'Call declined',
  'call_cancelled': 'Call cancelled',
  'call_missed': 'No answer',
  'call_busy': 'User is busy',
};

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.conversationId,
    this.callType = 'voice',
    this.callerId,
    this.remoteName = '',
    this.remotePhoto,
    this.isOutgoing = false,
    this.connectionState = 'new',
    this.endMessage,
    this.micOn = true,
    this.videoOn = true,
    this.speakerOn = false,
    this.hasLocalVideo = false,
    this.remoteStream,
    this.connectedAt,
  });

  final CallPhase phase;
  final String? callId;
  final String? conversationId;
  final String callType;
  final int? callerId;
  final String remoteName;
  final String? remotePhoto;
  final bool isOutgoing;
  final String connectionState;

  /// Text for the ended screen (or a failure reason).
  final String? endMessage;
  final bool micOn;
  final bool videoOn;
  final bool speakerOn;
  final bool hasLocalVideo;
  final MediaStream? remoteStream;
  final DateTime? connectedAt;

  bool get isVideo => callType == 'video';

  /// Kept for older call sites.
  String? get error => endMessage;

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    String? conversationId,
    String? callType,
    int? callerId,
    String? remoteName,
    String? remotePhoto,
    bool? isOutgoing,
    String? connectionState,
    String? endMessage,
    bool? micOn,
    bool? videoOn,
    bool? speakerOn,
    bool? hasLocalVideo,
    MediaStream? remoteStream,
    bool clearRemoteStream = false,
    DateTime? connectedAt,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      conversationId: conversationId ?? this.conversationId,
      callType: callType ?? this.callType,
      callerId: callerId ?? this.callerId,
      remoteName: remoteName ?? this.remoteName,
      remotePhoto: remotePhoto ?? this.remotePhoto,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      connectionState: connectionState ?? this.connectionState,
      endMessage: endMessage ?? this.endMessage,
      micOn: micOn ?? this.micOn,
      videoOn: videoOn ?? this.videoOn,
      speakerOn: speakerOn ?? this.speakerOn,
      hasLocalVideo: hasLocalVideo ?? this.hasLocalVideo,
      remoteStream: clearRemoteStream ? null : (remoteStream ?? this.remoteStream),
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

String _errorMessage(Object error, String fallback) {
  if (error is MediaPermissionException) return error.message;
  return fallback;
}

/// Port of DuoFrontend `lib/call/useCallManager.ts`.
class CallController extends StateNotifier<CallState> {
  CallController(
    this._repository,
    this._signaling,
    this._webrtc,
    this._inbox,
    this._currentUserId,
  ) : super(const CallState()) {
    _signalingSub = _signaling.events.listen((e) => _handleSignal(e));
    _signalClosedSub = _signaling.closed.listen((_) {
      if (_session != null && state.phase != CallPhase.active) {
        _endLocally('Call connection was lost');
      }
    });
    _inboxSub = _inbox.events.listen(_onInbox);
    _remoteSub = _webrtc.remoteStream.listen((stream) {
      if (stream != null && mounted) state = state.copyWith(remoteStream: stream);
    });
    _connectionSub = _webrtc.connectionState.listen(_onConnectionState);
  }

  final CallRepository _repository;
  final CallSignalingService _signaling;
  final WebRtcCallService _webrtc;
  final InboxWebSocketService _inbox;
  final int? Function() _currentUserId;
  final _tone = CallTonePlayer();

  late final StreamSubscription _signalingSub;
  late final StreamSubscription _signalClosedSub;
  late final StreamSubscription _inboxSub;
  late final StreamSubscription _remoteSub;
  late final StreamSubscription _connectionSub;

  /// Current session id/caller (refs in the web hook).
  String? _sessionId;
  String? _sessionConversationId;
  int? _sessionCallerId;
  List<Map<String, dynamic>> _sessionIce = const [];
  String? get _session => _sessionId;

  bool _accepted = false;
  bool _offerSent = false;
  ({String sdp, String type})? _pendingOffer;
  final Set<String> _seenSignals = {};
  final List<Timer> _timers = [];
  Timer? _disconnectTimer;
  Timer? _endedTimer;
  bool _ending = false;

  WebRtcCallService get webrtc => _webrtc;
  Stream<dynamic> get remoteStream => _webrtc.remoteStream;

  Future<void> connectInbox() => _inbox.connect();
  Future<void> disconnectInbox() => _inbox.disconnect();

  // ---------------------------------------------------------------- helpers

  void _setPhase(CallPhase phase, [CallState Function(CallState s)? extra]) {
    if (!mounted) return;
    final next = state.copyWith(phase: phase);
    state = extra == null ? next : extra(next);
  }

  void _addTimer(Duration d, void Function() fn) => _timers.add(Timer(d, fn));

  void _clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
  }

  Future<void> _cleanupMedia() async {
    await _tone.stop();
    _clearTimers();
    await _signaling.disconnect();
    _accepted = false;
    _offerSent = false;
    _pendingOffer = null;
    _seenSignals.clear();
    await _webrtc.close();
    try {
      await Helper.setSpeakerphoneOn(false);
    } catch (_) {}
  }

  /// Tear everything down, show a short ended screen, then go idle.
  void _finish(String? message) {
    if (_ending) return;
    _ending = true;
    unawaited(_cleanupMedia());
    _sessionId = null;
    if (mounted) {
      state = CallState(
        phase: CallPhase.ended,
        remoteName: state.remoteName,
        remotePhoto: state.remotePhoto,
        callType: state.callType,
        conversationId: state.conversationId,
        isOutgoing: state.isOutgoing,
        endMessage: message,
      );
    }
    _endedTimer?.cancel();
    _endedTimer = Timer(_endedScreen, () {
      _ending = false;
      if (mounted && state.phase == CallPhase.ended) state = const CallState();
    });
  }

  /// Tell the server we're leaving, choosing cancel/reject/hangup by phase.
  Future<void> _notifyServerEnd(String? callId, CallPhase phase, bool accepted) async {
    if (callId == null || callId.isEmpty) return;
    try {
      if (phase == CallPhase.incoming) {
        await _repository.rejectCall(callId);
      } else if (phase == CallPhase.outgoing && !accepted) {
        await _repository.cancelCall(callId);
      } else {
        await _repository.hangupCall(callId);
      }
    } catch (_) {
      // The server may already consider the call over.
    }
  }

  Future<void> _endLocally(String? message) async {
    final callId = _sessionId;
    final phase = state.phase;
    final accepted = _accepted;
    _finish(message);
    await _notifyServerEnd(callId, phase, accepted);
  }

  void _onConnectionState(RTCPeerConnectionState cs) {
    if (!mounted || _session == null) return;
    state = state.copyWith(connectionState: cs.name.replaceFirst('RTCPeerConnectionState', '').toLowerCase());
    switch (cs) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _disconnectTimer?.cancel();
        _disconnectTimer = null;
        _clearTimers();
        unawaited(_tone.stop());
        if (state.phase != CallPhase.active) {
          _setPhase(CallPhase.active, (s) => s.copyWith(connectedAt: DateTime.now()));
        }
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        _disconnectTimer ??= Timer(_disconnectGrace, () => _endLocally('Connection lost'));
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        _endLocally('Connection failed');
      default:
        break;
    }
  }

  void _sendIce(String callId, RTCIceCandidate c) {
    _signaling.send('ice_candidate', callId, {
      'candidate': c.candidate,
      'sdp_mid': c.sdpMid,
      'sdp_mline_index': c.sdpMLineIndex,
    });
  }

  Future<void> _trySendOffer() async {
    final callId = _sessionId;
    if (callId == null || _sessionCallerId != _currentUserId()) return;
    if (!_accepted || _offerSent) return;
    if (!_webrtc.isStarted || !_signaling.isOpen) return;
    _offerSent = true;
    try {
      final offer = await _webrtc.createOffer();
      _signaling.send('call_offer', callId, {'sdp': offer.sdp, 'sdp_type': offer.type});
    } catch (e) {
      _offerSent = false;
      await _endLocally(_errorMessage(e, 'Could not start the call'));
    }
  }

  Future<void> _answerOffer(String sdp, String type) async {
    final callId = _sessionId;
    if (callId == null) return;
    if (!_webrtc.isStarted) {
      _pendingOffer = (sdp: sdp, type: type);
      return;
    }
    try {
      final answer = await _webrtc.applyOffer(sdp, type);
      _signaling.send('call_answer', callId, {'sdp': answer.sdp, 'sdp_type': answer.type});
    } catch (e) {
      await _endLocally(_errorMessage(e, 'Could not connect the call'));
    }
  }

  Future<List<Map<String, dynamic>>> _resolveIceServers() async {
    if (_sessionIce.isNotEmpty) return _sessionIce;
    try {
      return await _repository.getIceServers();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _connectCallSocket(String conversationId) => _signaling.connect(conversationId);

  Future<void> _applyDefaultAudioRoute(bool video) async {
    // Video calls default to the loudspeaker, voice calls to the earpiece.
    await _webrtc.setSpeakerphone(video);
    if (mounted) state = state.copyWith(speakerOn: video);
  }

  // ---------------------------------------------------------------- signals

  Future<void> _handleSignal(CallSignalEvent event) async {
    final callId = _sessionId;
    if (callId == null) return;
    final data = event.data;
    final msgCallId = '${data['call_id'] ?? ''}';
    if (msgCallId.isNotEmpty && msgCallId != callId) return;

    // The server relays signals via both the call room and the inbox.
    final payload = data['payload'] is Map
        ? Map<String, dynamic>.from(data['payload'] as Map)
        : Map<String, dynamic>.from(data);
    final type = event.type;
    if (type != 'call_accepted' && !_terminalEvents.contains(type)) {
      final key = '$type|${payload['sdp'] ?? payload['candidate'] ?? ''}';
      if (!_seenSignals.add(key)) return;
    }

    switch (type) {
      case 'call_accepted':
        if (_sessionCallerId != _currentUserId() || _accepted) break;
        _accepted = true;
        await _tone.stop();
        _clearTimers();
        _addTimer(_connectTimeout, () {
          if (state.phase != CallPhase.active) _endLocally('Could not connect the call');
        });
        if (state.phase == CallPhase.outgoing) _setPhase(CallPhase.connecting);
        await _trySendOffer();
      case 'call_offer':
        final sdp = '${payload['sdp'] ?? ''}';
        if (sdp.isNotEmpty) await _answerOffer(sdp, '${payload['type'] ?? 'offer'}');
      case 'call_answer':
        final sdp = '${payload['sdp'] ?? ''}';
        if (sdp.isEmpty) break;
        try {
          await _webrtc.applyAnswer(sdp, '${payload['type'] ?? 'answer'}');
        } catch (e) {
          await _endLocally(_errorMessage(e, 'Could not connect the call'));
        }
      case 'ice_candidate':
        await _webrtc.addIceCandidate(payload);
      default:
        if (_terminalEvents.contains(type)) _finish(_endMessages[type] ?? 'Call ended');
    }
  }

  void _onInbox(CallSignalEvent event) {
    if (event.type == 'call_incoming') {
      _handleIncomingPayload(event.data);
    } else if (event.type == 'call_accepted' || _terminalEvents.contains(event.type)) {
      unawaited(_handleSignal(event));
    }
  }

  void _handleIncomingPayload(Map<String, dynamic> payload) {
    final callId = '${payload['call_id'] ?? ''}';
    if (callId.isEmpty) return;
    final callerId = int.tryParse('${payload['caller_id']}');
    if (callerId != null && callerId == _currentUserId()) return;
    if (_sessionId == callId) return;
    if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) {
      unawaited(_repository.markBusy(callId).catchError((_) {}));
      return;
    }
    handleIncoming(
      callId: callId,
      conversationId: '${payload['conversation_id'] ?? ''}',
      callType: '${payload['call_type'] ?? 'voice'}',
      remoteName: '${payload['caller_name'] ?? 'Someone'}',
      remotePhoto: payload['caller_photo'] as String?,
      callerId: callerId,
    );
  }

  // ---------------------------------------------------------------- public API

  /// Also used by push notifications (call ringing while app was backgrounded).
  Future<void> handleIncoming({
    required String callId,
    required String conversationId,
    required String callType,
    required String remoteName,
    String? remotePhoto,
    int? callerId,
  }) async {
    if (_sessionId == callId) return;
    if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) return;
    await _cleanupMedia();
    _endedTimer?.cancel();
    _ending = false;
    _sessionId = callId;
    _sessionConversationId = conversationId;
    _sessionCallerId = callerId;
    _sessionIce = const [];
    state = CallState(
      phase: CallPhase.incoming,
      callId: callId,
      conversationId: conversationId,
      callType: callType == 'video' ? 'video' : 'voice',
      callerId: callerId,
      remoteName: remoteName,
      remotePhoto: remotePhoto,
    );
    unawaited(_tone.start(CallTone.incoming));
    _addTimer(_ringTimeout, () {
      if (state.phase == CallPhase.incoming) _finish('Missed call');
    });
  }

  Future<void> startOutgoingCall({
    required String conversationId,
    required String callType,
    required String remoteName,
    String? remotePhoto,
  }) async {
    if (state.phase != CallPhase.idle && state.phase != CallPhase.ended) return;
    await _cleanupMedia();
    _endedTimer?.cancel();
    _ending = false;
    _sessionId = null;
    final video = callType == 'video';
    state = CallState(
      phase: CallPhase.outgoing,
      conversationId: conversationId,
      callType: video ? 'video' : 'voice',
      callerId: _currentUserId(),
      remoteName: remoteName,
      remotePhoto: remotePhoto,
      isOutgoing: true,
    );

    final MediaStream stream;
    try {
      stream = await WebRtcCallService.getCallMedia(video: video);
    } catch (e) {
      _finish(_errorMessage(e, 'Could not access the microphone'));
      return;
    }
    if (state.phase != CallPhase.outgoing) {
      for (final t in stream.getTracks()) {
        await t.stop();
      }
      return;
    }
    state = state.copyWith(
      hasLocalVideo: stream.getVideoTracks().isNotEmpty,
      videoOn: stream.getVideoTracks().isNotEmpty,
    );

    try {
      final session = await _repository.initiateCall(conversationId: conversationId, callType: callType);
      if (state.phase != CallPhase.outgoing) {
        for (final t in stream.getTracks()) {
          await t.stop();
        }
        await _repository.cancelCall(session.id).catchError((_) => session);
        return;
      }
      _sessionId = session.id;
      _sessionConversationId = session.conversationId.isNotEmpty ? session.conversationId : conversationId;
      _sessionCallerId = session.callerId != 0 ? session.callerId : _currentUserId();
      _sessionIce = session.iceServers;
      state = state.copyWith(callId: session.id, callerId: _sessionCallerId);
      unawaited(_tone.start(CallTone.outgoing));
      await _webrtc.start(
        stream,
        iceServers: await _resolveIceServers(),
        onIceCandidate: (c) => _sendIce(session.id, c),
      );
      await _applyDefaultAudioRoute(video);
      await _connectCallSocket(_sessionConversationId!);
      _addTimer(_ringTimeout, () {
        if (!_accepted && state.phase == CallPhase.outgoing) _endLocally('No answer');
      });
      // call_accepted may already have arrived while we were connecting.
      await _trySendOffer();
    } catch (e) {
      for (final t in stream.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      final callId = _sessionId;
      _finish(_errorMessage(e, 'Could not start the call'));
      if (callId != null) {
        try {
          await _repository.cancelCall(callId);
        } catch (_) {}
      }
    }
  }

  Future<void> acceptIncoming() async {
    final callId = _sessionId;
    final conversationId = _sessionConversationId;
    if (callId == null || conversationId == null || state.phase != CallPhase.incoming) return;
    await _tone.stop();
    _clearTimers();
    _setPhase(CallPhase.connecting);

    final MediaStream stream;
    try {
      stream = await WebRtcCallService.getCallMedia(video: state.isVideo);
    } catch (e) {
      _finish(_errorMessage(e, 'Could not access the microphone'));
      try {
        await _repository.rejectCall(callId);
      } catch (_) {}
      return;
    }
    state = state.copyWith(
      hasLocalVideo: stream.getVideoTracks().isNotEmpty,
      videoOn: stream.getVideoTracks().isNotEmpty,
    );

    try {
      // Be ready for the caller's offer before telling the server we accepted.
      await _webrtc.start(
        stream,
        iceServers: await _resolveIceServers(),
        onIceCandidate: (c) => _sendIce(callId, c),
      );
      await _applyDefaultAudioRoute(state.isVideo);
      await _connectCallSocket(conversationId);
      final updated = await _repository.acceptCall(callId);
      if (updated.iceServers.isNotEmpty && _sessionIce.isEmpty) _sessionIce = updated.iceServers;
      if (updated.callerId != 0) _sessionCallerId = updated.callerId;
      _addTimer(_connectTimeout, () {
        if (state.phase != CallPhase.active) _endLocally('Could not connect the call');
      });
      final pending = _pendingOffer;
      _pendingOffer = null;
      if (pending != null) await _answerOffer(pending.sdp, pending.type);
    } catch (e) {
      _finish(_errorMessage(e, 'Could not join the call'));
      try {
        await _repository.rejectCall(callId);
      } catch (_) {}
    }
  }

  Future<void> rejectIncoming() => _endLocally('Call declined');

  Future<void> hangup() => _endLocally('Call ended');

  void toggleMic() {
    final next = !state.micOn;
    _webrtc.setMicrophoneEnabled(next);
    state = state.copyWith(micOn: next);
  }

  void toggleVideo() {
    if (!state.hasLocalVideo) return;
    final next = !state.videoOn;
    _webrtc.setVideoEnabled(next);
    state = state.copyWith(videoOn: next);
  }

  Future<void> toggleSpeaker() async {
    final next = !state.speakerOn;
    await _webrtc.setSpeakerphone(next);
    if (mounted) state = state.copyWith(speakerOn: next);
  }

  Future<void> switchCamera() async {
    try {
      await _webrtc.switchCamera();
    } catch (_) {
      // Keep the current camera.
    }
  }

  void reset() {
    if (state.phase == CallPhase.ended) state = const CallState();
  }

  @override
  void dispose() {
    _signalingSub.cancel();
    _signalClosedSub.cancel();
    _inboxSub.cancel();
    _remoteSub.cancel();
    _connectionSub.cancel();
    _endedTimer?.cancel();
    _clearTimers();
    _tone.stop();
    _webrtc.close();
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
    () => ref.read(authControllerProvider).user?.id,
  );
});
