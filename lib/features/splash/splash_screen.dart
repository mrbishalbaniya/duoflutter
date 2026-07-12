import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'splash_controller.dart';
import 'splash_preloader.dart';
import 'widgets/splash_brand.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _preloadsStarted = false;
  bool _bootstrapped = false;

  void _bootstrapOnce() {
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPreloads());
  }

  Future<void> _startPreloads() async {
    if (_preloadsStarted) return;
    _preloadsStarted = true;
    await SplashPreloader.preload();
    if (mounted) {
      ref.read(splashControllerProvider.notifier).markAssetsReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    _bootstrapOnce();

    final splash = ref.watch(splashControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<SplashState>(splashControllerProvider, (previous, next) {
      if (next.canExit && !next.isExiting) {
        ref.read(splashControllerProvider.notifier).markExiting();
      }
    });

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status != AuthStatus.unknown) {
        final splashState = ref.read(splashControllerProvider);
        if (splashState.canExit && !splashState.isExiting) {
          ref.read(splashControllerProvider.notifier).markExiting();
        }
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            SplashBackground(isDark: isDark),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  SplashLogoMark(exiting: splash.isExiting),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      splash.versionLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            letterSpacing: 1.2,
                          ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
