import 'dart:convert';

import '../domain/notification_item.dart';

/// Stable action IDs used across Android/iOS notification actions.
abstract final class NotificationActionIds {
  static const reply = 'reply';
  static const openChat = 'open_chat';
  static const openLikes = 'open_likes';
  static const openUpdate = 'open_update';
  static const markRead = 'mark_read';
}

/// Encoded into local-notification [payload] so taps/replies keep context.
class NotificationTapPayload {
  const NotificationTapPayload({
    required this.deepLink,
    required this.type,
    this.conversationId = '',
    this.notificationId = '',
    this.userId = '',
    this.eventId = '',
    this.extra = const {},
  });

  final String deepLink;
  final DuoNotificationType type;
  final String conversationId;
  final String notificationId;
  final String userId;
  final String eventId;
  final Map<String, String> extra;

  factory NotificationTapPayload.fromJson(Map<String, dynamic> json) {
    return NotificationTapPayload(
      deepLink: '${json['deepLink'] ?? json['url'] ?? ''}',
      type: DuoNotificationType.fromValue('${json['type'] ?? ''}'),
      conversationId: '${json['conversationId'] ?? json['conversation_id'] ?? ''}',
      notificationId: '${json['notificationId'] ?? json['id'] ?? ''}',
      userId: '${json['userId'] ?? json['from_user_id'] ?? json['viewer_id'] ?? ''}',
      eventId: '${json['eventId'] ?? json['event_id'] ?? ''}',
      extra: {
        for (final e in json.entries)
          if (e.value != null) e.key: '${e.value}',
      },
    );
  }

  /// Accepts legacy plain deep-link strings or JSON payloads.
  factory NotificationTapPayload.decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const NotificationTapPayload(
        deepLink: '/chat',
        type: DuoNotificationType.unknown,
      );
    }
    final text = raw.trim();
    if (text.startsWith('{')) {
      try {
        final map = jsonDecode(text);
        if (map is Map<String, dynamic>) {
          return NotificationTapPayload.fromJson(map);
        }
        if (map is Map) {
          return NotificationTapPayload.fromJson(Map<String, dynamic>.from(map));
        }
      } catch (_) {
        // fall through to treat as path
      }
    }
    return NotificationTapPayload(
      deepLink: text.startsWith('/') ? text : '/$text',
      type: DuoNotificationType.unknown,
    );
  }

  String encode() => jsonEncode({
        'deepLink': deepLink,
        'type': type.value,
        if (conversationId.isNotEmpty) 'conversationId': conversationId,
        if (notificationId.isNotEmpty) 'notificationId': notificationId,
        if (userId.isNotEmpty) 'userId': userId,
        if (eventId.isNotEmpty) 'eventId': eventId,
        ...extra,
      });

  String get canonicalKey =>
      '${type.value}|$deepLink|$conversationId|$userId|$eventId';
}
