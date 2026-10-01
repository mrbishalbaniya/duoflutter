import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

enum CallTone { incoming, outgoing }

/// Port of DuoFrontend `lib/call/ringtone.ts`: the same synthesized tones, rendered
/// once to a small WAV (one full on/off period) and looped, so no audio assets
/// are needed. Best effort only — failures are silent.
class CallTonePlayer {
  AudioPlayer? _player;
  CallTone? _playing;

  Future<void> start(CallTone tone) async {
    if (_playing == tone) return;
    await stop();
    _playing = tone;
    try {
      final file = await _toneFile(tone);
      final player = AudioPlayer();
      _player = player;
      await player.setFilePath(file.path);
      await player.setLoopMode(LoopMode.one);
      if (_playing != tone) {
        await player.dispose();
        return;
      }
      if (tone == CallTone.incoming) HapticFeedback.heavyImpact();
      await player.play();
    } catch (_) {
      // Tones are optional.
    }
  }

  Future<void> stop() async {
    _playing = null;
    final player = _player;
    _player = null;
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }

  static final Map<CallTone, File> _cache = {};

  static Future<File> _toneFile(CallTone tone) async {
    final cached = _cache[tone];
    if (cached != null && cached.existsSync()) return cached;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/duo_call_${tone.name}.wav');
    await file.writeAsBytes(_render(tone), flush: true);
    return _cache[tone] = file;
  }

  /// incoming: two 0.35s beeps of 880+1320 Hz every 2s (vol 0.12)
  /// outgoing: one 1.2s beep of 440+480 Hz every 3.5s (vol 0.06)
  static Uint8List _render(CallTone tone) {
    const rate = 22050;
    final incoming = tone == CallTone.incoming;
    final period = incoming ? 2.0 : 3.5;
    final beeps = incoming
        ? const [(0.05, 0.35), (0.55, 0.35)]
        : const [(0.05, 1.2)];
    final freqs = incoming ? const [880.0, 1320.0] : const [440.0, 480.0];
    // Louder than the web's WebAudio gain: phone speakers are quieter.
    final volume = incoming ? 0.35 : 0.2;

    final samples = (rate * period).round();
    final pcm = Int16List(samples);
    for (final (start, length) in beeps) {
      final s0 = (start * rate).round();
      final n = (length * rate).round();
      for (var i = 0; i < n && s0 + i < samples; i++) {
        final t = i / rate;
        // 30ms attack / 50ms release like the web gain ramps.
        final env = math.min(1.0, math.min(t / 0.03, (length - t) / 0.05)).clamp(0.0, 1.0);
        var v = 0.0;
        for (final f in freqs) {
          v += math.sin(2 * math.pi * f * t);
        }
        pcm[s0 + i] = (v / freqs.length * env * volume * 32767).round().clamp(-32768, 32767);
      }
    }

    final data = pcm.buffer.asUint8List();
    final header = ByteData(44);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    header.setUint32(4, 36 + data.length, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, rate, Endian.little);
    header.setUint32(28, rate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    str(36, 'data');
    header.setUint32(40, data.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }
}
