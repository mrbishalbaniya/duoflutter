import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/call/presentation/call_bridge.dart';
import 'features/notifications/presentation/widgets/push_notification_bridge.dart';
import 'features/security/presentation/widgets/biometric_unlock_bridge.dart';
import 'features/update/presentation/widgets/update_bridge.dart';

class DuoApp extends ConsumerWidget {
  const DuoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Builder(
      builder: (context) {
        final brightness = switch (themeMode) {
          ThemeMode.dark => Brightness.dark,
          ThemeMode.light => Brightness.light,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        final theme = brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light();

        return AnimatedTheme(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          data: theme,
          child: MaterialApp.router(
            title: 'Duo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            routerConfig: router,
            builder: (context, child) {
              return UpdateBridge(
                child: PushNotificationBridge(
                  child: CallBridge(
                    child: BiometricUnlockBridge(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorage();
  await storage.init();
}
