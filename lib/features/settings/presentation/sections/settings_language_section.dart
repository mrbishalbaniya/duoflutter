import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../widgets/duo_ui.dart';
import '../../../auth/auth_controller.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Web `LanguageRegionPage`: `app_language` / `app_region` saved on the profile
/// and shared across devices.
const _languages = <(String, String, String)>[
  ('en', 'English', 'English'),
  ('ne', 'Nepali', 'नेपाली'),
];
const _regions = ['Nepal', 'India', 'United States', 'United Kingdom', 'Australia', 'Other'];

class SettingsLanguageSection extends ConsumerWidget {
  const SettingsLanguageSection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  Future<void> _save(BuildContext context, WidgetRef ref, Map<String, dynamic> payload, String done) async {
    final ok = await runWithFeedback(
      context,
      () => ref.read(profileRepositoryProvider).updateProfile(payload),
      success: done,
    );
    if (ok && context.mounted) await ref.read(authControllerProvider.notifier).refreshUser();
  }

  Future<String?> _pick(
    BuildContext context, {
    required String title,
    String? note,
    required List<(String value, String label, String? subtitle)> options,
    required String selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(note, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(
                children: [
                  for (final (value, label, subtitle) in options)
                    RadioListTile<String>(
                      value: value,
                      title: Text(label),
                      subtitle: subtitle == null ? null : Text(subtitle),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider.select((s) => s.user?.profile));
    final language = profile?.appLanguage ?? 'en';
    final region = profile?.appRegion ?? 'Nepal';
    final languageLabel = _languages.firstWhere((l) => l.$1 == language, orElse: () => _languages.first);

    return SettingsSection(
      title: 'Language',
      animationIndex: animationIndex,
      visible: visible,
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.language_rounded,
            title: 'App language',
            description: '${languageLabel.$2} · ${languageLabel.$3}',
            onTap: profile == null
                ? null
                : () async {
                    final next = await _pick(
                      context,
                      title: 'App language',
                      note: 'Saved to your account and used by Duo on the web. '
                          'The Android app is currently shown in English.',
                      options: [for (final l in _languages) (l.$1, l.$2, l.$3)],
                      selected: language,
                    );
                    if (next == null || next == language || !context.mounted) return;
                    await _save(context, ref, {'app_language': next}, 'Language updated');
                  },
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.public_outlined,
            title: 'Region',
            description: region,
            onTap: profile == null
                ? null
                : () async {
                    final next = await _pick(
                      context,
                      title: 'Region',
                      note: 'Used for formats and regional content across your devices.',
                      options: [for (final r in _regions) (r, r, null)],
                      selected: _regions.contains(region) ? region : 'Other',
                    );
                    if (next == null || next == region || !context.mounted) return;
                    await _save(context, ref, {'app_region': next}, 'Region updated');
                  },
          ),
        ],
      ),
    );
  }
}
