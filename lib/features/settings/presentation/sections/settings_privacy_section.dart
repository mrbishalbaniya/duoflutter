import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../map/widgets/location_privacy_section.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsPrivacySection extends StatelessWidget {
  const SettingsPrivacySection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

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
            // Open the real controls here (pushing the Map tab route would
            // stack a second copy of that tab on top of Settings).
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const _LocationPrivacyScreen()),
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: 'Chat privacy',
            description: 'Screenshot alerts and secure chat per conversation',
            // Secure chat / screenshot alerts live in each conversation's
            // menu, so switch to the Chat tab.
            onTap: () => context.go(AppRoutes.chat),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.block_outlined,
            title: 'Blocked users',
            description: 'Manage people you have blocked',
            onTap: () => context.push(AppRoutes.blockedUsers),
          ),
        ],
      ),
    );
  }
}

class _LocationPrivacyScreen extends StatelessWidget {
  const _LocationPrivacyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location privacy')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: const [LocationPrivacySection()],
      ),
    );
  }
}
