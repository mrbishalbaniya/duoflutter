import 'package:flutter/material.dart';

import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsHelpSection extends StatelessWidget {
  const SettingsHelpSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Help',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Help center',
            description: 'Guides and troubleshooting',
            onTap: () => showSettingsComingSoonDialog(context, title: 'Help center'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.support_agent_outlined,
            title: 'Contact support',
            description: 'Get help from the Duo team',
            onTap: () => showSettingsComingSoonDialog(context, title: 'Contact support'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.quiz_outlined,
            title: 'FAQ',
            description: 'Answers to common questions',
            onTap: () => showSettingsComingSoonDialog(context, title: 'FAQ'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.bug_report_outlined,
            title: 'Report a bug',
            description: 'Tell us what went wrong',
            onTap: () => showSettingsComingSoonDialog(context, title: 'Report a bug'),
          ),
        ],
      ),
    );
  }
}
