import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef IceCandidateHandler = void Function(RTCIceCandidate candidate);

class WebRtcCallService {
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _remoteController = StreamController<MediaStream?>.broadcast();
  final _qualityController = StreamController<String>.broadcast();

  Stream<MediaStream?> get remoteStream => _remoteController.stream;
  Stream<String> get connectionQuality => _qualityController.stream;

  MediaStream? get localStream => _localStream;
  bool _videoEnabled = true;
  bool _audioEnabled = true;
  bool _speakerOn = true;

  Future<void> initialize({
    required List<Map<String, dynamic>> iceServers,
    required bool video,
    IceCandidateHandler? onIceCandidate,
  }) async {
    await dispose();
    final config = {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
    _peer = await createPeerConnection(config);
    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && onIceCandidate != null) {
        onIceCandidate(candidate);
      }
    };
    _peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteController.add(_remoteStream);
      }
    };
    _peer!.onConnectionState = (state) {
      _qualityController.add(state.name);
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video,
    });
    for (final track in _localStream!.getTracks()) {
      await _peer!.addTrack(track, _localStream!);
    }
    _videoEnabled = video;
    _audioEnabled = true;
  }

  Future<String> createOffer() async {
    final offer = await _peer!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 1});
    await _peer!.setLocalDescription(offer);
    return offer.sdp ?? '';
  }

  Future<String> createAnswer() async {
    final answer = await _peer!.createAnswer();
    await _peer!.setLocalDescription(answer);
    return answer.sdp ?? '';
  }

  Future<void> applyRemoteAnswer(String sdp, String type) async {
    await _peer!.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> applyRemoteOffer(String sdp, String type) async {
    await _peer!.setRemoteDescription(RTCSessionDescription(sdp, type));
  }

  Future<void> addIceCandidate(Map<String, dynamic> raw) async {
    final candidate = RTCIceCandidate(
      '${raw['candidate'] ?? ''}',
      (raw['sdpMid'] ?? raw['sdp_mid']) as String?,
      (raw['sdpMLineIndex'] ?? raw['sdp_mline_index']) as int?,
    );
    if ((candidate.candidate ?? '').isEmpty) return;
    await _peer?.addCandidate(candidate);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    _audioEnabled = enabled;
    for (final track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = enabled;
    }
  }

  Future<void> setVideoEnabled(bool enabled) async {
    _videoEnabled = enabled;
    for (final track in _localStream?.getVideoTracks() ?? []) {
      track.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    await Helper.switchCamera(_localStream!.getVideoTracks().first);
  }

  Future<void> setSpeakerphone(bool enabled) async {
    _speakerOn = enabled;
    await Helper.setSpeakerphoneOn(enabled);
  }

  bool get isVideoEnabled => _videoEnabled;
  bool get isAudioEnabled => _audioEnabled;
  bool get isSpeakerOn => _speakerOn;

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peer?.close();
    _localStream = null;
    _remoteStream = null;
    _peer = null;
  }

  void closeControllers() {
    _remoteController.close();
    _qualityController.close();
  }
}
