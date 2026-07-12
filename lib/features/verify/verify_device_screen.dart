import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/verification_domain.dart';
import 'verification_screen.dart';

/// Public handoff route — continues verification with a session token (no login).
class VerifyDeviceScreen extends ConsumerWidget {
  const VerifyDeviceScreen({super.key, this.sessionToken});

  final String? sessionToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionToken == null || sessionToken!.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Invalid verification link. Open the link from your email or QR code again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return VerificationScreen(
      mode: VerificationMode.device,
      initialSessionToken: sessionToken,
    );
  }
}
