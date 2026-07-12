import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/storage/local_storage.dart';
import '../../../repositories/notification_repository.dart';
import '../../notifications/services/firebase_bootstrap.dart';
import '../../notifications/services/push_debug_log.dart';

class PushNotificationService {
  PushNotificationService({
    required NotificationRepository repository,
    required LocalStorage storage,
    LocalNotificationServiceDelegate? localNotifications,
  })  : _repository = repository,
        _storage = storage,
        _localNotifications = localNotifications ?? LocalNotificationServiceDelegate();

  final NotificationRepository _repository;
  final LocalStorage _storage;
  final LocalNotificationServiceDelegate _localNotifications;
  FirebaseApp? _firebaseApp;

  Future<PushStatus> getStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const PushStatus.unsupported();
    }

    try {
      final config = await _repository.getConfig(platform: _platformName());
      final permission = await _resolvePermission();
      final enabled = _storage.pushEnabled &&
          permission == PushPermissionState.granted &&
          (_storage.pushToken?.isNotEmpty ?? false);

      return PushStatus(
        supported: true,
        configured: config.isConfigured,
        permission: permission,
        enabled: enabled,
      );
    } catch (e) {
      PushDebugLog.error('Push status check failed', e);
      return PushStatus(
        supported: true,
        configured: false,
        permission: PushPermissionState.notDetermined,
        enabled: false,
      );
    }
  }

  Future<void> register() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw Exception('Push notifications are not supported on this device.');
    }

    final config = await _repository.getConfig(platform: _platformName());
    if (!config.isConfigured || config.firebase == null) {
      throw Exception(
        'Push is not configured yet. Ask an admin to enable Firebase and add the '
        '${Platform.isIOS ? "iOS" : "Android"} app ID in integration settings.',
      );
    }

    await _ensureFirebase(config.firebase!);
    await _localNotifications.ensureAndroidPermission();

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      throw Exception('Notification permission was denied.');
    }

    if (Platform.isAndroid) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain an FCM device token.');
    }

    PushDebugLog.info('FCM token obtained (${token.substring(0, 12)}…)');

    await _repository.registerDeviceToken(
      token: token,
      platform: _platformName(),
    );

    _storage.pushToken = token;
    _storage.pushEnabled = true;
    PushDebugLog.info('Device token registered with backend');
  }

  Future<void> unregister() async {
    final token = _storage.pushToken;
    if (token != null && token.isNotEmpty) {
      await _repository.unregisterDeviceToken(token);
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {
      // Token may already be invalid locally.
    }

    _storage.pushToken = null;
    _storage.pushEnabled = false;
    PushDebugLog.info('Push notifications disabled');
  }

  Future<void> syncIfEnabled() async {
    if (!_storage.pushEnabled) return;
    try {
      await register();
    } catch (e) {
      PushDebugLog.warn('Silent push sync failed: $e');
    }
  }

  Future<void> ensureMessagingReady() async {
    if (Firebase.apps.isNotEmpty) return;
    if (!_storage.pushEnabled) return;
    try {
      final cached = _storage.firebaseOptions;
      if (cached != null && cached.isComplete) {
        await _ensureFirebase(cached);
        return;
      }
      final config = await _repository.getConfig(platform: _platformName());
      if (config.firebase != null) {
        await _ensureFirebase(config.firebase!);
      }
    } catch (e) {
      PushDebugLog.warn('ensureMessagingReady failed: $e');
    }
  }

  Future<PushPermissionState> _resolvePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PushPermissionState.unsupported;
    }

    if (Platform.isAndroid) {
      final granted = await _localNotifications.androidPermissionGranted();
      if (!granted) return PushPermissionState.denied;
    }

    if (Firebase.apps.isEmpty) {
      return PushPermissionState.notDetermined;
    }

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        PushPermissionState.granted,
      AuthorizationStatus.denied => PushPermissionState.denied,
      AuthorizationStatus.notDetermined => PushPermissionState.notDetermined,
    };
  }

  Future<void> _ensureFirebase(FirebasePublicConfig config) async {
    if (_firebaseApp != null || Firebase.apps.isNotEmpty) return;

    _firebaseApp = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config.apiKey,
        appId: config.appId,
        messagingSenderId: config.messagingSenderId,
        projectId: config.projectId,
        authDomain: config.authDomain.isNotEmpty ? config.authDomain : null,
      ),
    );
    await FirebaseBootstrap.cacheOptions(_storage, config);
    PushDebugLog.info('Firebase messaging ready');
  }

  String _platformName() => Platform.isIOS ? 'ios' : 'android';
}

/// Thin wrapper so push service can request Android permissions without a circular import.
class LocalNotificationServiceDelegate {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> ensureAndroidPermission() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    PushDebugLog.info('Android POST_NOTIFICATIONS granted=$granted');
  }

  Future<bool> androidPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? false;
  }
}
