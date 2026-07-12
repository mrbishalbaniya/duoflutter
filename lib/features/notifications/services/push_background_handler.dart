import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_messaging_coordinator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  try {
    if (Firebase.apps.isEmpty) {
      // Firebase may not be initialized in background isolate; local store still works.
    }
    await PushMessagingCoordinator.handleBackgroundMessage(message);
  } catch (e) {
    debugPrint('Background FCM handler failed: $e');
  }
}
