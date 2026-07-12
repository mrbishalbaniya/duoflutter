import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsPrivacySection extends StatelessWidget {
  const SettingsPrivacySection({
    super.key,
    required this.onEditProfile,
    required this.animationIndex,
    this.visible = true,
  });

  final VoidCallback onEditProfile;
  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Privacy',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.map_outlined,
            title: 'Location privacy',
            description: 'Control who sees you on the map',
            onTap: () => context.push(AppRoutes.map),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.tune_rounded,
            title: 'Discovery preferences',
            description: 'Age range, distance, and match filters',
            onTap: onEditProfile,
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: 'Chat privacy',
            description: 'Screenshot alerts and secure chat per conversation',
            onTap: () => context.push(AppRoutes.chat),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.block_outlined,
            title: 'Blocked users',
            description: 'Manage people you have blocked',
            enabled: false,
            showChevron: false,
            trailing: _SoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Blocked users'),
          ),
        ],
      ),
    );
  }
}

class _SoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
