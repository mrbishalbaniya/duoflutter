import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../widgets/duo_ui.dart';
import '../../../splash/widgets/splash_brand.dart';
import '../../providers/permission_providers.dart';

class PermissionPersonalizationScreen extends ConsumerStatefulWidget {
  const PermissionPersonalizationScreen({super.key});

  @override
  ConsumerState<PermissionPersonalizationScreen> createState() =>
      _PermissionPersonalizationScreenState();
}

class _PermissionPersonalizationScreenState extends ConsumerState<PermissionPersonalizationScreen> {
  bool _matchAlerts = true;
  bool _discoverVisibility = true;

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final store = ref.read(permissionLocalStoreProvider);
    await store.savePersonalizationPrefs({
      'match_alerts': _matchAlerts,
      'discover_visibility': _discoverVisibility,
    });
    await ref.read(permissionLocalStoreProvider).markSetupComplete();
    if (!mounted) return;
    context.go(AppRoutes.match);
  }

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
                      Text(
                        'Make Duo yours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Optional preferences to personalize your experience.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 20),
                      DuoGlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        borderRadius: 24,
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _matchAlerts,
                              onChanged: (value) => setState(() => _matchAlerts = value),
                              title: const Text('Match & message alerts'),
                              subtitle: const Text('Get notified about new matches and messages.'),
                              secondary: Icon(Icons.favorite_rounded, color: scheme.primary),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            SwitchListTile(
                              value: _discoverVisibility,
                              onChanged: (value) => setState(() => _discoverVisibility = value),
                              title: const Text('Show me in Discover'),
                              subtitle: const Text('Let others find your profile in recommendations.'),
                              secondary: Icon(Icons.explore_rounded, color: scheme.tertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _finish,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Go to Duo'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip for now'),
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
