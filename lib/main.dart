import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'features/notifications/services/push_background_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await bootstrap();
  runApp(
    const ProviderScope(
      child: DuoApp(),
    ),
  );
}
