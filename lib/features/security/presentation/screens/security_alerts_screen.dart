import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/security_providers.dart';

class SecurityAlertsScreen extends ConsumerWidget {
  const SecurityAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(securityEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Alerts'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(securityRepositoryProvider).markAllEventsRead();
              ref.invalidate(securityEventsProvider);
              ref.invalidate(securityOverviewProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No security alerts yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(securityEventsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = list[index];
                final scheme = Theme.of(context).colorScheme;
                final time = event.createdAt != null
                    ? DateFormat('MMM d · HH:mm').format(event.createdAt!.toLocal())
                    : '';
                return AnimatedOpacity(
                  opacity: event.isRead ? 0.7 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: Card(
                    color: event.isRead ? null : scheme.primaryContainer.withValues(alpha: 0.25),
                    child: ListTile(
                      leading: Icon(_iconFor(event.eventType), color: scheme.primary),
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([event.message, time].where((s) => s.isNotEmpty).join('\n')),
                      onTap: () async {
                        if (!event.isRead) {
                          await ref.read(securityRepositoryProvider).markEventRead(event.id);
                          ref.invalidate(securityEventsProvider);
                          ref.invalidate(securityOverviewProvider);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_login':
      case 'new_device':
        return Icons.devices_outlined;
      case 'password_changed':
        return Icons.key_outlined;
      case 'two_fa_enabled':
      case 'two_fa_disabled':
        return Icons.phonelink_lock_outlined;
      case 'biometric_enabled':
      case 'biometric_disabled':
        return Icons.fingerprint_outlined;
      case 'failed_login':
      case 'suspicious_login':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }
}
