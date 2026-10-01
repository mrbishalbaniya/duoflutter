import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

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
            icon: Icons.delete_forever_outlined,
            title: 'Delete account',
            description: 'Permanently remove your account and data',
            destructive: true,
            onTap: () => context.push(AppRoutes.deleteAccount),
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
