import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsSecuritySection extends ConsumerWidget {
  const SettingsSecuritySection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Security',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.security_rounded,
            title: 'Security Center',
            description: '2FA, biometrics, devices, login history & alerts',
            onTap: () {
              HapticFeedback.selectionClick();
              context.push(AppRoutes.security);
            },
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.phonelink_lock_outlined,
            title: 'Two-factor authentication',
            description: 'Email OTP and authenticator app',
            onTap: () => context.push(AppRoutes.securityTwoFactor),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.fingerprint_outlined,
            title: 'Biometric login',
            description: 'Fingerprint, face unlock, or device PIN',
            onTap: () => context.push(AppRoutes.securityBiometric),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.devices_outlined,
            title: 'Active devices',
            description: 'Manage sessions and trusted devices',
            onTap: () => context.push(AppRoutes.securityDevices),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.history_rounded,
            title: 'Login history',
            description: 'Recent sign-in activity',
            onTap: () => context.push(AppRoutes.securityLoginHistory),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.key_outlined,
            title: 'Change password',
            description: 'Update your account password',
            onTap: () => context.push(AppRoutes.securityChangePassword),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.notifications_active_outlined,
            title: 'Security alerts',
            description: 'New logins, password changes, and more',
            onTap: () => context.push(AppRoutes.securityAlerts),
          ),
        ],
      ),
    );
  }
}
