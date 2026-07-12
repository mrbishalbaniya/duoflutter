import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../providers/settings_providers.dart';
import 'settings_section.dart';

class SettingsPasswordSection extends ConsumerStatefulWidget {
  const SettingsPasswordSection({super.key});

  @override
  ConsumerState<SettingsPasswordSection> createState() => _SettingsPasswordSectionState();
}

class _SettingsPasswordSectionState extends ConsumerState<SettingsPasswordSection> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(settingsControllerProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
          confirmPassword: _confirmController.text,
        );
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = _currentController.text.isNotEmpty &&
        _newController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        !ui.passwordSaving;

    return SettingsSection(
      title: 'Security',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change password',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Current password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New password'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              onChanged: (_) => setState(() {}),
            ),
            if (ui.passwordError != null) ...[
              const SizedBox(height: 10),
              Text(ui.passwordError!, style: const TextStyle(color: DuoColors.error, fontSize: 13)),
            ],
            if (ui.passwordMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                ui.passwordMessage!,
                style: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),
            DuoGradientButton(
              label: ui.passwordSaving ? 'Updating…' : 'Update password',
              loading: ui.passwordSaving,
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
