import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/security_domain.dart';
import '../../models/security_models.dart';
import '../../providers/security_providers.dart';
import '../../../../widgets/duo_ui.dart';
import '../widgets/security_widgets.dart';

class ActiveDevicesScreen extends ConsumerWidget {
  const ActiveDevicesScreen({super.key, this.trustedOnly = false});

  final bool trustedOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = trustedOnly
        ? ref.watch(trustedDevicesProvider)
        : ref.watch(activeDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(trustedOnly ? 'Trusted Devices' : 'Active Devices'),
        actions: [
          if (!trustedOnly)
            TextButton(
              onPressed: () => _logoutOthers(context, ref),
              child: const Text('Sign out others'),
            ),
        ],
      ),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DuoStateView.error(e, onRetry: () => _refresh(ref)),
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(ref),
              child: DuoStateView(
                icon: Icons.devices_other,
                title: trustedOnly ? 'No trusted devices yet' : 'No active devices found',
              ),
            );
          }
          final current = list.where((d) => d.isCurrent).toList();
          final others = list.where((d) => !d.isCurrent).toList();
          return RefreshIndicator(
            onRefresh: () async => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (current.isNotEmpty) ...[
                  Text('Current device', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...current.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _deviceCard(context, ref, d),
                      )),
                ],
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Other devices', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...others.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _deviceCard(context, ref, d),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
    ref.invalidate(securityOverviewProvider);
  }

  Widget _deviceCard(BuildContext context, WidgetRef ref, UserDevice d) {
    return DeviceCard(
      deviceName: d.deviceName,
      location: d.locationLabel,
      osVersion: d.osVersion.isNotEmpty ? d.osVersion : d.platformLabel,
      lastActive: formatRelativeTime(d.lastActive),
      isCurrent: d.isCurrent,
      isTrusted: d.isTrustedActive,
      platform: d.platform,
      actions: Row(
        children: [
          TextButton(
            onPressed: () => _rename(context, ref, d),
            child: const Text('Rename'),
          ),
          if (!d.isTrustedActive)
            TextButton(
              onPressed: () => _trust(context, ref, d.id),
              child: const Text('Trust'),
            ),
          if (d.isTrustedActive)
            TextButton(
              onPressed: () => _untrust(context, ref, d.id),
              child: const Text('Untrust'),
            ),
          if (!d.isCurrent)
            TextButton(
              onPressed: () => _logout(ref, context, d.id, d.deviceName),
              child: const Text('Sign out'),
            ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, UserDevice device) async {
    final controller = TextEditingController(text: device.deviceName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Device name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    await runWithFeedback(
      context,
      () => ref.read(securityRepositoryProvider).renameDevice(device.id, name),
      success: 'Device renamed.',
    );
    if (!context.mounted) return;
    _refresh(ref);
  }

  Future<void> _trust(BuildContext context, WidgetRef ref, int id) async {
    await runWithFeedback(
      context,
      () => ref.read(securityRepositoryProvider).trustDevice(id),
      success: 'Device trusted.',
    );
    if (!context.mounted) return;
    _refresh(ref);
  }

  Future<void> _untrust(BuildContext context, WidgetRef ref, int id) async {
    await runWithFeedback(
      context,
      () => ref.read(securityRepositoryProvider).untrustDevice(id),
      success: 'Device no longer trusted.',
    );
    if (!context.mounted) return;
    _refresh(ref);
  }

  Future<void> _logout(WidgetRef ref, BuildContext context, int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out device?'),
        content: Text('Sign out $name from your Duo account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await runWithFeedback(
      context,
      () => ref.read(securityRepositoryProvider).logoutDevice(id),
      success: 'Device signed out.',
    );
    if (!context.mounted) return;
    _refresh(ref);
  }

  Future<void> _logoutOthers(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: const Text('This keeps the current device signed in and revokes every other session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out others')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    var revoked = 0;
    final done = await runWithFeedback(context, () async {
      revoked = await ref.read(securityRepositoryProvider).logoutAllDevices(keepCurrent: true);
    });
    if (!context.mounted) return;
    _refresh(ref);
    if (done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed out $revoked other device(s).')),
      );
    }
  }
}
