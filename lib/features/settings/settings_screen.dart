import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.dark;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _changingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() => _changingPassword = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Duo Wallet'),
            subtitle: Text('NPR ${user?.profile.walletBalance ?? 0}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.wallet),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Identity verification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.verify),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Appearance', style: Theme.of(context).textTheme.labelLarge),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {_themeMode},
            onSelectionChanged: (s) => setState(() => _themeMode = s.first),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Change password', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _changingPassword ? null : _changePassword,
                  child: Text(_changingPassword ? 'Updating…' : 'Update password'),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class VerifyPlaceholderScreen extends StatelessWidget {
  const VerifyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Liveness verification with camera will be implemented in Phase 2, '
            'using the existing /api/verification/ endpoints.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
