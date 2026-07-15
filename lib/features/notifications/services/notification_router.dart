import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../chat/providers/chat_thread_controller.dart';
import '../../discover/domain/discover_models.dart';
import '../../discover/providers/discover_providers.dart';
import '../../update/providers/update_providers.dart';
import '../domain/notification_item.dart';
import '../domain/notification_tap_payload.dart';
import '../services/push_debug_log.dart';

/// Central deep-link resolver for every Duo notification type.
///
/// Register new types by adding an enum value + a case in [resolveDefaultDeepLink]
/// and [navigate]. Prefer absolute app paths so taps never open the wrong screen.
class NotificationRouter {
  NotificationRouter._();

  static String? _lastKey;
  static DateTime? _lastAt;

  /// Deduplicate accidental double-taps (FCM + local launch).
  static bool _shouldSkipDuplicate(String key) {
    final now = DateTime.now();
    if (_lastKey == key && _lastAt != null && now.difference(_lastAt!) < const Duration(milliseconds: 900)) {
      PushDebugLog.info('Skipping duplicate navigation for $key');
      return true;
    }
    _lastKey = key;
    _lastAt = now;
    return false;
  }

  static String resolveDefaultDeepLink({
    required DuoNotificationType type,
    required Map<String, String> data,
  }) {
    final url = (data['url'] ?? '').trim();
    if (url.isNotEmpty) return url.startsWith('/') ? url : '/$url';

    final conversationId = (data['conversation_id'] ?? data['conversation'] ?? '').trim();
    final callId = (data['call_id'] ?? '').trim();
    final callType = (data['call_type'] ?? 'voice').trim();
    final userId = (data['from_user_id'] ?? data['viewer_id'] ?? data['other_user_id'] ?? '').trim();
    final eventId = (data['event_id'] ?? '').trim();

    return switch (type) {
      DuoNotificationType.chatMessage || DuoNotificationType.messageReaction =>
        conversationId.isNotEmpty ? '/chat?conversation=$conversationId' : AppRoutes.chat,
      DuoNotificationType.newMatch => conversationId.isNotEmpty
          ? '/chat?conversation=$conversationId'
          : AppRoutes.match,
      DuoNotificationType.profileLike || DuoNotificationType.superLike =>
        '/discover?tab=likes-you',
      DuoNotificationType.profileViewed => '/discover?tab=visited-you',
      DuoNotificationType.profileVerified ||
      DuoNotificationType.photoApproved ||
      DuoNotificationType.verificationUpdate =>
        AppRoutes.verify,
      DuoNotificationType.subscriptionPurchased ||
      DuoNotificationType.subscriptionExpired ||
      DuoNotificationType.paymentSuccess ||
      DuoNotificationType.paymentFailure =>
        AppRoutes.wallet,
      DuoNotificationType.adminAnnouncement ||
      DuoNotificationType.systemMaintenance ||
      DuoNotificationType.marketing =>
        AppRoutes.notifications,
      DuoNotificationType.securityAlert => AppRoutes.securityAlerts,
      DuoNotificationType.callIncoming => conversationId.isNotEmpty && callId.isNotEmpty
          ? '/chat?conversation=$conversationId&call=$callId&call_type=$callType'
          : AppRoutes.chat,
      DuoNotificationType.callMissed => conversationId.isNotEmpty
          ? '/chat?conversation=$conversationId'
          : AppRoutes.chat,
      DuoNotificationType.updateAvailable => AppRoutes.update,
      DuoNotificationType.event =>
        eventId.isNotEmpty ? '/notifications?event=$eventId' : AppRoutes.notifications,
      DuoNotificationType.unknown => userId.isNotEmpty
          ? AppRoutes.profile
          : AppRoutes.notifications,
    };
  }

  static Future<void> navigate({
    required GoRouter router,
    required WidgetRef ref,
    required NotificationTapPayload payload,
  }) async {
    if (_shouldSkipDuplicate(payload.canonicalKey)) return;

    final uri = _parseAppUri(payload.deepLink);
    final path = uri.path;
    final conversationId = uri.queryParameters['conversation'] ??
        uri.queryParameters['conversation_id'] ??
        payload.conversationId;

    PushDebugLog.info(
      'NotificationRouter → type=${payload.type.value} path=$path conversation=$conversationId',
    );

    // Chat thread
    if (conversationId.isNotEmpty &&
        (path.contains('/chat') ||
            payload.type == DuoNotificationType.chatMessage ||
            payload.type == DuoNotificationType.messageReaction ||
            payload.type == DuoNotificationType.newMatch ||
            payload.type == DuoNotificationType.callIncoming ||
            payload.type == DuoNotificationType.callMissed)) {
      final target = '/chat/$conversationId';
      if (_isAlreadyOn(router, target)) {
        await _refreshChat(ref, conversationId);
        return;
      }
      router.push(target);
      return;
    }

    if (path == AppRoutes.chat || path.endsWith('/chat')) {
      if (_isAlreadyOn(router, AppRoutes.chat)) return;
      router.go(AppRoutes.chat);
      return;
    }

    // Discover tabs
    final tab = uri.queryParameters['tab'];
    if (path.contains('/discover') ||
        payload.type == DuoNotificationType.profileLike ||
        payload.type == DuoNotificationType.superLike ||
        payload.type == DuoNotificationType.profileViewed) {
      if (tab == 'likes-you' ||
          payload.type == DuoNotificationType.profileLike ||
          payload.type == DuoNotificationType.superLike) {
        ref.read(discoverTabProvider.notifier).state = DiscoverTab.received;
      } else if (tab == 'visited-you' || payload.type == DuoNotificationType.profileViewed) {
        ref.read(discoverTabProvider.notifier).state = DiscoverTab.visitors;
      }
      if (_isAlreadyOn(router, AppRoutes.discover)) {
        ref.invalidate(discoverTabProvider);
        return;
      }
      router.go(AppRoutes.discover);
      return;
    }

    // Explicit typed routes
    final destination = switch (payload.type) {
      DuoNotificationType.newMatch when !path.contains('/chat') => AppRoutes.match,
      DuoNotificationType.profileVerified ||
      DuoNotificationType.photoApproved ||
      DuoNotificationType.verificationUpdate =>
        AppRoutes.verify,
      DuoNotificationType.subscriptionPurchased ||
      DuoNotificationType.subscriptionExpired ||
      DuoNotificationType.paymentSuccess ||
      DuoNotificationType.paymentFailure =>
        AppRoutes.wallet,
      DuoNotificationType.securityAlert => AppRoutes.securityAlerts,
      DuoNotificationType.updateAvailable => AppRoutes.update,
      DuoNotificationType.adminAnnouncement ||
      DuoNotificationType.systemMaintenance ||
      DuoNotificationType.marketing ||
      DuoNotificationType.event =>
        AppRoutes.notifications,
      _ => null,
    };

    if (destination != null) {
      if (_isAlreadyOn(router, destination)) {
        if (destination == AppRoutes.update) {
          await ref.read(updateControllerProvider.notifier).checkForUpdates(force: true, manual: true);
        }
        return;
      }
      router.go(destination);
      return;
    }

    // Path-based fallback from backend url
    if (path.isNotEmpty && path != '/') {
      if (_isAlreadyOn(router, path)) return;
      final known = {
        AppRoutes.match,
        AppRoutes.discover,
        AppRoutes.chat,
        AppRoutes.profile,
        AppRoutes.wallet,
        AppRoutes.settings,
        AppRoutes.security,
        AppRoutes.securityAlerts,
        AppRoutes.notifications,
        AppRoutes.verify,
        AppRoutes.update,
        AppRoutes.map,
      };
      if (known.contains(path)) {
        router.go(path);
        return;
      }
      // Avoid opening garbage paths — land on inbox for announcements.
      router.go(AppRoutes.notifications);
      return;
    }

    router.go(AppRoutes.notifications);
  }

  static Uri _parseAppUri(String deepLink) {
    final raw = deepLink.trim().isEmpty ? '/notifications' : deepLink.trim();
    final normalized = raw.startsWith('/') ? 'app://duo$raw' : raw;
    return Uri.tryParse(normalized) ?? Uri(path: AppRoutes.notifications);
  }

  static bool _isAlreadyOn(GoRouter router, String targetPath) {
    try {
      final loc = router.routerDelegate.currentConfiguration.uri.path;
      if (targetPath.startsWith('/chat/')) {
        return loc == targetPath || loc.endsWith(targetPath);
      }
      return loc == targetPath;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _refreshChat(WidgetRef ref, String conversationId) async {
    try {
      ref.invalidate(chatThreadControllerProvider(conversationId));
      PushDebugLog.info('Refreshed open chat $conversationId');
    } catch (e) {
      PushDebugLog.error('Failed to refresh chat from notification', e);
    }
  }
}
