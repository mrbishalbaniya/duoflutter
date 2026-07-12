import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_item.dart';
import '../data/notification_local_store.dart';

class ParsedPushPayload {
  const ParsedPushPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.deepLink,
    required this.imageUrl,
    required this.iconUrl,
    required this.tag,
    required this.data,
    required this.id,
  });

  final String title;
  final String body;
  final DuoNotificationType type;
  final String deepLink;
  final String imageUrl;
  final String iconUrl;
  final String tag;
  final Map<String, String> data;
  final String id;

  NotificationItem toItem({bool isRead = false}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      receivedAt: DateTime.now().toUtc(),
      deepLink: deepLink,
      imageUrl: imageUrl,
      iconUrl: iconUrl,
      tag: tag,
      data: data,
      isRead: isRead,
    );
  }
}

/// Mirrors DuoFrontend/lib/push/fcm.ts notificationFromPayload + SW routing.
class PushPayloadParser {
  static ParsedPushPayload parse(RemoteMessage message) {
    final data = message.data.map((k, v) => MapEntry(k, '$v'));
    final n = message.notification;
    final type = DuoNotificationType.fromValue(_pick(data['type']));

    var title = _pick(n?.title, data['title'], 'Duo');
    var body = _pick(n?.body, data['body'], 'You have a new update');
    final otherName = _pick(data['other_name'], 'someone special');
    final score = _pick(data['compatibility_score']);

    if (n?.title == null && data['title'] == null) {
      title = switch (type) {
        DuoNotificationType.newMatch => "It's a Match!",
        DuoNotificationType.profileLike => 'Someone liked you',
        DuoNotificationType.chatMessage => 'New message',
        DuoNotificationType.unknown => title,
      };
    }

    if (n?.body == null && data['body'] == null && type == DuoNotificationType.newMatch) {
      body = score.isNotEmpty
          ? 'You and $otherName have expressed interest in each other. $score% compatible — start chatting.'
          : 'You and $otherName have expressed interest in each other. Start chatting on Duo.';
    }

    if (type == DuoNotificationType.profileLike) {
      final action = data['action']?.toUpperCase();
      if (action == 'SUPERLIKE') {
        title = 'Someone superliked you';
        body =
            'A special someone sent you a superlike. Open Duo to find out who.';
      }
    }

    final deepLink = _resolveDeepLink(data, type);
    final imageUrl = _pick(data['image']);
    final iconUrl = _pick(data['icon']);
    final tag = _pick(data['tag'], type.value);

    return ParsedPushPayload(
      title: title,
      body: body,
      type: type,
      deepLink: deepLink,
      imageUrl: imageUrl,
      iconUrl: iconUrl,
      tag: tag,
      data: data,
      id: NotificationLocalStore.idFromPayload(data),
    );
  }

  static String _resolveDeepLink(Map<String, String> data, DuoNotificationType type) {
    final url = _pick(data['url']);
    if (url.isNotEmpty) return url;

    final conversationId = _pick(data['conversation_id']);
    if (conversationId.isNotEmpty) {
      return '/chat?conversation=$conversationId';
    }

    return switch (type) {
      DuoNotificationType.profileLike => '/discover?tab=likes-you',
      DuoNotificationType.newMatch => '/chat',
      DuoNotificationType.chatMessage => '/chat',
      DuoNotificationType.unknown => '/chat',
    };
  }

  static String _pick(String? a, [String? b, String? c]) {
    for (final value in [a, b, c]) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
