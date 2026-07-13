import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.email,
    required this.username,
    required this.phoneLabel,
    required this.balanceLabel,
    required this.isVerified,
    required this.onEditProfile,
    required this.animationIndex,
    this.visible = true,
  });

  final String email;
  final String? username;
  final String phoneLabel;
  final String balanceLabel;
  final bool isVerified;
  final VoidCallback onEditProfile;
  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSection(
          title: 'Wallet',
          animationIndex: animationIndex,
          visible: visible,
          child: SettingsRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Duo Wallet',
            description: 'Buy coins with eSewa and spend on Premium',
            trailing: Text(
              balanceLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            onTap: () => context.push(AppRoutes.wallet),
          ),
        ),
        const SizedBox(height: 20),
        SettingsSection(
          title: 'Verification',
          animationIndex: animationIndex + 1,
          visible: visible,
          child: isVerified ? _VerifiedTile() : SettingsRow(
            icon: Icons.photo_camera_front_outlined,
            title: 'Verify your profile',
            description: 'Take a selfie to earn a verified badge',
            onTap: () => context.push(AppRoutes.verify),
          ),
        ),
        const SizedBox(height: 20),
        SettingsSection(
          title: 'Account',
          animationIndex: animationIndex + 2,
          visible: visible,
          child: Column(
            children: [
              SettingsInfoTile(icon: Icons.mail_outline, title: 'Email', value: email),
              const SettingsDivider(),
              SettingsInfoTile(
                icon: Icons.alternate_email_rounded,
                title: 'Username',
                value: username?.isNotEmpty == true ? '@$username' : 'Not set',
              ),
              const SettingsDivider(),
              SettingsInfoTile(icon: Icons.phone_outlined, title: 'Phone', value: phoneLabel),
              const SettingsDivider(),
              SettingsRow(
                icon: Icons.person_outline,
                title: 'Edit profile',
                description: 'Update photos, bio, and preferences',
                onTap: onEditProfile,
              ),
              const SettingsDivider(),
              SettingsRow(
                icon: Icons.badge_outlined,
                title: 'Personal information',
                description: 'Name, birthday, location, and more',
                onTap: onEditProfile,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerifiedTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.tertiary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, color: scheme.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Your identity is verified.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
