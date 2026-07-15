import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/notification_item.dart';
import '../data/notification_local_store.dart';
import 'notification_router.dart';

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
    this.conversationId = '',
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
  final String conversationId;

  /// Backend sends `sound: "1"|"0"` in the FCM data payload.
  bool get playSound {
    final raw = data['sound']?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return true;
    return raw != '0' && raw != 'false' && raw != 'off' && raw != 'no';
  }

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

/// Parse FCM remote messages into a stable [ParsedPushPayload].
class PushPayloadParser {
  static ParsedPushPayload parse(RemoteMessage message) {
    final data = message.data.map((k, v) => MapEntry(k, '$v'));
    final n = message.notification;

    var type = DuoNotificationType.fromValue(_pick(data['type']));
    if (type == DuoNotificationType.profileLike &&
        data['action']?.toUpperCase() == 'SUPERLIKE') {
      type = DuoNotificationType.superLike;
    }

    var title = _pick(n?.title, data['title'], 'Duo');
    var body = _pick(n?.body, data['body'], 'You have a new update');
    final otherName = _pick(data['other_name'], 'someone special');
    final score = _pick(data['compatibility_score']);

    if (n?.title == null && data['title'] == null) {
      title = switch (type) {
        DuoNotificationType.newMatch => "It's a Match!",
        DuoNotificationType.profileLike => 'Someone liked you',
        DuoNotificationType.superLike => 'Someone superliked you',
        DuoNotificationType.chatMessage => 'New message',
        DuoNotificationType.messageReaction => 'New reaction',
        DuoNotificationType.callIncoming => 'Incoming call',
        DuoNotificationType.callMissed => 'Missed call',
        DuoNotificationType.profileViewed => 'Someone viewed your profile',
        DuoNotificationType.updateAvailable => 'Update Available',
        DuoNotificationType.securityAlert => 'Security alert',
        _ => title,
      };
    }

    if (n?.body == null && data['body'] == null) {
      if (type == DuoNotificationType.newMatch) {
        body = score.isNotEmpty
            ? 'You and $otherName have expressed interest in each other. $score% compatible — start chatting.'
            : 'You and $otherName have expressed interest in each other. Start chatting on Duo.';
      } else if (type == DuoNotificationType.superLike) {
        body = 'A special someone sent you a superlike. Open Duo to find out who.';
      } else if (type == DuoNotificationType.updateAvailable) {
        body =
            'A new version of the app is available. Update now for the latest improvements and fixes.';
      }
    }

    final deepLink = NotificationRouter.resolveDefaultDeepLink(type: type, data: data);
    final conversationId = _pick(
      data['conversation_id'],
      data['conversation'],
      _conversationFromUrl(deepLink),
    );

    return ParsedPushPayload(
      title: title,
      body: body,
      type: type,
      deepLink: deepLink,
      imageUrl: _pick(data['image']),
      iconUrl: _pick(data['icon']),
      tag: _pick(data['tag'], type.value),
      data: data,
      id: NotificationLocalStore.idFromPayload(data),
      conversationId: conversationId,
    );
  }

  static String _conversationFromUrl(String url) {
    final uri = Uri.tryParse(url.startsWith('/') ? 'app://duo$url' : url);
    return uri?.queryParameters['conversation'] ??
        uri?.queryParameters['conversation_id'] ??
        '';
  }

  static String _pick(String? a, [String? b, String? c]) {
    for (final value in [a, b, c]) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
