import 'package:flutter/material.dart';

import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsLanguageSection extends StatelessWidget {
  const SettingsLanguageSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Language',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.language_rounded,
            title: 'App language',
            description: 'English (device default)',
            enabled: false,
            showChevron: false,
            trailing: _SoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'App language'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.public_outlined,
            title: 'Region',
            description: 'Nepal',
            enabled: false,
            showChevron: false,
            trailing: _SoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Region'),
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
