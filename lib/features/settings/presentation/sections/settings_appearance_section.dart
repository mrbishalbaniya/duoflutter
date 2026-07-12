import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_controller.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_theme_option.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Appearance',
      animationIndex: animationIndex,
      visible: visible,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SettingsThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  active: themeMode == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  },
                ),
                const SizedBox(width: 8),
                SettingsThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  active: themeMode == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  },
                ),
                const SizedBox(width: 8),
                SettingsThemeOption(
                  label: 'System',
                  icon: Icons.brightness_auto_outlined,
                  active: themeMode == ThemeMode.system,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Display preferences follow your device accessibility settings, including text scaling.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
