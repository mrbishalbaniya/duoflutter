import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../dialogs/settings_dialogs.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsSecuritySection extends ConsumerStatefulWidget {
  const SettingsSecuritySection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  ConsumerState<SettingsSecuritySection> createState() => _SettingsSecuritySectionState();
}

class _SettingsSecuritySectionState extends ConsumerState<SettingsSecuritySection> {
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
      setState(() {});
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
      animationIndex: widget.animationIndex,
      visible: widget.visible,
      child: Column(
        children: [
          Padding(
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
                  Text(
                    ui.passwordError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                if (ui.passwordMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    ui.passwordMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: Text(ui.passwordSaving ? 'Updating…' : 'Update password'),
                ),
              ],
            ),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.phonelink_lock_outlined,
            title: 'Two-factor authentication',
            description: 'Extra protection for your account',
            enabled: false,
            showChevron: false,
            trailing: _ComingSoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Two-factor authentication'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.fingerprint_outlined,
            title: 'Biometric login',
            description: 'Use fingerprint or face unlock',
            enabled: false,
            showChevron: false,
            trailing: _ComingSoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Biometric login'),
          ),
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.devices_outlined,
            title: 'Login devices',
            description: 'Manage active sessions',
            enabled: false,
            showChevron: false,
            trailing: _ComingSoonBadge(),
            onTap: () => showSettingsComingSoonDialog(context, title: 'Login devices'),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
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
