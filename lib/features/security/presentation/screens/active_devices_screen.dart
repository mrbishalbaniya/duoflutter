import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/security_domain.dart';
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
      appBar: AppBar(title: Text(trustedOnly ? 'Trusted Devices' : 'Active Devices')),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(trustedOnly ? 'No trusted devices yet.' : 'No active devices found.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeDevicesProvider);
              ref.invalidate(trustedDevicesProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = list[index];
                return DeviceCard(
                  deviceName: d.deviceName,
                  location: d.location,
                  osVersion: d.osVersion,
                  lastActive: formatRelativeTime(d.lastActive),
                  isCurrent: d.isCurrent,
                  isTrusted: d.isTrustedActive,
                  platform: d.platform,
                  actions: d.isCurrent
                      ? null
                      : Row(
                          children: [
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
                            TextButton(
                              onPressed: () => _logout(ref, context, d.id, d.deviceName),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _trust(WidgetRef ref, int id) async {
    await ref.read(securityRepositoryProvider).trustDevice(id);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
  }

  Future<void> _untrust(WidgetRef ref, int id) async {
    await ref.read(securityRepositoryProvider).untrustDevice(id);
    ref.invalidate(activeDevicesProvider);
    ref.invalidate(trustedDevicesProvider);
  }

  Future<void> _logout(WidgetRef ref, BuildContext context, int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout device?'),
        content: Text('Sign out $name from your Duo account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(securityRepositoryProvider).logoutDevice(id);
    ref.invalidate(activeDevicesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device signed out.')));
    }
  }
}
