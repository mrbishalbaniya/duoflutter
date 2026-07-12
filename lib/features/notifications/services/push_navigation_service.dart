import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../discover/domain/discover_models.dart';
import '../../discover/providers/discover_providers.dart';

/// Mirrors DuoFrontend firebase-messaging-sw.js targetPathFromNotification.
class PushNavigationService {
  static void navigateFromDeepLink({
    required GoRouter router,
    required WidgetRef ref,
    required String deepLink,
  }) {
    final uri = Uri.tryParse(deepLink.startsWith('/') ? 'app://host$deepLink' : deepLink);
    if (uri == null) {
      router.go(AppRoutes.chat);
      return;
    }

    final path = uri.path;
    final conversationId = uri.queryParameters['conversation'] ??
        uri.queryParameters['conversation_id'];

    if (conversationId != null && conversationId.isNotEmpty) {
      router.push('/chat/$conversationId');
      return;
    }

    if (path.contains('/chat')) {
      router.go(AppRoutes.chat);
      return;
    }

    final tab = uri.queryParameters['tab'];
    if (path.contains('/discover') || tab != null) {
      if (tab == 'likes-you') {
        ref.read(discoverTabProvider.notifier).state = DiscoverTab.received;
      } else if (tab == 'visited-you') {
        ref.read(discoverTabProvider.notifier).state = DiscoverTab.visitors;
      }
      router.go(AppRoutes.discover);
      return;
    }

    router.go(AppRoutes.chat);
  }
}
