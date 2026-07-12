import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/notification_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../providers/settings_providers.dart';
import 'settings_section.dart';

class SettingsNotificationsSection extends ConsumerWidget {
  const SettingsNotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final status = ui.pushStatus;

    return SettingsSection(
      title: 'Notifications',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: DuoColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: DuoColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Push notifications',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get beautiful alerts for likes, new matches, and messages on this device.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildBody(context, ref, ui, status),
                  ),
                  if (ui.pushError != null) ...[
                    const SizedBox(height: 10),
                    Text(ui.pushError!, style: const TextStyle(color: DuoColors.error, fontSize: 13)),
                  ],
                  if (ui.pushMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      ui.pushMessage!,
                      style: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/notifications'),
                    child: const Text('View notification history'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    SettingsUiState ui,
    PushStatus status,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (ui.pushLoading) {
      return const Row(
        key: ValueKey('push-loading'),
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Checking support…'),
        ],
      );
    }

    if (!status.supported) {
      return Text(
        'This device does not support push notifications.',
        key: const ValueKey('push-unsupported'),
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      );
    }

    if (!status.configured) {
      return Text(
        'Push is not configured yet. Ask an admin to enable Firebase in integration settings.',
        key: const ValueKey('push-unconfigured'),
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      );
    }

    return Wrap(
      key: const ValueKey('push-controls'),
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (status.enabled)
          OutlinedButton(
            onPressed: ui.pushSaving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(settingsControllerProvider.notifier).togglePushNotifications();
                  },
            child: Text(ui.pushSaving ? 'Updating…' : 'Turn off notifications'),
          )
        else
          DuoGradientButton(
            label: ui.pushSaving ? 'Updating…' : 'Enable notifications',
            loading: ui.pushSaving,
            onPressed: ui.pushSaving
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(settingsControllerProvider.notifier).togglePushNotifications();
                  },
          ),
        Text(
          status.enabled ? 'Enabled' : 'Disabled',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
