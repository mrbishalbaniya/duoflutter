import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/update_models.dart';
import '../../providers/update_providers.dart';
import '../../utils/update_utils.dart';
import '../../../settings/presentation/widgets/settings_row.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../dialogs/update_dialog.dart';

class SettingsUpdateSection extends ConsumerWidget {
  const SettingsUpdateSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final state = ref.watch(updateControllerProvider);
    final installed = state.installed;
    final latest = state.latest;

    return SettingsSection(
      title: 'App updates',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          if (installed != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current version',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${installed.version} (build ${installed.buildNumber})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (latest?.updateAvailable == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Update available',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.system_update_alt_rounded,
            title: 'Check for updates',
            description: state.lastCheckedAt == null
                ? 'Never checked'
                : 'Last checked ${_formatLastChecked(state.lastCheckedAt!)}',
            onTap: () async {
              final controller = ref.read(updateControllerProvider.notifier);
              final latest = await controller.checkForUpdates(force: true, manual: true);
              if (!context.mounted) return;
              final ui = ref.read(updateControllerProvider);
              if (ui.phase == UpdatePhase.failed && ui.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ui.error!)),
                );
                return;
              }
              if (latest == null) return;
              if (ui.phase == UpdatePhase.available || ui.hasBlockingUpdate) {
                await showUpdateDialog(context, blocking: ui.hasBlockingUpdate);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ui.message ?? 'You are up to date.')),
                );
              }
            },
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.history_rounded,
            title: 'Update history',
            description: '${state.history.length} published releases',
            onTap: () => _showHistory(context, state),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.sd_storage_outlined,
            title: 'Update storage',
            description: formatBytes(state.storageUsedBytes),
            showChevron: false,
            trailing: TextButton(
              onPressed: () => ref.read(updateControllerProvider.notifier).clearUpdateCache(),
              child: const Text('Clear'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastChecked(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showHistory(BuildContext context, UpdateUiState state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: state.history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.history[index];
              return ListTile(
                title: Text('${item.latestVersion} (build ${item.buildNumber})'),
                subtitle: Text((item.releaseNotes.isNotEmpty ? item.releaseNotes.first : 'Release').toString()),
                trailing: item.updateAvailable ? const Icon(Icons.new_releases_outlined) : null,
              );
            },
          ),
        );
      },
    );
  }
}
