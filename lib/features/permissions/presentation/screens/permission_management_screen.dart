import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../widgets/duo_ui.dart';
import '../../models/permission_models.dart';
import '../../providers/permission_providers.dart';
import '../dialogs/permission_denied_dialog.dart';
import '../widgets/permission_toggle_tile.dart';

class PermissionManagementScreen extends ConsumerStatefulWidget {
  const PermissionManagementScreen({super.key});

  @override
  ConsumerState<PermissionManagementScreen> createState() => _PermissionManagementScreenState();
}

class _PermissionManagementScreenState extends ConsumerState<PermissionManagementScreen>
    with WidgetsBindingObserver {
  DuoPermissionType? _busyType;

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
      ref.read(permissionManagementControllerProvider.notifier).refresh();
    }
  }

  Future<void> _onToggle(DuoPermissionDefinition definition, bool enable) async {
    final controller = ref.read(permissionManagementControllerProvider.notifier);
    final current =
        ref.read(permissionManagementControllerProvider).statuses[definition.type] ??
            DuoPermissionStatus.notDetermined;

    if (!enable && current.isGranted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Turn off ${definition.title}?'),
          content: const Text(
            'Open system settings to disable this permission, then return to Duo.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open settings')),
          ],
        ),
      );
      if (open == true) await controller.openSettings();
      return;
    }

    setState(() => _busyType = definition.type);
    HapticFeedback.selectionClick();
    try {
      final result = await controller.request(definition.type);
      if (!mounted) return;
      if (!result.isGranted &&
          (result == DuoPermissionStatus.denied || result == DuoPermissionStatus.permanentlyDenied)) {
        await showPermissionDeniedDialog(
          context,
          definition: definition,
          status: result,
          onOpenSettings: controller.openSettings,
        );
      }
    } finally {
      if (mounted) setState(() => _busyType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionManagementControllerProvider);
    final controller = ref.read(permissionManagementControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        centerTitle: false,
      ),
      body: DuoAmbientBackground(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Enable or disable what Duo can access on this device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                '${state.statuses.values.where((s) => s.isGranted).length} of ${permissionSetupOrder.length} enabled',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...permissionSetupOrder.map((definition) {
                final status = state.statuses[definition.type] ?? DuoPermissionStatus.notDetermined;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PermissionToggleTile(
                    definition: definition,
                    status: status,
                    enabled: status.isGranted,
                    isBusy: _busyType == definition.type || state.isRefreshing,
                    onChanged: (value) => _onToggle(definition, value),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await controller.openSettings();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open system app settings'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await controller.resetSetupFlow();
                  if (!context.mounted) return;
                  context.go(AppRoutes.permissionWelcome);
                },
                child: const Text('Run permission setup again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
