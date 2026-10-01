import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/notification_models.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/settings_providers.dart';
import '../sections/settings_notifications_section.dart';
import '../widgets/settings_section.dart';

/// Server-side notification and email preferences, shared by the push and
/// email preference screens.
class NotificationPrefsNotifier extends AutoDisposeAsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() {
    return ref.read(notificationRepositoryProvider).getPreferences();
  }

  /// Optimistic update; rolls back and rethrows if the server rejects it.
  Future<void> setPref(String key, bool value) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(NotificationPreferences.fromJson({...previous.toJson(), key: value}));
    try {
      state = AsyncData(await ref.read(notificationRepositoryProvider).updatePreferences({key: value}));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final notificationPrefsProvider =
    AsyncNotifierProvider.autoDispose<NotificationPrefsNotifier, NotificationPreferences>(
  NotificationPrefsNotifier.new,
);

const _pushCategoryRows = <(String, String, String)>[
  ('sound_enabled', 'Notification sound', 'Play a sound when notifications arrive'),
  ('chat_enabled', 'Messages', 'Chat and reactions'),
  ('calls_enabled', 'Calls', 'Incoming and missed call alerts'),
  ('match_enabled', 'Matches', 'New mutual matches'),
  ('likes_enabled', 'Likes', 'Likes and profile views'),
  ('verification_enabled', 'Verification', 'Photo and identity updates'),
  ('payment_enabled', 'Payments', 'Wallet and subscription alerts'),
  ('announcements_enabled', 'Announcements', 'System and admin updates'),
  ('marketing_enabled', 'Marketing', 'Tips, offers, and Duo news'),
  ('vibration_enabled', 'Vibration', 'Vibrate when supported on this device'),
];

/// Mirrors the web `/notifications` preferences page.
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  String? _saving;

  Future<void> _update(String key, bool value) async {
    setState(() => _saving = key);
    try {
      await ref.read(notificationPrefsProvider.notifier).setPref(key, value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your notification preferences.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          IconButton(
            tooltip: 'Notification history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Manage how and when you receive notifications',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SettingsNotificationsSection(
            animationIndex: 0,
            title: 'Push notifications',
            showHistoryLink: false,
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Notification categories',
            child: prefsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Could not load your preferences.'),
                    TextButton(
                      onPressed: () => ref.invalidate(notificationPrefsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (prefs) {
                final enabled = prefs.pushEnabled;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        'Choose which types of notifications you want to receive',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    for (final (i, row) in _pushCategoryRows.indexed) ...[
                      if (i > 0) const SettingsDivider(),
                      Material(
                        type: MaterialType.transparency,
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: prefs.valueFor(row.$1),
                          onChanged: !enabled || _saving != null ? null : (v) => _update(row.$1, v ?? false),
                          title: Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(row.$3),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Notification preferences only apply when push notifications are enabled. '
                    'You can customize categories based on your interests.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
