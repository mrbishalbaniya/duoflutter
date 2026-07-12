import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo_mobile/app.dart';
import 'package:duo_mobile/core/theme/theme_controller.dart';
import 'package:duo_mobile/features/auth/auth_controller.dart';
import 'package:duo_mobile/features/onboarding/onboarding_controller.dart';
import 'package:duo_mobile/features/splash/splash_controller.dart';

void main() {
  testWidgets('DuoApp builds and routes to login when logged out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith((ref) => ThemeController.testing()),
          splashMinDurationProvider.overrideWith((ref) => Duration.zero),
          splashControllerProvider.overrideWith((ref) => SplashController.testing(ref)),
          onboardingControllerProvider.overrideWith(
            (ref) => OnboardingController.testing(ref, isComplete: true),
          ),
          authControllerProvider.overrideWith((ref) {
            return AuthController(ref, autoBootstrap: false)
              ..state = const AuthState(status: AuthStatus.unauthenticated);
          }),
        ],
        child: const DuoApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
