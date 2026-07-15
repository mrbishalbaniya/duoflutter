import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/storage/local_storage.dart';
import '../domain/notification_item.dart';
import '../domain/notification_tap_payload.dart';
import 'notification_reply_handler.dart';
import 'notification_image_loader.dart';
import 'push_debug_log.dart';

typedef NotificationInteractionCallback = void Function(
  NotificationTapPayload payload, {
  String? actionId,
  String? input,
});

class LocalNotificationService {
  LocalNotificationService({
    NotificationImageLoader? imageLoader,
    NotificationReplyHandler? replyHandler,
  })  : _plugin = FlutterLocalNotificationsPlugin(),
        _imageLoader = imageLoader ?? NotificationImageLoader(),
        _replyHandler = replyHandler ?? NotificationReplyHandler();

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationImageLoader _imageLoader;
  final NotificationReplyHandler _replyHandler;
  bool _initialized = false;
  NotificationInteractionCallback? _onInteraction;

  /// Custom Duo chime in `android/.../res/raw/duo_notification.wav`
  /// and `ios/Runner/duo_notification.wav`. Channel IDs bumped to v2 so
  /// existing installs pick up the new sound (Android channels are immutable).
  static const androidNotificationSound =
      RawResourceAndroidNotificationSound('duo_notification');
  static const iosNotificationSound = 'duo_notification.wav';

  static const androidChatChannel = AndroidNotificationChannel(
    'duo_chat_v2',
    'Chat Messages',
    description: 'New messages from your matches',
    importance: Importance.high,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: true,
    showBadge: true,
  );

  static const androidMatchChannel = AndroidNotificationChannel(
    'duo_matches_v2',
    'New Matches',
    description: 'When you match with someone new',
    importance: Importance.max,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: true,
    showBadge: true,
  );

  static const androidLikeChannel = AndroidNotificationChannel(
    'duo_likes_v2',
    'Likes',
    description: 'When someone likes your profile',
    importance: Importance.high,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: true,
    showBadge: true,
  );

  static const androidCallChannel = AndroidNotificationChannel(
    'duo_calls_v2',
    'Calls',
    description: 'Incoming and missed call alerts',
    importance: Importance.max,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: true,
    showBadge: true,
  );

  static const androidUpdatesChannel = AndroidNotificationChannel(
    'duo_updates_v2',
    'App Updates',
    description: 'When a new Duo version is available',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: false,
    showBadge: false,
  );

  static const androidSystemChannel = AndroidNotificationChannel(
    'duo_system_v2',
    'Announcements',
    description: 'Verification, payments, and admin announcements',
    importance: Importance.high,
    playSound: true,
    sound: androidNotificationSound,
    enableVibration: true,
    showBadge: true,
  );

  static const _chatCategoryId = 'duo_chat_reply';

  Future<void> initialize({
    required NotificationInteractionCallback onInteraction,
  }) async {
    _onInteraction = onInteraction;
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _chatCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.text(
              NotificationActionIds.reply,
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Message',
            ),
            DarwinNotificationAction.plain(
              NotificationActionIds.openChat,
              'Open',
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        _dispatchResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundInteractionHandler,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(androidChatChannel);
      await android?.createNotificationChannel(androidMatchChannel);
      await android?.createNotificationChannel(androidLikeChannel);
      await android?.createNotificationChannel(androidCallChannel);
      await android?.createNotificationChannel(androidUpdatesChannel);
      await android?.createNotificationChannel(androidSystemChannel);
      PushDebugLog.info('Android notification channels created');
    }

    _initialized = true;
    PushDebugLog.info('Local notifications initialized');
  }

  void _dispatchResponse(NotificationResponse response) {
    final payload = NotificationTapPayload.decode(response.payload);
    final actionId = response.actionId;
    final input = response.input?.trim();

    if (actionId == NotificationActionIds.reply && input != null && input.isNotEmpty) {
      unawaited(_handleInlineReply(payload, input));
      return;
    }

    _onInteraction?.call(payload, actionId: actionId, input: input);
  }

  Future<void> _handleInlineReply(NotificationTapPayload payload, String text) async {
    PushDebugLog.info('Inline reply received for ${payload.conversationId}');
    final ok = await _replyHandler.sendReply(
      conversationId: payload.conversationId,
      text: text,
    );
    if (!ok) {
      await showPushNotification(
        display: ParsedPushDisplay(
          notificationId: 'reply_failed_${payload.conversationId}'.hashCode,
          type: DuoNotificationType.chatMessage,
          title: 'Reply failed',
          body: 'Could not send your reply. Open the chat to try again.',
          deepLink: payload.deepLink,
          tag: 'reply_failed',
          conversationId: payload.conversationId,
          notificationKey: payload.notificationId,
        ),
      );
      return;
    }
    // Still notify foreground so chat can refresh if open.
    _onInteraction?.call(
      payload,
      actionId: NotificationActionIds.reply,
      input: text,
    );
  }

  @pragma('vm:entry-point')
  static void notificationBackgroundInteractionHandler(NotificationResponse response) {
    unawaited(_backgroundInteraction(response));
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundInteraction(NotificationResponse response) async {
    WidgetsFlutterBinding.ensureInitialized();
    final payload = NotificationTapPayload.decode(response.payload);
    final input = response.input?.trim();

    if (response.actionId == NotificationActionIds.reply &&
        input != null &&
        input.isNotEmpty &&
        payload.conversationId.isNotEmpty) {
      final handler = NotificationReplyHandler();
      final ok = await handler.sendReply(
        conversationId: payload.conversationId,
        text: input,
      );
      PushDebugLog.info(ok ? 'Background reply sent' : 'Background reply failed');
      return;
    }

    final encoded = response.payload;
    if (encoded == null || encoded.isEmpty) return;
    try {
      final storage = LocalStorage();
      await storage.init();
      await storage.setPendingNotificationTapPayload(encoded);
      PushDebugLog.info('Stored pending notification interaction payload');
    } catch (e) {
      PushDebugLog.error('Failed to store pending notification payload', e);
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
    final largeIcon = await _imageLoader.largeIcon(
      display.iconUrl.isNotEmpty ? display.iconUrl : display.imageUrl,
    );

    final tapPayload = NotificationTapPayload(
      deepLink: display.deepLink,
      type: display.type,
      conversationId: display.conversationId,
      notificationId: display.notificationKey,
    );

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: display.type == DuoNotificationType.newMatch || display.type.isCallFamily
          ? Priority.max
          : Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: largeIcon,
      color: const Color(0xFFE84A7A),
      groupKey: 'duo_${display.type.value}',
      setAsGroupSummary: false,
      styleInformation: BigTextStyleInformation(
        display.body,
        contentTitle: display.title,
        summaryText: display.type.label,
      ),
      actions: actions,
      ticker: display.title,
      visibility: NotificationVisibility.public,
      category: display.type.isChatFamily
          ? AndroidNotificationCategory.message
          : display.type.isCallFamily
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.social,
      autoCancel: true,
      playSound: display.playSound,
      sound: display.playSound ? androidNotificationSound : null,
      enableVibration:
          display.playSound && display.type != DuoNotificationType.updateAvailable,
      tag: display.tag.isNotEmpty ? display.tag : display.type.value,
      channelShowBadge: display.type != DuoNotificationType.updateAvailable,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: display.playSound,
      sound: display.playSound ? iosNotificationSound : null,
      subtitle: display.type.label,
      threadIdentifier: display.conversationId.isNotEmpty
          ? display.conversationId
          : display.type.value,
      categoryIdentifier: display.type.isChatFamily ? _chatCategoryId : null,
    );

    await _plugin.show(
      id: display.notificationId,
      title: display.title,
      body: display.body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: tapPayload.encode(),
    );
    PushDebugLog.info('Notification shown in system tray (${display.type.value})');
  }

  Future<void> cancelById(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> setBadgeCount(int count) async {
    if (Platform.isIOS) {
      // flutter_local_notifications exposes badge via plugin method on newer versions;
      // best-effort no-op if unsupported.
      try {
        await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(badge: true);
      } catch (_) {}
    }
    PushDebugLog.info('Badge count requested=$count');
  }

  AndroidNotificationChannel _channelFor(DuoNotificationType type) {
    return switch (type) {
      DuoNotificationType.chatMessage || DuoNotificationType.messageReaction => androidChatChannel,
      DuoNotificationType.newMatch => androidMatchChannel,
      DuoNotificationType.profileLike ||
      DuoNotificationType.superLike ||
      DuoNotificationType.profileViewed =>
        androidLikeChannel,
      DuoNotificationType.callIncoming || DuoNotificationType.callMissed => androidCallChannel,
      DuoNotificationType.updateAvailable => androidUpdatesChannel,
      _ => androidSystemChannel,
    };
  }

  List<AndroidNotificationAction> _actionsFor(DuoNotificationType type) {
    return switch (type) {
      DuoNotificationType.chatMessage || DuoNotificationType.messageReaction => [
          AndroidNotificationAction(
            NotificationActionIds.reply,
            'Reply',
            showsUserInterface: false,
            cancelNotification: false,
            inputs: const [
              AndroidNotificationActionInput(
                label: 'Reply',
                allowFreeFormInput: true,
              ),
            ],
            semanticAction: SemanticAction.reply,
          ),
          const AndroidNotificationAction(
            NotificationActionIds.openChat,
            'Open',
            showsUserInterface: true,
          ),
        ],
      DuoNotificationType.newMatch => [
          const AndroidNotificationAction(
            NotificationActionIds.openChat,
            'Start chatting',
            showsUserInterface: true,
          ),
        ],
      DuoNotificationType.profileLike || DuoNotificationType.superLike => [
          const AndroidNotificationAction(
            NotificationActionIds.openLikes,
            'See who',
            showsUserInterface: true,
          ),
        ],
      DuoNotificationType.callIncoming => [
          const AndroidNotificationAction(
            NotificationActionIds.openChat,
            'Answer',
            showsUserInterface: true,
          ),
        ],
      DuoNotificationType.callMissed => [
          const AndroidNotificationAction(
            NotificationActionIds.openChat,
            'Call back',
            showsUserInterface: true,
          ),
        ],
      DuoNotificationType.updateAvailable => [
          const AndroidNotificationAction(
            NotificationActionIds.openUpdate,
            'Update',
            showsUserInterface: true,
          ),
        ],
      _ => const [],
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
    this.conversationId = '',
    this.notificationKey = '',
    this.playSound = true,
  });

  final int notificationId;
  final DuoNotificationType type;
  final String title;
  final String body;
  final String deepLink;
  final String imageUrl;
  final String iconUrl;
  final String tag;
  final String conversationId;
  final String notificationKey;
  final bool playSound;
}
