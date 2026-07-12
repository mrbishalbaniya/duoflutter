import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

final settingsPackageInfoProvider = FutureProvider.autoDispose<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsAboutSection extends ConsumerWidget {
  const SettingsAboutSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(settingsPackageInfoProvider);

    return SettingsSection(
      title: 'About',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy policy',
            onTap: () => showSettingsComingSoonDialog(context, title: 'Privacy policy'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.description_outlined,
            title: 'Terms of service',
            onTap: () => showSettingsComingSoonDialog(context, title: 'Terms of service'),
          ),
          const SettingsDivider(),
          packageAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Loading version…'),
                ],
              ),
            ),
            error: (_, __) => SettingsRow(
              icon: Icons.info_outline,
              title: 'Version',
              description: AppConfig.appName,
              showChevron: false,
            ),
            data: (info) => SettingsRow(
              icon: Icons.info_outline,
              title: 'Version',
              description: '${info.version} (${info.buildNumber})',
              showChevron: false,
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.article_outlined,
            title: 'Open source licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Duo',
            ),
          ),
        ],
      ),
    );
  }
}
