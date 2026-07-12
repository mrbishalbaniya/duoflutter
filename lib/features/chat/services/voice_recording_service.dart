import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

enum MicrophonePermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;
  bool _paused = false;

  String? get recordingPath => _path;

  bool get isPaused => _paused;

  static Future<MicrophonePermissionResult> ensureMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return MicrophonePermissionResult.granted;
    status = await Permission.microphone.request();
    if (status.isGranted) return MicrophonePermissionResult.granted;
    if (status.isPermanentlyDenied) {
      return MicrophonePermissionResult.permanentlyDenied;
    }
    return MicrophonePermissionResult.denied;
  }

  static Future<void> openSettings() => openAppSettings();

  Future<bool> get isRecording => _recorder.isRecording();

  Future<String?> start() async {
    if (await _recorder.isRecording()) return _path;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _path = path;
    _paused = false;
    return path;
  }

  Future<void> pause() async {
    if (await _recorder.isRecording()) {
      await _recorder.pause();
      _paused = true;
    }
  }

  Future<void> resume() async {
    if (_paused) {
      await _recorder.resume();
      _paused = false;
    }
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    _paused = false;
    return path ?? _path;
  }

  Future<void> cancel() async {
    try {
      if (await _recorder.isRecording() || _paused) {
        await _recorder.stop();
      }
    } catch (_) {}

    final path = _path;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _path = null;
    _paused = false;
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
