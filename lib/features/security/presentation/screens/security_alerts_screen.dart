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
                final severityColor = switch (event.severity) {
                  'critical' => scheme.error,
                  'warning' => scheme.tertiary,
                  _ => scheme.primary,
                };
                return Dismissible(
                  key: ValueKey('alert-${event.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                  ),
                  onDismissed: (_) async {
                    await ref.read(securityRepositoryProvider).deleteEvent(event.id);
                    ref.invalidate(securityEventsProvider);
                    ref.invalidate(securityOverviewProvider);
                  },
                  child: AnimatedOpacity(
                    opacity: event.isRead ? 0.72 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Card(
                      color: event.isRead ? null : severityColor.withValues(alpha: 0.12),
                      child: ListTile(
                        leading: Icon(_iconFor(event.eventType), color: severityColor),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          [
                            event.message,
                            if (event.severity.isNotEmpty) event.severity.toUpperCase(),
                            time,
                          ].where((s) => s.isNotEmpty).join('\n'),
                        ),
                        onTap: () async {
                          if (!event.isRead) {
                            await ref.read(securityRepositoryProvider).markEventRead(event.id);
                            ref.invalidate(securityEventsProvider);
                            ref.invalidate(securityOverviewProvider);
                          }
                        },
                      ),
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
      case 'suspicious_login':
      case 'failed_login':
        return Icons.warning_amber_rounded;
      default:
        return Icons.shield_outlined;
    }
  }
}
