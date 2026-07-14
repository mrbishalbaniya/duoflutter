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
        _SecurityScoreCard(overview: overview),
        if (overview.recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RecommendationsCard(overview: overview),
        ],
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

class _SecurityScoreCard extends StatelessWidget {
  const _SecurityScoreCard({required this.overview});

  final SecurityOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final score = overview.securityScore.clamp(0, 100);
    final color = score >= 80
        ? Colors.green
        : score >= 50
            ? scheme.tertiary
            : scheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 7,
                    color: color,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Text(
                    '$score%',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security score',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    score >= 80
                        ? 'Your account is well protected.'
                        : 'Improve your score by completing the recommendations below.',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsCard extends ConsumerWidget {
  const _RecommendationsCard({required this.overview});

  final SecurityOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final rec in overview.recommendations.take(4)) ...[
            ListTile(
              leading: Icon(_iconFor(rec.action)),
              title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(rec.description),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _open(context, rec.action),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String action) {
    switch (action) {
      case 'two_factor':
        return Icons.phonelink_lock_outlined;
      case 'biometric':
        return Icons.fingerprint_outlined;
      case 'devices':
        return Icons.devices_outlined;
      case 'email':
        return Icons.mark_email_read_outlined;
      case 'phone':
        return Icons.phone_iphone_outlined;
      default:
        return Icons.shield_outlined;
    }
  }

  void _open(BuildContext context, String action) {
    switch (action) {
      case 'two_factor':
        context.push(AppRoutes.securityTwoFactor);
      case 'biometric':
        context.push(AppRoutes.securityBiometric);
      case 'devices':
        context.push(AppRoutes.securityDevices);
      default:
        break;
    }
  }
}
