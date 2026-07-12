import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../widgets/duo_ui.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_edit_screen.dart';
import '../profile/providers/profile_providers.dart';
import 'domain/settings_domain.dart';
import 'providers/settings_providers.dart';
import 'widgets/settings_account_sections.dart';
import 'widgets/settings_appearance_section.dart';
import 'widgets/settings_notifications_section.dart';
import 'widgets/settings_password_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = user?.profile;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            const DuoPageHeader(title: 'Settings'),
            SettingsWalletSection(
              balanceLabel: formatWalletBalance(profile?.walletBalance),
            ),
            const SizedBox(height: 20),
            SettingsVerificationSection(isVerified: profile?.isVerified ?? false),
            const SizedBox(height: 20),
            const SettingsAppearanceSection(),
            const SizedBox(height: 20),
            const SettingsNotificationsSection(),
            const SizedBox(height: 20),
            const SettingsPasswordSection(),
            const SizedBox(height: 20),
            SettingsAccountSection(
              email: user?.email ?? '—',
              onEditProfile: () => _openEditProfile(context, ref),
              onLogout: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, WidgetRef ref) async {
    try {
      final loaded = await ref.read(myProfileProvider.future);
      if (!context.mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ProfileEditScreen(initialProfile: loaded),
        ),
      );
      if (saved == true) {
        ref.invalidate(myProfileProvider);
      }
    } catch (e) {
      if (!context.mounted) return;
      final fallback = ref.read(authControllerProvider).user?.profile;
      if (fallback != null) {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ProfileEditScreen(initialProfile: fallback),
          ),
        );
        if (saved == true) {
          ref.invalidate(myProfileProvider);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open profile editor: $e')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    HapticFeedback.mediumImpact();
    await ref.read(settingsControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

