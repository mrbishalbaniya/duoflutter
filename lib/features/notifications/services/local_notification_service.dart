import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/storage/local_storage.dart';
import '../domain/notification_item.dart';
import 'push_debug_log.dart';

class LocalNotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const androidChatChannel = AndroidNotificationChannel(
    'duo_chat',
    'Chat Messages',
    description: 'New messages from your matches',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const androidMatchChannel = AndroidNotificationChannel(
    'duo_matches',
    'New Matches',
    description: 'When you match with someone new',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const androidLikeChannel = AndroidNotificationChannel(
    'duo_likes',
    'Likes',
    description: 'When someone likes your profile',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize({
    required void Function(String? payload) onNotificationTap,
  }) async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _backgroundTapHandler,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(androidChatChannel);
      await android?.createNotificationChannel(androidMatchChannel);
      await android?.createNotificationChannel(androidLikeChannel);
      PushDebugLog.info('Android notification channels created');
    }

    _initialized = true;
    PushDebugLog.info('Local notifications initialized');
  }

  @pragma('vm:entry-point')
  static void _backgroundTapHandler(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_storePendingPayload(payload));
  }

  @pragma('vm:entry-point')
  static Future<void> _storePendingPayload(String payload) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final storage = LocalStorage();
      await storage.init();
      await storage.setPendingNotificationTapPayload(payload);
      PushDebugLog.info('Stored pending notification tap payload');
    } catch (e) {
      PushDebugLog.error('Failed to store pending tap payload', e);
    }
  }

  Future<NotificationAppLaunchDetails?> getLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }

  Future<void> showPushNotification({
    required ParsedPushDisplay display,
  }) async {
    if (!_initialized) {
      PushDebugLog.warn('Local notifications not initialized — skipping show()');
      return;
    }

    final channel = _channelFor(display.type);
    final actions = _actionsFor(display.type);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: display.type == DuoNotificationType.newMatch
          ? Priority.max
          : Priority.high,
      icon: '@drawable/ic_notification',
      color: const Color(0xFFB83280),
      groupKey: 'duo_${display.type.value}',
      styleInformation: BigTextStyleInformation(
        display.body,
        contentTitle: display.title,
        summaryText: display.type.label,
      ),
      actions: actions,
      ticker: display.title,
      visibility: NotificationVisibility.public,
      category: display.type == DuoNotificationType.chatMessage
          ? AndroidNotificationCategory.message
          : AndroidNotificationCategory.social,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      tag: display.tag.isNotEmpty ? display.tag : display.type.value,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: display.type.label,
      threadIdentifier: display.type.value,
    );

    await _plugin.show(
      id: display.notificationId,
      title: display.title,
      body: display.body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: display.deepLink,
    );
    PushDebugLog.info('Notification shown in system tray (${display.type.value})');
  }

  AndroidNotificationChannel _channelFor(DuoNotificationType type) {
    return switch (type) {
      DuoNotificationType.chatMessage => androidChatChannel,
      DuoNotificationType.newMatch => androidMatchChannel,
      DuoNotificationType.profileLike => androidLikeChannel,
      DuoNotificationType.unknown => androidChatChannel,
    };
  }

  List<AndroidNotificationAction> _actionsFor(DuoNotificationType type) {
    return switch (type) {
      DuoNotificationType.chatMessage => [
          const AndroidNotificationAction('open_chat', 'Reply'),
        ],
      DuoNotificationType.newMatch => [
          const AndroidNotificationAction('open_chat', 'Start Chatting'),
        ],
      DuoNotificationType.profileLike => [
          const AndroidNotificationAction('open_likes', 'See who'),
        ],
      DuoNotificationType.unknown => const [],
    };
  }
}

class ParsedPushDisplay {
  const ParsedPushDisplay({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.deepLink,
    this.imageUrl = '',
    this.iconUrl = '',
    this.tag = '',
  });

  final int notificationId;
  final DuoNotificationType type;
  final String title;
  final String body;
  final String deepLink;
  final String imageUrl;
  final String iconUrl;
  final String tag;
}
