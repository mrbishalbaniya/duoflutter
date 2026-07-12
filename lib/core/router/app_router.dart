import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_controller.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_thread_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/match/match_celebration_screen.dart';
import '../../features/match/match_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/verify/verification_screen.dart';
import '../../features/verify/verify_device_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const match = '/match';
  static const matchCelebration = '/match/celebration';
  static const discover = '/discover';
  static const chat = '/chat';
  static const chatThread = '/chat/:conversationId';
  static const map = '/map';
  static const profile = '/profile';
  static const wallet = '/wallet';
  static const settings = '/settings';
  static const verify = '/verify';
  static const verifyDevice = '/verify/device';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final splash = ref.watch(splashControllerProvider);
  final intro = ref.watch(onboardingControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isOnboarding = path == AppRoutes.onboarding;
      final isAuthRoute = path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword ||
          isOnboarding;
      final isSplash = path == AppRoutes.splash;
      final isVerifyDevice = path == AppRoutes.verifyDevice;

      if (auth.status == AuthStatus.unknown) {
        return isSplash || isVerifyDevice ? null : AppRoutes.splash;
      }

      if (isSplash && !splash.canExit) {
        return null;
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (isVerifyDevice) return null;
        if (!intro.isComplete) {
          if (!isOnboarding) return AppRoutes.onboarding;
          return null;
        }
        if (isOnboarding) return AppRoutes.login;
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      if (auth.status == AuthStatus.authenticated) {
        final needsOnboarding = !(auth.user?.profile.isOnboarded ?? false);
        if (needsOnboarding) {
          if (path != AppRoutes.register) return AppRoutes.register;
          return null;
        }
        if (isAuthRoute || isSplash) return AppRoutes.match;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchCelebration,
        builder: (_, state) => MatchCelebrationScreen(
          match: state.extra as dynamic,
        ),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyDevice,
        builder: (_, state) => VerifyDeviceScreen(
          sessionToken: state.uri.queryParameters['session'],
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (_, __) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (_, __) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.match,
                builder: (_, __) => const MatchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                builder: (_, __) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
    _ref.listen(splashControllerProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
