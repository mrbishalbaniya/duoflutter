import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/appearance.dart';
import '../../../../core/theme/theme_controller.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final palette = paletteById(ref.watch(appearanceProvider).palette);
    final modeLabel = switch (themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System',
    };

    return SettingsSection(
      title: 'Appearance',
      animationIndex: animationIndex,
      visible: visible,
      child: SettingsRow(
        icon: Icons.palette_outlined,
        title: 'Theme',
        description: '$modeLabel · ${palette.name}',
        onTap: () => context.push(AppRoutes.settingsAppearance),
      ),
    );
  }
}
