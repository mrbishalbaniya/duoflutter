import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_controller.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
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
import '../../features/permissions/providers/permission_providers.dart';
import '../../features/permissions/presentation/screens/permission_welcome_screen.dart';
import '../../features/permissions/presentation/screens/permission_setup_screen.dart';
import '../../features/permissions/presentation/screens/permission_personalization_screen.dart';
import '../../features/update/presentation/screens/update_screen.dart';
import '../../features/security/presentation/screens/active_devices_screen.dart';
import '../../features/security/presentation/screens/biometric_login_screen.dart';
import '../../features/security/presentation/screens/change_password_screen.dart';
import '../../features/security/presentation/screens/login_history_screen.dart';
import '../../features/security/presentation/screens/security_alerts_screen.dart';
import '../../features/security/presentation/screens/security_center_screen.dart';
import '../../features/security/presentation/screens/two_factor_screen.dart';

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
  static const security = '/security';
  static const securityTwoFactor = '/security/two-factor';
  static const securityBiometric = '/security/biometric';
  static const securityDevices = '/security/devices';
  static const securityLoginHistory = '/security/login-history';
  static const securityAlerts = '/security/alerts';
  static const securityChangePassword = '/security/change-password';
  static const notifications = '/notifications';
  static const update = '/update';
  static const verify = '/verify';
  static const verifyDevice = '/verify/device';
  static const permissionWelcome = '/setup/welcome';
  static const permissionSetup = '/setup/permissions';
  static const permissionPersonalize = '/setup/personalize';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final splash = ref.watch(splashControllerProvider);
  final intro = ref.watch(onboardingControllerProvider);
  final permissionSetupComplete = ref.watch(permissionSetupCompleteProvider);

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
      final isPermissionRoute = path == AppRoutes.permissionWelcome ||
          path == AppRoutes.permissionSetup ||
          path == AppRoutes.permissionPersonalize;

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
        if (!permissionSetupComplete) {
          if (!isPermissionRoute) return AppRoutes.permissionWelcome;
          return null;
        }
        if (isPermissionRoute) return AppRoutes.match;
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
        path: AppRoutes.permissionWelcome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PermissionWelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.permissionSetup,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PermissionSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.permissionPersonalize,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PermissionPersonalizationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.update,
        builder: (_, __) => const UpdateScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (_, __) => const SecurityCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityTwoFactor,
        builder: (_, __) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityBiometric,
        builder: (_, __) => const BiometricLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityDevices,
        builder: (context, state) => ActiveDevicesScreen(
          trustedOnly: state.uri.queryParameters['trusted'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.securityLoginHistory,
        builder: (_, __) => const LoginHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityAlerts,
        builder: (_, __) => const SecurityAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.securityChangePassword,
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
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
    _ref.listen(onboardingControllerProvider, (previous, next) {
      if (previous?.isComplete != next.isComplete) {
        notifyListeners();
      }
    });
    _ref.listen(permissionSetupCompleteProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
