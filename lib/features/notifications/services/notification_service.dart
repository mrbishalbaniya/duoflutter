import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/storage/local_storage.dart';
import '../../../repositories/notification_repository.dart';
import '../../chat/providers/chat_thread_controller.dart';
import '../../settings/services/push_notification_service.dart';
import '../data/notification_local_store.dart';
import '../domain/notification_item.dart';
import '../domain/notification_tap_payload.dart';
import 'firebase_bootstrap.dart';
import 'local_notification_service.dart';
import 'notification_router.dart';
import 'push_debug_log.dart';
import 'push_payload_parser.dart';

typedef NotificationIngestCallback = Future<void> Function(NotificationItem item);

/// Production coordinator for FCM + local notifications + deep links + reply.
///
/// Prefer this over calling [LocalNotificationService] / [PushPayloadParser] directly.
class NotificationService {
  NotificationService({
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
  final Set<String> _recentMessageIds = {};

  /// Backward-compatible alias used by existing bridges.
  void bind({
    required GoRouter router,
    required WidgetRef ref,
    required NotificationIngestCallback onIngest,
  }) {
    _router = router;
    _ref = ref;
    _onIngest = onIngest;
    unawaited(reinitialize());
  }

  void unbind() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
  }

  Future<void> reinitialize() async {
    await _pushService.ensureMessagingReady();
    if (Firebase.apps.isEmpty) {
      PushDebugLog.warn('Skipping FCM listeners — Firebase not initialized');
      return;
    }

    unbind();

    await _localNotifications.initialize(onInteraction: _handleInteraction);

    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (!_storage.pushEnabled) return;
      try {
        await _repository.registerDeviceToken(
          token: token,
          platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        );
        _storage.pushToken = token;
        PushDebugLog.info('FCM token refreshed and re-registered');
      } catch (e) {
        PushDebugLog.error('Token refresh registration failed', e);
      }
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      PushDebugLog.info('App opened from terminated FCM notification');
      await _ingestAndNavigate(initial, markRead: true);
    }

    await _handleLocalLaunchTap();
    await _handlePendingTapPayload();
    await _syncBadge();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_isDuplicateMessage(message)) return;
    PushDebugLog.info('Foreground FCM received (type=${message.data['type']})');
    final parsed = PushPayloadParser.parse(message);
    final item = await _ingest(parsed);

    await _localNotifications.showPushNotification(
      display: ParsedPushDisplay(
        notificationId: _stableId(item.id),
        type: parsed.type,
        title: parsed.title,
        body: parsed.body,
        deepLink: parsed.deepLink,
        imageUrl: parsed.imageUrl,
        iconUrl: parsed.iconUrl,
        tag: parsed.tag,
        conversationId: parsed.conversationId,
        notificationKey: parsed.id,
        playSound: parsed.playSound,
      ),
    );
    await _syncBadge();
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    PushDebugLog.info('FCM notification opened from background');
    await _ingestAndNavigate(message, markRead: true);
  }

  void _handleInteraction(
    NotificationTapPayload payload, {
    String? actionId,
    String? input,
  }) {
    PushDebugLog.info(
      'Notification interaction action=$actionId type=${payload.type.value}',
    );

    if (actionId == NotificationActionIds.reply &&
        input != null &&
        input.isNotEmpty &&
        payload.conversationId.isNotEmpty) {
      _refreshOpenChat(payload.conversationId);
      return;
    }

    if (actionId == NotificationActionIds.openLikes) {
      unawaited(
        _navigate(
          const NotificationTapPayload(
            deepLink: '/discover?tab=likes-you',
            type: DuoNotificationType.profileLike,
          ),
        ),
      );
      return;
    }

    if (actionId == NotificationActionIds.openUpdate ||
        payload.type == DuoNotificationType.updateAvailable) {
      unawaited(
        _navigate(
          NotificationTapPayload(
            deepLink: AppRoutes.update,
            type: DuoNotificationType.updateAvailable,
            notificationId: payload.notificationId,
          ),
        ),
      );
      return;
    }

    unawaited(_navigate(payload));
  }

  Future<void> _ingestAndNavigate(RemoteMessage message, {required bool markRead}) async {
    final parsed = PushPayloadParser.parse(message);
    final item = await _ingest(parsed, markRead: markRead);
    await _navigate(
      NotificationTapPayload(
        deepLink: item.deepLink,
        type: item.type,
        conversationId: parsed.conversationId,
        notificationId: item.id,
      ),
    );
  }

  Future<void> _navigate(NotificationTapPayload payload) async {
    final router = _router;
    final ref = _ref;
    if (router == null || ref == null) {
      await _storage.setPendingNotificationTapPayload(payload.encode());
      PushDebugLog.warn('Router not bound — queued pending tap payload');
      return;
    }

    if (payload.notificationId.isNotEmpty) {
      await _localStore.markRead(payload.notificationId);
      await _syncBadge();
    }

    await NotificationRouter.navigate(router: router, ref: ref, payload: payload);
    await _syncBadge();
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

  Future<void> _handleLocalLaunchTap() async {
    final launch = await _localNotifications.getLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null && payload.isNotEmpty) {
      PushDebugLog.info('App launched from local notification tap');
      _handleInteraction(NotificationTapPayload.decode(payload));
    }
  }

  Future<void> _handlePendingTapPayload() async {
    final payload = _storage.pendingNotificationTapPayload;
    if (payload == null || payload.isEmpty) return;
    await _storage.setPendingNotificationTapPayload(null);
    PushDebugLog.info('Processing pending notification tap payload');
    _handleInteraction(NotificationTapPayload.decode(payload));
  }

  void _refreshOpenChat(String conversationId) {
    final ref = _ref;
    if (ref == null) return;
    try {
      ref.invalidate(chatThreadControllerProvider(conversationId));
      PushDebugLog.info('Invalidated chat after inline reply: $conversationId');
    } catch (e) {
      PushDebugLog.error('Failed to refresh chat after reply', e);
    }
  }

  bool _isDuplicateMessage(RemoteMessage message) {
    final id = message.messageId ??
        '${message.data['tag']}_${message.data['type']}_${message.data['conversation_id']}';
    if (id.isEmpty) return false;
    if (_recentMessageIds.contains(id)) {
      PushDebugLog.info('Dropping duplicate FCM message $id');
      return true;
    }
    _recentMessageIds.add(id);
    if (_recentMessageIds.length > 80) {
      _recentMessageIds.remove(_recentMessageIds.first);
    }
    return false;
  }

  int _stableId(String key) {
    // Stable positive 31-bit id for Android notify id.
    return key.hashCode & 0x7fffffff;
  }

  Future<void> _syncBadge() async {
    final unread = _localStore.unreadCount(_localStore.loadAll());
    await _localNotifications.setBadgeCount(unread);
  }

  /// Local "Update Available" notification (deduped by version+build).
  Future<void> showUpdateAvailableNotification({
    required String version,
    required int buildNumber,
    required bool forceUpdate,
  }) async {
    final identity = '$version+$buildNumber';
    if (_storage.lastNotifiedUpdateVersion == identity) {
      PushDebugLog.info('Skipping update notification — already notified for $identity');
      return;
    }

    await _localNotifications.initialize(onInteraction: _handleInteraction);
    await _localNotifications.showPushNotification(
      display: ParsedPushDisplay(
        notificationId: _stableId('update_$identity'),
        type: DuoNotificationType.updateAvailable,
        title: 'Update Available',
        body: forceUpdate
            ? 'A required update is available. Update now to continue using Duo.'
            : 'A new version of the app is available. Update now for the latest improvements and fixes.',
        deepLink: AppRoutes.update,
        tag: 'update_available',
        notificationKey: 'update_$identity',
      ),
    );
    await _storage.setLastNotifiedUpdateVersion(identity);
    PushDebugLog.info('Update available notification shown for $identity');
  }

  /// Background isolate entry.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (kIsWeb) return;
    PushDebugLog.info('Background FCM received (type=${message.data['type']})');

    await FirebaseBootstrap.ensureInitialized();
    final storage = LocalStorage();
    await storage.init();
    final box = await Hive.openBox<dynamic>(NotificationLocalStore.boxName);
    final store = NotificationLocalStore(box);
    final parsed = PushPayloadParser.parse(message);
    await store.upsert(parsed.toItem());

    final local = LocalNotificationService();
    await local.initialize(onInteraction: (_, {actionId, input}) {});
    await local.showPushNotification(
      display: ParsedPushDisplay(
        notificationId: parsed.id.hashCode & 0x7fffffff,
        type: parsed.type,
        title: parsed.title,
        body: parsed.body,
        deepLink: parsed.deepLink,
        imageUrl: parsed.imageUrl,
        iconUrl: parsed.iconUrl,
        tag: parsed.tag,
        conversationId: parsed.conversationId,
        notificationKey: parsed.id,
        playSound: parsed.playSound,
      ),
    );
    PushDebugLog.info('Background local notification shown');
  }
}

/// Legacy name retained for existing imports / providers.
typedef PushMessagingCoordinator = NotificationService;
