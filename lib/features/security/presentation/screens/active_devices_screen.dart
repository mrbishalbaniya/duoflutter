import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/security_domain.dart';
import '../../models/security_models.dart';
import '../../providers/security_providers.dart';
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
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(trustedOnly ? 'No trusted devices yet.' : 'No active devices found.'),
            );
          }
          final current = list.where((d) => d.isCurrent).toList();
          final others = list.where((d) => !d.isCurrent).toList();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeDevicesProvider);
              ref.invalidate(trustedDevicesProvider);
            },
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
              onPressed: () => _trust(ref, d.id),
              child: const Text('Trust'),
            ),
          if (d.isTrustedActive)
            TextButton(
              onPressed: () => _untrust(ref, d.id),
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
    if (name == null || name.isEmpty) return;
    await ref.read(securityRepositoryProvider).renameDevice(device.id, name);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
  }

  Future<void> _trust(WidgetRef ref, int id) async {
    await ref.read(securityRepositoryProvider).trustDevice(id);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
    ref.invalidate(securityOverviewProvider);
  }

  Future<void> _untrust(WidgetRef ref, int id) async {
    await ref.read(securityRepositoryProvider).untrustDevice(id);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
    ref.invalidate(securityOverviewProvider);
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
    if (ok != true) return;
    await ref.read(securityRepositoryProvider).logoutDevice(id);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(securityOverviewProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device signed out.')));
    }
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
    if (ok != true) return;
    final revoked = await ref.read(securityRepositoryProvider).logoutAllDevices(keepCurrent: true);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(securityOverviewProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed out $revoked other device(s).')),
      );
    }
  }
}
