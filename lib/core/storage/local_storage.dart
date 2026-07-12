import 'package:hive_flutter/hive_flutter.dart';

import '../models/notification_models.dart';
import '../../features/notifications/data/notification_local_store.dart';

class LocalStorage {
  static const _settingsBox = 'settings';
  static const _cacheBox = 'cache';
  static const chatCacheBoxName = 'chat_cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<dynamic>(_cacheBox);
    await Hive.openBox<dynamic>(chatCacheBoxName);
    await Hive.openBox<dynamic>(NotificationLocalStore.boxName);
  }

  Box<dynamic> get settings => Hive.box<dynamic>(_settingsBox);
  Box<dynamic> get cache => Hive.box<dynamic>(_cacheBox);
  Box<dynamic> get chatCache => Hive.box<dynamic>(chatCacheBoxName);
  Box<dynamic> get notificationInbox => Hive.box<dynamic>(NotificationLocalStore.boxName);

  static const _themeKey = 'duo_theme';
  static const _pushEnabledKey = 'duo_push_enabled';
  static const _pushTokenKey = 'duo_push_token';
  static const _pendingNotificationTapKey = 'duo_pending_notification_tap';
  static const _firebaseOptionsKey = 'duo_firebase_options';

  String get themeMode {
    final stored = settings.get(_themeKey) ?? settings.get('theme_mode');
    if (stored == 'light' || stored == 'dark' || stored == 'system') {
      return stored as String;
    }
    return 'dark';
  }

  set themeMode(String value) => settings.put(_themeKey, value);

  bool get pushEnabled => settings.get(_pushEnabledKey) == true;

  set pushEnabled(bool value) => settings.put(_pushEnabledKey, value);

  String? get pushToken => settings.get(_pushTokenKey) as String?;

  set pushToken(String? value) {
    if (value == null || value.isEmpty) {
      settings.delete(_pushTokenKey);
    } else {
      settings.put(_pushTokenKey, value);
    }
  }

  FirebasePublicConfig? get firebaseOptions {
    final raw = settings.get(_firebaseOptionsKey);
    if (raw is! Map) return null;
    return FirebasePublicConfig.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> setFirebaseOptions(FirebasePublicConfig config) async {
    await settings.put(_firebaseOptionsKey, {
      'apiKey': config.apiKey,
      'authDomain': config.authDomain,
      'projectId': config.projectId,
      'messagingSenderId': config.messagingSenderId,
      'appId': config.appId,
    });
  }

  String? get pendingNotificationTapPayload =>
      settings.get(_pendingNotificationTapKey) as String?;

  Future<void> setPendingNotificationTapPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      await settings.delete(_pendingNotificationTapKey);
    } else {
      await settings.put(_pendingNotificationTapKey, payload);
    }
  }
}
