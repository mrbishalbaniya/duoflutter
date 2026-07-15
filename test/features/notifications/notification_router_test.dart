import 'package:flutter_test/flutter_test.dart';

import 'package:duo_mobile/features/notifications/domain/notification_item.dart';
import 'package:duo_mobile/features/notifications/domain/notification_tap_payload.dart';
import 'package:duo_mobile/features/notifications/services/notification_router.dart';

void main() {
  group('NotificationTapPayload', () {
    test('encodes and decodes JSON', () {
      const payload = NotificationTapPayload(
        deepLink: '/chat?conversation=abc',
        type: DuoNotificationType.chatMessage,
        conversationId: 'abc',
        notificationId: 'n1',
      );
      final roundTrip = NotificationTapPayload.decode(payload.encode());
      expect(roundTrip.deepLink, '/chat?conversation=abc');
      expect(roundTrip.type, DuoNotificationType.chatMessage);
      expect(roundTrip.conversationId, 'abc');
      expect(roundTrip.notificationId, 'n1');
    });

    test('accepts legacy plain deep links', () {
      final payload = NotificationTapPayload.decode('/discover?tab=likes-you');
      expect(payload.deepLink, '/discover?tab=likes-you');
      expect(payload.type, DuoNotificationType.unknown);
    });

    test('handles invalid/empty payloads safely', () {
      final empty = NotificationTapPayload.decode(null);
      expect(empty.deepLink, '/chat');
      final bad = NotificationTapPayload.decode('{not-json');
      expect(bad.deepLink.startsWith('/'), isTrue);
    });
  });

  group('NotificationRouter.resolveDefaultDeepLink', () {
    test('chat uses conversation id', () {
      final link = NotificationRouter.resolveDefaultDeepLink(
        type: DuoNotificationType.chatMessage,
        data: {'conversation_id': 'c1'},
      );
      expect(link, '/chat?conversation=c1');
    });

    test('prefers backend url when present', () {
      final link = NotificationRouter.resolveDefaultDeepLink(
        type: DuoNotificationType.chatMessage,
        data: {'url': '/wallet', 'conversation_id': 'c1'},
      );
      expect(link, '/wallet');
    });

    test('likes and profile views go to discover tabs', () {
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.profileLike,
          data: const {},
        ),
        '/discover?tab=likes-you',
      );
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.profileViewed,
          data: const {},
        ),
        '/discover?tab=visited-you',
      );
    });

    test('verification and payments route correctly', () {
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.verificationUpdate,
          data: const {},
        ),
        '/verify',
      );
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.paymentSuccess,
          data: const {},
        ),
        '/wallet',
      );
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.securityAlert,
          data: const {},
        ),
        '/security/alerts',
      );
      expect(
        NotificationRouter.resolveDefaultDeepLink(
          type: DuoNotificationType.updateAvailable,
          data: const {},
        ),
        '/update',
      );
    });
  });

  group('DuoNotificationType', () {
    test('maps backend values and aliases', () {
      expect(DuoNotificationType.fromValue('chat_message'), DuoNotificationType.chatMessage);
      expect(DuoNotificationType.fromValue('super_like'), DuoNotificationType.superLike);
      expect(DuoNotificationType.fromValue('nope'), DuoNotificationType.unknown);
    });
  });
}
