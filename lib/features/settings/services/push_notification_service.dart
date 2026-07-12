import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/storage/local_storage.dart';
import '../../../repositories/notification_repository.dart';

class PushNotificationService {
  PushNotificationService({
    required NotificationRepository repository,
    required LocalStorage storage,
  })  : _repository = repository,
        _storage = storage;

  final NotificationRepository _repository;
  final LocalStorage _storage;
  FirebaseApp? _firebaseApp;

  Future<PushStatus> getStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const PushStatus.unsupported();
    }

    try {
      final config = await _repository.getConfig();
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
    } catch (_) {
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

    final config = await _repository.getConfig();
    if (!config.isConfigured || config.firebase == null) {
      throw Exception(
        'Push is not configured yet. Ask an admin to enable Firebase in integration settings.',
      );
    }

    await _ensureFirebase(config.firebase!);
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) {
      throw Exception('Notification permission was denied.');
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain an FCM device token.');
    }

    await _repository.registerDeviceToken(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );

    _storage.pushToken = token;
    _storage.pushEnabled = true;
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
  }

  Future<void> syncIfEnabled() async {
    if (!_storage.pushEnabled) return;
    try {
      await register();
    } catch (_) {
      // Silent sync on login — user can retry from Settings.
    }
  }

  Future<PushPermissionState> _resolvePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PushPermissionState.unsupported;
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
  }
}
