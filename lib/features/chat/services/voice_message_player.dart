import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Ensures only one voice message plays at a time across the chat thread.
class VoiceMessagePlayer {
  VoiceMessagePlayer._() {
    _player.positionStream.listen((position) {
      if (_activeMessageId == null) return;
      final duration = _player.duration;
      if (duration == null || duration.inMilliseconds <= 0) return;
      _positionController.add(position);
    });
    _player.playerStateStream.listen((state) {
      if (_activeMessageId == null) return;
      _playingController.add(state.playing);
      activeMessageIdNotifier.value = _activeMessageId;
      if (state.processingState == ProcessingState.completed) {
        _playingController.add(false);
        _progressResetController.add(null);
      }
    });
  }

  static final VoiceMessagePlayer instance = VoiceMessagePlayer._();

  final AudioPlayer _player = AudioPlayer();
  String? _activeMessageId;
  final _positionController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _progressResetController = StreamController<void>.broadcast();
  final ValueNotifier<String?> activeMessageIdNotifier = ValueNotifier<String?>(null);

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<void> get progressResetStream => _progressResetController.stream;

  String? get activeMessageId => _activeMessageId;

  Future<void> toggle(String messageId, String audioUrl) async {
    if (_activeMessageId == messageId && _player.playing) {
      await _player.pause();
      return;
    }

    if (_activeMessageId != messageId) {
      await _player.stop();
      _activeMessageId = messageId;
      activeMessageIdNotifier.value = messageId;
      await _player.setUrl(audioUrl);
    }

    await _player.play();
  }

  Future<void> seek(String messageId, double progressFraction) async {
    if (_activeMessageId != messageId) return;
    final duration = _player.duration;
    if (duration == null || duration.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (duration.inMilliseconds * progressFraction.clamp(0, 1)).round(),
    );
    await _player.seek(target);
  }

  Future<void> stopIfActive(String messageId) async {
    if (_activeMessageId == messageId) {
      await _player.stop();
      _activeMessageId = null;
      activeMessageIdNotifier.value = null;
    }
  }
}
