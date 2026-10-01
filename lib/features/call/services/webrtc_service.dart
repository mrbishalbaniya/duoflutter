import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown when the mic/camera cannot be used; [message] is user-facing.
class MediaPermissionException implements Exception {
  const MediaPermissionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Port of DuoFrontend `lib/call/webrtc.ts` (`getCallMedia` + `WebRtcPeer`).
class WebRtcCallService {
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingCandidates = [];

  final _remoteController = StreamController<MediaStream?>.broadcast();
  final _connectionController = StreamController<RTCPeerConnectionState>.broadcast();

  Stream<MediaStream?> get remoteStream => _remoteController.stream;
  Stream<RTCPeerConnectionState> get connectionState => _connectionController.stream;
  MediaStream? get localStream => _localStream;
  MediaStream? get currentRemoteStream => _remoteStream;
  bool get isStarted => _peer != null;

  bool _speakerOn = false;
  bool get isSpeakerOn => _speakerOn;

  /// Ask for mic (and camera) with a clear error when blocked; a video call with
  /// no usable camera falls back to audio so the call still works (web parity).
  static Future<MediaStream> getCallMedia({required bool video}) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw MediaPermissionException(
        mic.isPermanentlyDenied
            ? 'Microphone access is blocked. Allow it in app settings.'
            : 'Microphone permission is needed for calls.',
      );
    }
    var wantVideo = video;
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) wantVideo = false; // audio-only fallback
    }
    const audio = {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    };
    try {
      return await navigator.mediaDevices.getUserMedia({
        'audio': audio,
        'video': wantVideo
            ? {
                'facingMode': 'user',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      });
    } catch (_) {
      if (wantVideo) {
        try {
          return await navigator.mediaDevices.getUserMedia({'audio': audio, 'video': false});
        } catch (_) {}
      }
      throw const MediaPermissionException('Could not access the microphone or camera.');
    }
  }

  /// Create the peer connection using an already-acquired local stream.
  Future<void> start(
    MediaStream local, {
    required List<Map<String, dynamic>> iceServers,
    required void Function(RTCIceCandidate candidate) onIceCandidate,
  }) async {
    await _closeConnection();
    _localStream = local;
    final servers = iceServers.isNotEmpty
        ? iceServers
        : [
            {'urls': 'stun:stun.l.google.com:19302'},
            {'urls': 'stun:stun1.l.google.com:19302'},
          ];
    final peer = await createPeerConnection({
      'iceServers': servers,
      'sdpSemantics': 'unified-plan',
    });
    _peer = peer;

    peer.onIceCandidate = (c) {
      if ((c.candidate ?? '').isNotEmpty) onIceCandidate(c);
    };
    peer.onTrack = (event) async {
      var remote = _remoteStream;
      if (event.streams.isNotEmpty) {
        remote = event.streams.first;
      } else {
        remote ??= await createLocalMediaStream('remote');
        await remote.addTrack(event.track);
      }
      _remoteStream = remote;
      _remoteController.add(remote);
    };
    peer.onConnectionState = (state) {
      if (identical(_peer, peer)) _connectionController.add(state);
    };

    for (final track in local.getTracks()) {
      await peer.addTrack(track, local);
    }
    // Always negotiate audio+video so either side can show video.
    final kinds = local.getTracks().map((t) => t.kind).toSet();
    if (!kinds.contains('audio')) {
      await peer.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }
    if (!kinds.contains('video')) {
      await peer.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final peer = _requirePeer();
    final offer = await peer.createOffer();
    await peer.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> applyOffer(String sdp, String type) async {
    final peer = _requirePeer();
    await peer.setRemoteDescription(RTCSessionDescription(sdp, type));
    await _flushCandidates();
    final answer = await peer.createAnswer();
    await peer.setLocalDescription(answer);
    return answer;
  }

  Future<void> applyAnswer(String sdp, String type) async {
    final peer = _requirePeer();
    final state = await peer.getSignalingState();
    if (state != RTCSignalingState.RTCSignalingStateHaveLocalOffer) return;
    await peer.setRemoteDescription(RTCSessionDescription(sdp, type));
    await _flushCandidates();
  }

  /// Candidates that arrive before the remote description are queued (they were
  /// previously dropped, which is the usual reason calls never connected).
  Future<void> addIceCandidate(Map<String, dynamic> raw) async {
    final text = '${raw['candidate'] ?? ''}';
    if (text.isEmpty) return;
    final mline = raw['sdpMLineIndex'] ?? raw['sdp_mline_index'];
    final candidate = RTCIceCandidate(
      text,
      (raw['sdpMid'] ?? raw['sdp_mid']) as String?,
      mline is int ? mline : int.tryParse('$mline'),
    );
    final peer = _peer;
    if (peer == null || await peer.getRemoteDescription() == null) {
      _pendingCandidates.add(candidate);
      return;
    }
    try {
      await peer.addCandidate(candidate);
    } catch (_) {
      // Stale or duplicate candidate; safe to ignore.
    }
  }

  Future<void> _flushCandidates() async {
    final queued = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in queued) {
      try {
        await _peer?.addCandidate(c);
      } catch (_) {}
    }
  }

  RTCPeerConnection _requirePeer() {
    final peer = _peer;
    if (peer == null) throw StateError('Peer not started');
    return peer;
  }

  void setMicrophoneEnabled(bool enabled) {
    for (final t in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = enabled;
    }
  }

  void setVideoEnabled(bool enabled) {
    for (final t in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = enabled;
    }
  }

  bool get hasLocalVideo => (_localStream?.getVideoTracks().isNotEmpty ?? false);

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> setSpeakerphone(bool enabled) async {
    _speakerOn = enabled;
    try {
      await Helper.setSpeakerphoneOn(enabled);
    } catch (_) {}
  }

  Future<void> _closeConnection() async {
    _pendingCandidates.clear();
    final peer = _peer;
    _peer = null;
    if (peer != null) {
      peer.onIceCandidate = null;
      peer.onTrack = null;
      peer.onConnectionState = null;
      try {
        await peer.close();
      } catch (_) {}
    }
  }

  /// Stop all tracks and close the connection.
  Future<void> close() async {
    await _closeConnection();
    for (final t in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      try {
        await t.stop();
      } catch (_) {}
    }
    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    _remoteStream = null;
    _remoteController.add(null);
  }

  void closeControllers() {
    _remoteController.close();
    _connectionController.close();
  }
}
