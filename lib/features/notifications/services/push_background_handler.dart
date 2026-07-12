import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'firebase_bootstrap.dart';
import 'push_debug_log.dart';
import 'push_messaging_coordinator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseBootstrap.ensureInitialized();
    await PushMessagingCoordinator.handleBackgroundMessage(message);
  } catch (e, stack) {
    PushDebugLog.error('Background FCM handler failed', '$e\n$stack');
  }
}
