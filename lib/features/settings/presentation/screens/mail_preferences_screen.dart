import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';
import 'notification_preferences_screen.dart';

const _emailCategories = <(String, IconData, String, String)>[
  ('email_matches', Icons.favorite_border_rounded, 'New matches', 'When you and someone like each other'),
  ('email_payments', Icons.receipt_long_outlined, 'Payments and receipts', 'Subscription payments, coin recharges and wallet receipts'),
  ('email_verification', Icons.verified_outlined, 'Verification updates', 'When your verified badge is added or removed'),
  ('email_announcements', Icons.campaign_outlined, 'Announcements', 'Important news and updates from the Duo team'),
  ('email_marketing', Icons.local_offer_outlined, 'Offers and tips', 'Promotions, discounts and dating tips'),
];

/// Mirrors the web `/settings/mails` page.
class MailPreferencesScreen extends ConsumerStatefulWidget {
  const MailPreferencesScreen({super.key});

  @override
  ConsumerState<MailPreferencesScreen> createState() => _MailPreferencesScreenState();
}

class _MailPreferencesScreenState extends ConsumerState<MailPreferencesScreen> {
  String? _saving;

  Future<void> _update(String key, bool value) async {
    setState(() => _saving = key);
    try {
      await ref.read(notificationPrefsProvider.notifier).setPref(key, value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save that change. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final email = ref.watch(authControllerProvider).user?.email;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Email notifications')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your email preferences.'),
              TextButton(
                onPressed: () => ref.invalidate(notificationPrefsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) {
          final masterOn = prefs.emailEnabled;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (email?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                  child: Text.rich(
                    TextSpan(
                      text: 'Emails are sent to ',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: email,
                          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              SettingsSection(
                title: 'Email',
                child: SettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Email notifications',
                  description: 'Turn off to stop all optional emails from Duo.',
                  showChevron: false,
                  trailing: Switch(
                    value: masterOn,
                    onChanged: _saving == 'email_enabled' ? null : (v) => _update('email_enabled', v),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SettingsSection(
                title: 'What to email me about',
                child: Opacity(
                  opacity: masterOn ? 1 : 0.6,
                  child: Column(
                    children: [
                      for (final (i, c) in _emailCategories.indexed) ...[
                        if (i > 0) const SettingsDivider(),
                        SettingsRow(
                          icon: c.$2,
                          title: c.$3,
                          description: c.$4,
                          showChevron: false,
                          trailing: Switch(
                            value: masterOn && prefs.valueFor(c.$1),
                            onChanged: !masterOn || _saving == c.$1 ? null : (v) => _update(c.$1, v),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!masterOn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    'Turn on email notifications to choose individual categories.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 20),
              SettingsSection(
                title: 'Always sent',
                child: Column(
                  children: [
                    for (final (i, a) in const [
                      (Icons.lock_outline, 'Security codes', 'Sign-in codes, password resets and email changes'),
                      (Icons.manage_accounts_outlined, 'Account status', 'If your account is deactivated or restored'),
                    ].indexed) ...[
                      if (i > 0) const SettingsDivider(),
                      SettingsRow(
                        icon: a.$1,
                        title: a.$2,
                        description: a.$3,
                        showChevron: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Always on', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
