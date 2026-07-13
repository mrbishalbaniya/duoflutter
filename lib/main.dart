import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'core/lifecycle/app_lifecycle_service.dart';
import 'features/notifications/services/push_background_handler.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await bootstrap();
  runApp(
    const ProviderScope(
      child: AppLifecycleBridge(
        child: DuoApp(),
      ),
    ),
  );
}
