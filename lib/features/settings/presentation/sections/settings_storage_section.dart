import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/settings_storage_service.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsStorageSection extends ConsumerWidget {
  const SettingsStorageSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(settingsStorageInfoProvider);
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Storage',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: storageAsync.when(
              loading: () => const Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Calculating cache size…'),
                ],
              ),
              error: (_, __) => Text(
                'Could not read cache size.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              data: (info) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StorageStat(label: 'Total cache', value: info.formattedTotal),
                  const SizedBox(height: 8),
                  _StorageStat(label: 'Chat cache', value: info.formattedChat),
                  const SizedBox(height: 8),
                  _StorageStat(label: 'Image cache', value: info.formattedImages),
                ],
              ),
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear cache',
            description: 'Free space by clearing chat and image caches',
            showChevron: false,
            onTap: () async {
              final confirmed = await showClearCacheDialog(context);
              if (confirmed != true || !context.mounted) return;
              HapticFeedback.mediumImpact();
              await ref.read(settingsStorageServiceProvider).clearCaches();
              ref.invalidate(settingsStorageInfoProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StorageStat extends StatelessWidget {
  const _StorageStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
