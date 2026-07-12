import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:screen_capture_event/screen_capture_event.dart';

import '../domain/chat_security_event_codes.dart';
import 'chat_debug_log.dart';

typedef SecurityEventCallback = void Function(String eventCode);

/// Platform screenshot / screen-recording detection for an open chat thread.
class ChatScreenCaptureService {
  ChatScreenCaptureService({required this.onSecurityEvent});

  final SecurityEventCallback onSecurityEvent;

  static const _debounce = Duration(seconds: 2);

  ScreenCaptureEvent? _listener;
  bool _watching = false;
  bool _recording = false;
  DateTime? _lastScreenshotAt;
  DateTime? _lastRecordingStartAt;
  DateTime? _lastRecordingStopAt;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void start({required bool notifyEnabled, required bool secureEnabled}) {
    if (!isSupported) {
      ChatDebugLog.screenCaptureUnsupported();
      return;
    }
    if (!notifyEnabled) {
      stopWatching();
      unawaited(setSecureMode(secureEnabled));
      return;
    }

    _listener ??= ScreenCaptureEvent();
    if (!_watching) {
      _listener!
        ..addScreenShotListener(_onScreenshot)
        ..addScreenRecordListener(_onScreenRecord);
      _listener!.watch();
      _watching = true;
      ChatDebugLog.screenCaptureWatching(enabled: true);
    }
    unawaited(setSecureMode(secureEnabled));
  }

  void stop() {
    stopWatching();
    unawaited(setSecureMode(false));
  }

  void stopWatching() {
    if (!_watching) return;
    _listener?.dispose();
    _listener = null;
    _watching = false;
    _recording = false;
    ChatDebugLog.screenCaptureWatching(enabled: false);
  }

  Future<void> setSecureMode(bool enabled) async {
    if (!Platform.isAndroid) return;
    final listener = _listener ?? ScreenCaptureEvent();
    try {
      await listener.preventAndroidScreenShot(enabled);
      ChatDebugLog.secureChatMode(enabled: enabled);
    } catch (error) {
      ChatDebugLog.screenCaptureError('secure_mode', '$error');
    }
  }

  void _onScreenshot(String? _) {
    if (!_shouldEmit(_lastScreenshotAt)) return;
    _lastScreenshotAt = DateTime.now();
    ChatDebugLog.screenshotDetected();
    onSecurityEvent(ChatSecurityEventCodes.screenshotTaken);
  }

  void _onScreenRecord(bool isRecording) {
    if (isRecording) {
      if (_recording) return;
      if (!_shouldEmit(_lastRecordingStartAt)) return;
      _recording = true;
      _lastRecordingStartAt = DateTime.now();
      ChatDebugLog.recordingStarted();
      onSecurityEvent(ChatSecurityEventCodes.recordingStarted);
      return;
    }

    if (!_recording) return;
    if (!_shouldEmit(_lastRecordingStopAt)) return;
    _recording = false;
    _lastRecordingStopAt = DateTime.now();
    ChatDebugLog.recordingStopped();
    onSecurityEvent(ChatSecurityEventCodes.recordingStopped);
  }

  bool _shouldEmit(DateTime? lastAt) {
    if (lastAt == null) return true;
    return DateTime.now().difference(lastAt) >= _debounce;
  }
}
