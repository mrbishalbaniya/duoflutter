import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_storage.dart';
import '../../../repositories/notification_repository.dart';
import '../data/notification_local_store.dart';
import '../domain/notification_item.dart';
import 'local_notification_service.dart';
import 'push_navigation_service.dart';
import 'push_payload_parser.dart';
import '../../settings/services/push_notification_service.dart';

typedef NotificationIngestCallback = Future<void> Function(NotificationItem item);

class PushMessagingCoordinator {
  PushMessagingCoordinator({
    required PushNotificationService pushService,
    required NotificationRepository repository,
    required LocalStorage storage,
    required NotificationLocalStore localStore,
    required LocalNotificationService localNotifications,
  })  : _pushService = pushService,
        _repository = repository,
        _storage = storage,
        _localStore = localStore,
        _localNotifications = localNotifications;

  final PushNotificationService _pushService;
  final NotificationRepository _repository;
  final LocalStorage _storage;
  final NotificationLocalStore _localStore;
  final LocalNotificationService _localNotifications;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  NotificationIngestCallback? _onIngest;
  GoRouter? _router;
  WidgetRef? _ref;
  bool _bound = false;

  void bind({
    required GoRouter router,
    required WidgetRef ref,
    required NotificationIngestCallback onIngest,
  }) {
    _router = router;
    _ref = ref;
    _onIngest = onIngest;
    if (_bound) return;
    _bound = true;
    unawaited(_initializeListeners());
  }

  void unbind() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _tokenRefreshSub?.cancel();
    _bound = false;
  }

  Future<void> _initializeListeners() async {
    await _pushService.ensureMessagingReady();
    if (Firebase.apps.isEmpty) return;

    await _localNotifications.initialize(
      onNotificationTap: _handleLocalNotificationTap,
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (!_storage.pushEnabled) return;
      try {
        await _repository.registerDeviceToken(token: token, platform: 'android');
        _storage.pushToken = token;
      } catch (_) {}
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await _ingestAndNavigate(initial, markRead: true);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final parsed = PushPayloadParser.parse(message);
    final item = await _ingest(parsed);

    await _localNotifications.showPushNotification(
      display: ParsedPushDisplay(
        notificationId: item.id.hashCode,
        type: parsed.type,
        title: parsed.title,
        body: parsed.body,
        deepLink: parsed.deepLink,
        imageUrl: parsed.imageUrl,
        iconUrl: parsed.iconUrl,
      ),
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    await _ingestAndNavigate(message, markRead: true);
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final router = _router;
    final ref = _ref;
    if (router == null || ref == null) return;
    PushNavigationService.navigateFromDeepLink(
      router: router,
      ref: ref,
      deepLink: payload,
    );
  }

  Future<void> _ingestAndNavigate(RemoteMessage message, {required bool markRead}) async {
    final parsed = PushPayloadParser.parse(message);
    final item = await _ingest(parsed, markRead: markRead);

    final router = _router;
    final ref = _ref;
    if (router == null || ref == null) return;

    PushNavigationService.navigateFromDeepLink(
      router: router,
      ref: ref,
      deepLink: item.deepLink,
    );
  }

  Future<NotificationItem> _ingest(
    ParsedPushPayload parsed, {
    bool markRead = false,
  }) async {
    final item = parsed.toItem(isRead: markRead);
    await _localStore.upsert(item);
    await _onIngest?.call(item);
    return item;
  }

  /// Called from background isolate via [firebaseMessagingBackgroundHandler].
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (kIsWeb) return;
    final storage = LocalStorage();
    await storage.init();
    final box = await Hive.openBox<dynamic>(NotificationLocalStore.boxName);
    final store = NotificationLocalStore(box);
    final parsed = PushPayloadParser.parse(message);
    await store.upsert(parsed.toItem());

    final local = LocalNotificationService();
    await local.initialize(onNotificationTap: (_) {});
    await local.showPushNotification(
      display: ParsedPushDisplay(
        notificationId: parsed.id.hashCode,
        type: parsed.type,
        title: parsed.title,
        body: parsed.body,
        deepLink: parsed.deepLink,
        imageUrl: parsed.imageUrl,
        iconUrl: parsed.iconUrl,
      ),
    );
  }
}
