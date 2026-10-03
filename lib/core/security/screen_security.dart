import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Blocks screenshots / screen recording while other members' profiles are
/// visible (Android FLAG_SECURE). Several holders can ask at once (a secure
/// route plus an open profile sheet); protection stays on until all release.
class ScreenSecurity {
  ScreenSecurity._();

  static const _channel = MethodChannel('duo/screen_security');
  static final Set<Object> _holders = {};
  static bool? _applied;

  static void acquire(Object holder) {
    _holders.add(holder);
    _apply();
  }

  static void release(Object holder) {
    _holders.remove(holder);
    _apply();
  }

  static void _apply() {
    final secure = _holders.isNotEmpty;
    if (_applied == secure || kIsWeb || !Platform.isAndroid) return;
    _applied = secure;
    _channel.invokeMethod<void>('setSecure', {'secure': secure}).catchError((Object e) {
      _applied = null; // retry on the next change
      debugPrint('ScreenSecurity: $e');
    });
  }
}
