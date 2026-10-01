import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/duo_coin.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Web settings: Wallet, Verification, Account and Match Preferences sections.
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.balanceLabel,
    required this.isVerified,
    required this.animationIndex,
    this.visible = true,
  });

  final String balanceLabel;
  final bool isVerified;
  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final gap = visible ? const SizedBox(height: 20) : const SizedBox.shrink();
    return Column(
      children: [
        SettingsSection(
          title: 'Wallet',
          animationIndex: animationIndex,
          visible: visible,
          child: SettingsRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Duo Wallet',
            description: 'Buy coins and spend on Premium',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DuoCoin(size: 18),
                const SizedBox(width: 6),
                Text(
                  balanceLabel.replaceAll(' coins', ''),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            onTap: () => context.push(AppRoutes.wallet),
          ),
        ),
        gap,
        SettingsSection(
          title: 'Verification',
          animationIndex: animationIndex,
          visible: visible,
          child: isVerified
              ? const _VerifiedTile()
              : SettingsRow(
                  icon: Icons.photo_camera_front_outlined,
                  title: 'Verify your profile',
                  description: 'Take a selfie to earn a verified badge',
                  onTap: () => context.push(AppRoutes.verify),
                ),
        ),
        gap,
        SettingsSection(
          title: 'Account',
          animationIndex: animationIndex + 1,
          visible: visible,
          child: SettingsRow(
            icon: Icons.person_outline,
            title: 'Account information',
            description: 'Email, username, phone & verification',
            onTap: () => context.push(AppRoutes.account),
          ),
        ),
        gap,
        SettingsSection(
          title: 'Match Preferences',
          animationIndex: animationIndex + 2,
          visible: visible,
          child: SettingsRow(
            icon: Icons.favorite_border_rounded,
            title: 'Partner preferences',
            description: 'Religion, caste, rashi, age, height and more',
            onTap: () => context.push(AppRoutes.matchPreferences),
          ),
        ),
      ],
    );
  }
}

class _VerifiedTile extends StatelessWidget {
  const _VerifiedTile();

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
                  'Verified Profile',
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
