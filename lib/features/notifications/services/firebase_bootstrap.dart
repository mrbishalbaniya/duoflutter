import 'package:firebase_core/firebase_core.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/storage/local_storage.dart';
import 'push_debug_log.dart';

/// Initializes Firebase in any isolate (main, background, or after cold start).
class FirebaseBootstrap {
  static Future<FirebaseApp?> ensureInitialized({LocalStorage? storage}) async {
    if (Firebase.apps.isNotEmpty) {
      PushDebugLog.info('Firebase already initialized');
      return Firebase.app();
    }

    final resolvedStorage = storage ?? LocalStorage();
    await resolvedStorage.init();

    final cached = resolvedStorage.firebaseOptions;
    if (cached == null || !cached.isComplete) {
      PushDebugLog.warn('Firebase options not cached — push not initialized yet');
      return null;
    }

    try {
      final app = await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: cached.apiKey,
          appId: cached.appId,
          messagingSenderId: cached.messagingSenderId,
          projectId: cached.projectId,
          authDomain: cached.authDomain.isNotEmpty ? cached.authDomain : null,
        ),
      );
      PushDebugLog.info('Firebase initialized (project=${cached.projectId})');
      return app;
    } catch (e) {
      PushDebugLog.error('Firebase initialization failed', e);
      return null;
    }
  }

  static Future<void> cacheOptions(
    LocalStorage storage,
    FirebasePublicConfig config,
  ) async {
    await storage.setFirebaseOptions(config);
    PushDebugLog.info('Cached Firebase options for background delivery');
  }
}
