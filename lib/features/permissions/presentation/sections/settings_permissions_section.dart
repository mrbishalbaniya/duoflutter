import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/permission_models.dart';
import '../../providers/permission_providers.dart';
import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../screens/permission_management_screen.dart';

class SettingsPermissionsSection extends ConsumerWidget {
  const SettingsPermissionsSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();

    final snapshot = ref.watch(permissionStatusesSnapshotProvider);
    final grantedCount = snapshot.maybeWhen(
      data: (statuses) => statuses.values.where((s) => s.isGranted).length,
      orElse: () => 0,
    );

    return SettingsSection(
      title: 'Permissions',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App access',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$grantedCount of ${permissionSetupOrder.length} permissions allowed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Manage permissions',
            description: 'View status, re-request access, or open Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
