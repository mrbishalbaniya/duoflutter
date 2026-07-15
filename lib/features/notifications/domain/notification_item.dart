import 'package:equatable/equatable.dart';

/// All backend FCM types (DuoBackend/notifications/constants.py) plus local types.
enum DuoNotificationType {
  chatMessage('chat_message'),
  messageReaction('message_reaction'),
  profileLike('profile_like'),
  superLike('super_like'),
  newMatch('new_match'),
  profileViewed('profile_viewed'),
  profileVerified('profile_verified'),
  photoApproved('photo_approved'),
  verificationUpdate('verification_update'),
  subscriptionPurchased('subscription_purchased'),
  subscriptionExpired('subscription_expired'),
  paymentSuccess('payment_success'),
  paymentFailure('payment_failure'),
  adminAnnouncement('admin_announcement'),
  systemMaintenance('system_maintenance'),
  marketing('marketing'),
  securityAlert('security_alert'),
  callIncoming('call_incoming'),
  callMissed('call_missed'),
  updateAvailable('update_available'),
  event('event'),
  unknown('unknown');

  const DuoNotificationType(this.value);

  final String value;

  static DuoNotificationType fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return DuoNotificationType.unknown;
    final normalized = raw.trim().toLowerCase();
    // Alias: backend may send profile_like with action SUPERLIKE.
    return DuoNotificationType.values.firstWhere(
      (t) => t.value == normalized,
      orElse: () => DuoNotificationType.unknown,
    );
  }

  String get label => switch (this) {
        DuoNotificationType.chatMessage => 'Message',
        DuoNotificationType.messageReaction => 'Reaction',
        DuoNotificationType.profileLike => 'Like',
        DuoNotificationType.superLike => 'Super Like',
        DuoNotificationType.newMatch => 'Match',
        DuoNotificationType.profileViewed => 'Profile view',
        DuoNotificationType.profileVerified => 'Verified',
        DuoNotificationType.photoApproved => 'Photo',
        DuoNotificationType.verificationUpdate => 'Verification',
        DuoNotificationType.subscriptionPurchased => 'Subscription',
        DuoNotificationType.subscriptionExpired => 'Subscription',
        DuoNotificationType.paymentSuccess => 'Payment',
        DuoNotificationType.paymentFailure => 'Payment',
        DuoNotificationType.adminAnnouncement => 'Announcement',
        DuoNotificationType.systemMaintenance => 'System',
        DuoNotificationType.marketing => 'News',
        DuoNotificationType.securityAlert => 'Security',
        DuoNotificationType.callIncoming => 'Call',
        DuoNotificationType.callMissed => 'Missed call',
        DuoNotificationType.updateAvailable => 'Update',
        DuoNotificationType.event => 'Event',
        DuoNotificationType.unknown => 'Update',
      };

  String get emoji => switch (this) {
        DuoNotificationType.chatMessage => '💬',
        DuoNotificationType.messageReaction => '✨',
        DuoNotificationType.profileLike => '❤️',
        DuoNotificationType.superLike => '⭐',
        DuoNotificationType.newMatch => '💘',
        DuoNotificationType.profileViewed => '👀',
        DuoNotificationType.profileVerified ||
        DuoNotificationType.photoApproved ||
        DuoNotificationType.verificationUpdate =>
          '✅',
        DuoNotificationType.subscriptionPurchased ||
        DuoNotificationType.subscriptionExpired ||
        DuoNotificationType.paymentSuccess ||
        DuoNotificationType.paymentFailure =>
          '💳',
        DuoNotificationType.adminAnnouncement ||
        DuoNotificationType.systemMaintenance ||
        DuoNotificationType.marketing =>
          '📢',
        DuoNotificationType.securityAlert => '🔐',
        DuoNotificationType.callIncoming => '📞',
        DuoNotificationType.callMissed => '📵',
        DuoNotificationType.updateAvailable => '⬆️',
        DuoNotificationType.event => '📅',
        DuoNotificationType.unknown => '🔔',
      };

  bool get isChatFamily =>
      this == DuoNotificationType.chatMessage || this == DuoNotificationType.messageReaction;

  bool get isCallFamily =>
      this == DuoNotificationType.callIncoming || this == DuoNotificationType.callMissed;
}

enum NotificationFilter {
  all,
  unread,
  messages,
  matches,
  likes,
}

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.deepLink = '',
    this.imageUrl = '',
    this.iconUrl = '',
    this.tag = '',
    this.data = const {},
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: DuoNotificationType.fromValue(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deepLink: json['deepLink'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  final String id;
  final DuoNotificationType type;
  final String title;
  final String body;
  final DateTime receivedAt;
  final String deepLink;
  final String imageUrl;
  final String iconUrl;
  final String tag;
  final Map<String, dynamic> data;
  final bool isRead;

  NotificationItem copyWith({
    String? id,
    DuoNotificationType? type,
    String? title,
    String? body,
    DateTime? receivedAt,
    String? deepLink,
    String? imageUrl,
    String? iconUrl,
    String? tag,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      deepLink: deepLink ?? this.deepLink,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      tag: tag ?? this.tag,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toUtc().toIso8601String(),
        'deepLink': deepLink,
        'imageUrl': imageUrl,
        'iconUrl': iconUrl,
        'tag': tag,
        'data': data,
        'isRead': isRead,
      };

  bool matchesFilter(NotificationFilter filter) {
    if (filter == NotificationFilter.unread) return !isRead;
    return switch (filter) {
      NotificationFilter.all || NotificationFilter.unread => true,
      NotificationFilter.messages => type.isChatFamily,
      NotificationFilter.matches => type == DuoNotificationType.newMatch,
      NotificationFilter.likes =>
        type == DuoNotificationType.profileLike || type == DuoNotificationType.superLike,
    };
  }

  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        body.toLowerCase().contains(q) ||
        type.label.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [id, type, title, body, receivedAt, isRead];
}

String formatNotificationTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${date.month}/${date.day}';
}
