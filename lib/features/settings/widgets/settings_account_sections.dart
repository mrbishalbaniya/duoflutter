import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import 'settings_row.dart';
import 'settings_section.dart';

class SettingsVerificationSection extends StatelessWidget {
  const SettingsVerificationSection({super.key, required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Verification',
      child: isVerified
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DuoColors.esewaGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: DuoColors.esewaGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified profile',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'Your identity is verified.',
                          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : SettingsRow(
              icon: Icons.photo_camera_front_outlined,
              title: 'Verify your profile',
              description: 'Take a selfie to earn a verified badge',
              onTap: () => context.push(AppRoutes.verify),
            ),
    );
  }
}

class SettingsWalletSection extends StatelessWidget {
  const SettingsWalletSection({super.key, required this.balanceLabel});

  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Wallet',
      child: SettingsRow(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Duo Wallet',
        description: 'Top up with eSewa and buy Premium passes',
        trailing: Text(
          balanceLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: []),
        ),
        onTap: () => context.push(AppRoutes.wallet),
      ),
    );
  }
}

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.email,
    required this.onEditProfile,
    required this.onLogout,
  });

  final String email;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Account',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mail_outline, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.person_outline,
            title: 'Edit profile',
            description: 'Update photos, bio, and preferences',
            onTap: onEditProfile,
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.logout_rounded,
            title: 'Log out',
            destructive: true,
            showChevron: false,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
