import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/notification_item.dart';
import '../domain/notification_tap_payload.dart';
import 'notification_router.dart';

/// Deprecated shim — use [NotificationRouter] for new code.
class PushNavigationService {
  static void navigateFromDeepLink({
    required GoRouter router,
    required WidgetRef ref,
    required String deepLink,
    DuoNotificationType type = DuoNotificationType.unknown,
  }) {
    NotificationRouter.navigate(
      router: router,
      ref: ref,
      payload: NotificationTapPayload(
        deepLink: deepLink,
        type: type,
      ),
    );
  }
}
