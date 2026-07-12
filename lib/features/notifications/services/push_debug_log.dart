import 'package:flutter/foundation.dart';

/// Structured push notification logging for production debugging.
class PushDebugLog {
  static const _tag = '[DuoPush]';

  static void info(String message) {
    debugPrint('$_tag $message');
  }

  static void warn(String message) {
    debugPrint('$_tag WARN $message');
  }

  static void error(String message, [Object? error]) {
    if (error != null) {
      debugPrint('$_tag ERROR $message: $error');
    } else {
      debugPrint('$_tag ERROR $message');
    }
  }
}
