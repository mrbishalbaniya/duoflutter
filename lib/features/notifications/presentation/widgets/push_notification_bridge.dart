import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/auth_controller.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../providers/notifications_providers.dart';

/// Mirrors DuoFrontend PushNotificationBridge — binds FCM listeners when authenticated.
class PushNotificationBridge extends ConsumerStatefulWidget {
  const PushNotificationBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationBridge> createState() => _PushNotificationBridgeState();
}

class _PushNotificationBridgeState extends ConsumerState<PushNotificationBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBinding());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncBinding();
    }
  }

  void _syncBinding() {
    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    final coordinator = ref.read(pushMessagingCoordinatorProvider);

    if (auth.status != AuthStatus.authenticated) {
      coordinator.unbind();
      return;
    }

    coordinator.bind(
      router: GoRouter.of(context),
      ref: ref,
      onIngest: (item) async {
        await ref.read(notificationLocalStoreProvider).upsert(item);
        ref.read(notificationsControllerProvider.notifier).refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, __) => _syncBinding());
    ref.listen(pushNotificationServiceProvider, (_, __) => _syncBinding());
    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous?.pushStatus.enabled != next.pushStatus.enabled) {
        _syncBinding();
      }
    });
    return widget.child;
  }
}
