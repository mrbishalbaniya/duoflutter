import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../models/security_models.dart';
import '../../providers/security_providers.dart';
import '../widgets/security_widgets.dart';

class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(securityOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Center'),
        centerTitle: false,
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load security settings: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(securityOverviewProvider);
            await ref.read(securityOverviewProvider.future);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final content = _SecurityCenterBody(overview: data);
              if (!wide) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [content],
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [content],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SecurityCenterBody extends ConsumerWidget {
  const _SecurityCenterBody({required this.overview});

  final SecurityOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SecurityHeroHeader(
          title: 'Protect your Duo account',
          subtitle: 'Manage sign-in methods, active devices, and security alerts in one place.',
          icon: Icons.security_rounded,
        ),
        const SizedBox(height: 16),
        SettingsSection(
          title: 'Account access',
          animationIndex: 0,
          child: Column(
            children: [
              SecurityNavTile(
                icon: Icons.phonelink_lock_outlined,
                title: 'Two-Factor Authentication',
                subtitle: overview.twoFactorEnabled
                    ? 'Enabled · ${overview.twoFactorMethod ?? 'active'}'
                    : 'Add an extra layer of protection',
                trailing: SecurityStatusChip(enabled: overview.twoFactorEnabled),
                onTap: () => context.push(AppRoutes.securityTwoFactor),
              ),
              const Divider(height: 1, indent: 72),
              SecurityNavTile(
                icon: Icons.fingerprint_outlined,
                title: 'Biometric Login',
                subtitle: overview.biometricEnabled
                    ? 'Fingerprint, face, or device PIN'
                    : 'Sign in faster with biometrics',
                trailing: SecurityStatusChip(enabled: overview.biometricEnabled),
                onTap: () => context.push(AppRoutes.securityBiometric),
              ),
              const Divider(height: 1, indent: 72),
              SecurityNavTile(
                icon: Icons.key_outlined,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => context.push(AppRoutes.securityChangePassword),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSection(
          title: 'Devices & sessions',
          animationIndex: 1,
          child: Column(
            children: [
              SecurityNavTile(
                icon: Icons.devices_outlined,
                title: 'Active Devices',
                subtitle: '${overview.activeDevices} device(s) · ${overview.activeSessions} session(s)',
                onTap: () => context.push(AppRoutes.securityDevices),
              ),
              const Divider(height: 1, indent: 72),
              SecurityNavTile(
                icon: Icons.verified_user_outlined,
                title: 'Trusted Devices',
                subtitle: 'Devices that skip extra verification',
                onTap: () => context.push('${AppRoutes.securityDevices}?trusted=1'),
              ),
              const Divider(height: 1, indent: 72),
              SecurityNavTile(
                icon: Icons.history_rounded,
                title: 'Login History',
                subtitle: 'Review recent sign-in activity',
                onTap: () => context.push(AppRoutes.securityLoginHistory),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsSection(
          title: 'Alerts & actions',
          animationIndex: 2,
          child: Column(
            children: [
              SecurityNavTile(
                icon: Icons.notifications_active_outlined,
                title: 'Security Alerts',
                subtitle: overview.unreadAlerts > 0
                    ? '${overview.unreadAlerts} unread alert(s)'
                    : 'New logins, password changes, and more',
                trailing: overview.unreadAlerts > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.error,
                        child: Text(
                          '${overview.unreadAlerts}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
                onTap: () => context.push(AppRoutes.securityAlerts),
              ),
              const Divider(height: 1, indent: 72),
              SecurityNavTile(
                icon: Icons.logout_rounded,
                title: 'Logout From All Devices',
                subtitle: 'Sign out everywhere except this device',
                destructive: true,
                onTap: () => _showLogoutAllDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutAllDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout from all devices?'),
        content: const Text(
          'This will invalidate all active sessions and refresh tokens. '
          'You can choose to keep this device signed in.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logoutAll(context, ref, keepCurrent: true);
            },
            child: const Text('Keep this device'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logoutAll(context, ref, keepCurrent: false);
            },
            child: const Text('Logout all'),
          ),
        ],
      ),
    );
  }

  void _logoutAll(BuildContext context, WidgetRef ref, {required bool keepCurrent}) {
    ref.read(securityActionControllerProvider.notifier).logoutAll(keepCurrent: keepCurrent).then((ok) {
      if (!context.mounted) return;
      final state = ref.read(securityActionControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message ?? state.error ?? 'Done')),
      );
      if (ok) ref.invalidate(securityOverviewProvider);
    });
  }
}
