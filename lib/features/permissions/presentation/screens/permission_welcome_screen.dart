import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/duo_gradients.dart';
import '../../../../widgets/duo_ui.dart';
import '../../../splash/widgets/splash_brand.dart';

class PermissionWelcomeScreen extends StatelessWidget {
  const PermissionWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SplashBackground(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const DuoBrandLogo(size: 42, showTagline: true),
                      const SizedBox(height: 36),
                      DuoGlassCard(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        borderRadius: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: DuoGradients.brand,
                              ),
                              child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Welcome to Duo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Let\'s set up a few permissions so you can match, chat, and share moments without interruptions.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            _WelcomePoint(
                              icon: Icons.toggle_on_rounded,
                              text: 'Enable or disable each permission on one screen.',
                            ),
                            const SizedBox(height: 10),
                            _WelcomePoint(
                              icon: Icons.skip_next_rounded,
                              text: 'Optional items can stay off — continue anytime.',
                            ),
                            const SizedBox(height: 10),
                            _WelcomePoint(
                              icon: Icons.settings_suggest_rounded,
                              text: 'You can change everything later in Settings.',
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.05, end: 0),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.go(AppRoutes.permissionSetup);
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Set up permissions'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePoint extends StatelessWidget {
  const _WelcomePoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
