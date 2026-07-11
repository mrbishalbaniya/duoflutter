import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
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
import '../../features/wallet/wallet_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
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
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isAuthRoute = path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.forgotPassword;
      final isSplash = path == AppRoutes.splash;

      if (auth.status == AuthStatus.unknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      if (auth.status == AuthStatus.authenticated) {
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
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
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
        builder: (_, __) => const VerifyPlaceholderScreen(),
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
                builder: (_, __) => const _MapPlaceholderScreen(),
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
  }

  final Ref _ref;
}

class _MapPlaceholderScreen extends StatelessWidget {
  const _MapPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Globe map coming in Phase 2',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Match locations, layers, and activity heatmap will mirror the web map.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
