import '../security/screen_security.dart';
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
import '../../features/wallet/wallet_transactions_screen.dart';
import '../../features/insights/insights_screen.dart';
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
import '../../features/support/data/support_content.dart';
import '../../features/support/presentation/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/account_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/mail_preferences_screen.dart';
import '../../features/settings/presentation/screens/match_preferences_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/support/presentation/delete_account_screen.dart';
import '../../features/support/presentation/help_screens.dart';
import '../../features/support/presentation/support_request_screen.dart';
import '../../repositories/support_repository.dart';

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
  static const walletTransactions = '/wallet/transactions';
  static const insights = '/insights';
  static const settings = '/settings';
  static const settingsAppearance = '/settings/appearance';
  static const settingsNotifications = '/settings/notifications';
  static const settingsMails = '/settings/mails';
  static const account = '/account';
  static const matchPreferences = '/preferences';
  static const security = '/security';
  static const securityTwoFactor = '/security/two-factor';
  static const securityBiometric = '/security/biometric';
  static const securityDevices = '/security/devices';
  static const securityLoginHistory = '/security/login-history';
  static const securityAlerts = '/security/alerts';
  static const securityChangePassword = '/security/change-password';
  static const notifications = '/notifications';
  static const blockedUsers = '/blocked-users';
  static const deleteAccount = '/delete-account';
  static const help = '/help';
  static const helpFaq = '/help/faq';
  static const helpContact = '/help/contact';
  static const helpReportBug = '/help/report-bug';
  static const legalPrivacy = '/legal/privacy';
  static const legalTerms = '/legal/terms';
  static const update = '/update';
  static const verify = '/verify';
  static const verifyDevice = '/verify/device';
  static const permissionWelcome = '/setup/welcome';
  static const permissionSetup = '/setup/permissions';
  static const permissionPersonalize = '/setup/personalize';
}

/// Screens that show other members' photos and profiles.
const _screenshotProtectedRoutes = {AppRoutes.match, AppRoutes.discover, AppRoutes.matchCelebration};

final routerProvider = Provider<GoRouter>((ref) {
  // Build the router ONCE. It used to `ref.watch` auth/splash/onboarding/
  // permission state, so every profile refresh (e.g. saving Match filters)
  // created a brand-new GoRouter: the whole navigation stack was rebuilt,
  // open sheets/awaits were orphaned and Match stayed "filters open" (frozen)
  // until relaunch. Redirect reads the latest values; _AuthRefreshListenable
  // re-runs it whenever they change.
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final splash = ref.read(splashControllerProvider);
      final intro = ref.read(onboardingControllerProvider);
      final permissionSetupComplete = ref.read(permissionSetupCompleteProvider);
      final path = state.matchedLocation;
      final isOnboarding = path == AppRoutes.onboarding;
      final isAuthRoute =
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword ||
          isOnboarding;
      final isSplash = path == AppRoutes.splash;
      // Static info pages reachable from the login footer before sign-in.
      final isPublicInfo =
          path == AppRoutes.legalPrivacy ||
          path == AppRoutes.legalTerms ||
          path == AppRoutes.help ||
          path == AppRoutes.helpFaq;
      final isVerifyDevice = path == AppRoutes.verifyDevice;
      final isPermissionRoute =
          path == AppRoutes.permissionWelcome ||
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
        if (isAuthRoute || isPublicInfo) return null;
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
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
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
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
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
        builder: (_, state) =>
            MatchCelebrationScreen(match: state.extra as dynamic),
      ),
      GoRoute(
        path: AppRoutes.chatThread,
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(path: AppRoutes.wallet, builder: (_, __) => const WalletScreen()),
      GoRoute(
        path: AppRoutes.walletTransactions,
        builder: (_, __) => const WalletTransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.insights,
        builder: (_, state) => InsightsScreen(
          initialMatchId: int.tryParse(state.uri.queryParameters['match'] ?? ''),
        ),
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
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
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
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
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
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(path: AppRoutes.settingsAppearance, builder: (_, __) => const AppearanceScreen()),
      GoRoute(
        path: AppRoutes.settingsNotifications,
        builder: (_, __) => const NotificationPreferencesScreen(),
      ),
      GoRoute(path: AppRoutes.settingsMails, builder: (_, __) => const MailPreferencesScreen()),
      GoRoute(path: AppRoutes.account, builder: (_, __) => const AccountScreen()),
      GoRoute(path: AppRoutes.matchPreferences, builder: (_, __) => const MatchPreferencesScreen()),
      GoRoute(path: AppRoutes.update, builder: (_, __) => const UpdateScreen()),
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
        path: AppRoutes.blockedUsers,
        builder: (_, __) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, __) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (_, __) => const HelpCenterScreen(),
      ),
      GoRoute(path: AppRoutes.helpFaq, builder: (_, __) => const FaqScreen()),
      GoRoute(
        path: AppRoutes.helpContact,
        builder: (_, __) => const SupportRequestScreen(
          category: SupportRequestCategory.contact,
        ),
      ),
      GoRoute(
        path: AppRoutes.helpReportBug,
        builder: (_, __) =>
            const SupportRequestScreen(category: SupportRequestCategory.bug),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        builder: (_, __) => const LegalScreen(document: privacyDocument),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        builder: (_, __) => const LegalScreen(document: termsDocument),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
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

  // No screenshots while other members' profiles are on screen.
  void syncScreenSecurity() {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (_screenshotProtectedRoutes.contains(path)) {
      ScreenSecurity.acquire(router);
    } else {
      ScreenSecurity.release(router);
    }
  }

  router.routerDelegate.addListener(syncScreenSecurity);
  ref.onDispose(() {
    router.routerDelegate.removeListener(syncScreenSecurity);
    ScreenSecurity.release(router);
  });
  return router;
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
