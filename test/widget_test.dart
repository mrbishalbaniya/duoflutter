import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo_mobile/app.dart';
import 'package:duo_mobile/features/auth/auth_controller.dart';

void main() {
  testWidgets('DuoApp builds and routes to login when logged out', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            return AuthController(ref, autoBootstrap: false)
              ..state = const AuthState(status: AuthStatus.unauthenticated);
          }),
        ],
        child: const DuoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
