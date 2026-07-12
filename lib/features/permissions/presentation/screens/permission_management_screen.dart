import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../widgets/duo_ui.dart';
import '../../models/permission_models.dart';
import '../../providers/permission_providers.dart';
import '../dialogs/permission_denied_dialog.dart';

class PermissionManagementScreen extends ConsumerWidget {
  const PermissionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Control what Duo can access on this device. Some features need specific permissions to work.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...permissionSetupOrder.map((definition) {
                final status = state.statuses[definition.type] ?? DuoPermissionStatus.notDetermined;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: definition.accent.withValues(alpha: 0.14),
                      child: Icon(definition.icon, color: definition.accent),
                    ),
                    title: Text(definition.title),
                    subtitle: Text(
                      '${definition.description}\n\nFeatures: ${definition.benefits.join(', ')}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          status.label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: status.statusColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () async {
                            HapticFeedback.selectionClick();
                            final result = await controller.request(definition.type);
                            if (!context.mounted) return;
                            if (!result.isGranted &&
                                (result == DuoPermissionStatus.denied ||
                                    result == DuoPermissionStatus.permanentlyDenied)) {
                              await showPermissionDeniedDialog(
                                context,
                                definition: definition,
                                status: result,
                                onOpenSettings: controller.openSettings,
                              );
                            }
                          },
                          child: const Text('Request'),
                        ),
                      ],
                    ),
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
