import 'package:flutter/material.dart';

import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsDangerZoneSection extends StatelessWidget {
  const SettingsDangerZoneSection({
    super.key,
    required this.onLogout,
    required this.animationIndex,
    this.visible = true,
  });

  final VoidCallback onLogout;
  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Danger zone',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.logout_rounded,
            title: 'Log out',
            destructive: true,
            showChevron: false,
            onTap: onLogout,
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.delete_forever_outlined,
            title: 'Delete account',
            description: 'Permanently remove your account and data',
            destructive: true,
            enabled: false,
            showChevron: false,
            trailing: _SoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Delete account'),
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
