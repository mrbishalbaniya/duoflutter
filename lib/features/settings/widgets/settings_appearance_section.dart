import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../../../widgets/theme_option.dart';
import 'settings_section.dart';

class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: 'Appearance',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  active: themeMode == ThemeMode.dark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                  },
                ),
                const SizedBox(width: 8),
                ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  active: themeMode == ThemeMode.light,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                  },
                ),
                const SizedBox(width: 8),
                ThemeOption(
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
          ],
        ),
      ),
    );
  }
}
