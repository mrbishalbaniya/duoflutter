import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/notification_item.dart';

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
  );

  static const androidMatchChannel = AndroidNotificationChannel(
    'duo_matches',
    'New Matches',
    description: 'When you match with someone new',
    importance: Importance.max,
    playSound: true,
  );

  static const androidLikeChannel = AndroidNotificationChannel(
    'duo_likes',
    'Likes',
    description: 'When someone likes your profile',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize({
    required void Function(String? payload) onNotificationTap,
  }) async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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
    }

    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _backgroundTapHandler(NotificationResponse response) {
    // Tap routing handled on next app resume via stored payload.
  }

  Future<void> showPushNotification({
    required ParsedPushDisplay display,
  }) async {
    if (!_initialized) return;

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
      groupKey: display.type.value,
      actions: actions,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: display.type.label,
    );

    await _plugin.show(
      id: display.notificationId,
      title: display.title,
      body: display.body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: display.deepLink,
    );
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
  });

  final int notificationId;
  final DuoNotificationType type;
  final String title;
  final String body;
  final String deepLink;
  final String imageUrl;
  final String iconUrl;
}
