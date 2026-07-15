import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/duo_gradients.dart';
import '../../../../widgets/duo_ui.dart';
import '../../../splash/widgets/splash_brand.dart';
import '../../models/permission_models.dart';
import '../../providers/permission_providers.dart';
import '../dialogs/permission_denied_dialog.dart';
import '../widgets/permission_toggle_tile.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionSetupControllerProvider.notifier).refreshStatuses();
    }
  }

  Future<void> _onToggle(DuoPermissionDefinition definition, bool enable) async {
    final controller = ref.read(permissionSetupControllerProvider.notifier);
    final current =
        ref.read(permissionSetupControllerProvider).statuses[definition.type] ??
            DuoPermissionStatus.notDetermined;

    if (!enable && current.isGranted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text('Turn off ${definition.title}?'),
            content: Text(
              'Android and iOS only let you disable permissions in system settings. '
              'Open settings, turn off access, then return here.',
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open settings'),
              ),
            ],
          );
        },
      );
      if (open != true || !mounted) return;
      await controller.togglePermission(definition.type, enable: false);
      return;
    }

    HapticFeedback.mediumImpact();
    final status = await controller.togglePermission(definition.type, enable: enable);
    if (!mounted) return;

    if (enable &&
        !status.isGranted &&
        (status == DuoPermissionStatus.denied || status == DuoPermissionStatus.permanentlyDenied)) {
      await showPermissionDeniedDialog(
        context,
        definition: definition,
        status: status,
        onOpenSettings: () => ref.read(permissionServiceProvider).openSystemSettings(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionSetupControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final enabledCount = state.enabledCount;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SplashBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 16, isWide ? 48 : 20, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const DuoBrandLogo(size: 34, showTagline: false),
                            const SizedBox(height: 20),
                            DuoGlassCard(
                              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                              borderRadius: 28,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Permissions',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Enable what Duo needs on this device. Toggle any item on or off — same control pattern as Settings.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: scheme.primary.withValues(alpha: 0.12),
                                    ),
                                    child: Text(
                                      '$enabledCount of ${permissionSetupOrder.length} enabled',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ...permissionSetupOrder.map((definition) {
                                    final status = state.statuses[definition.type] ??
                                        DuoPermissionStatus.notDetermined;
                                    final enabled = status.isGranted;
                                    final busy = state.requestingType == definition.type;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: PermissionToggleTile(
                                        definition: definition,
                                        status: status,
                                        enabled: enabled,
                                        isBusy: busy,
                                        onChanged: (value) => _onToggle(definition, value),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Turning a switch off opens system settings when the permission is already granted.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 8, isWide ? 48 : 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        children: [
                          OutlinedButton(
                            onPressed: state.isRequesting
                                ? null
                                : () async {
                                    HapticFeedback.selectionClick();
                                    await ref
                                        .read(permissionSetupControllerProvider.notifier)
                                        .enableAllRecommended();
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Enable recommended'),
                          ),
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: DuoGradients.brand,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FilledButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.go(AppRoutes.permissionPersonalize);
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
