import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/security_domain.dart';
import '../../providers/security_providers.dart';
import '../widgets/security_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(securityActionControllerProvider);
    final strength = evaluatePasswordStrength(_newController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SecurityHeroHeader(
            title: 'Update your password',
            subtitle: 'Use a strong, unique password to keep your account secure.',
            icon: Icons.key_outlined,
          ),
          const SizedBox(height: 20),
          _passwordField(
            controller: _currentController,
            label: 'Current password',
            visible: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 12),
          _passwordField(
            controller: _newController,
            label: 'New password',
            visible: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
            onChanged: (_) => setState(() {}),
          ),
          if (_newController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            PasswordStrengthMeter(score: strength.score, label: strength.label),
            const SizedBox(height: 8),
            ...strength.requirements.map(
              (r) => Row(
                children: [
                  Icon(
                    r.met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                    size: 16,
                    color: r.met ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(r.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _passwordField(
            controller: _confirmController,
            label: 'Confirm new password',
            visible: _showConfirm,
            onToggle: () => setState(() => _showConfirm = !_showConfirm),
          ),
          if (action.error != null) ...[
            const SizedBox(height: 12),
            Text(action.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (action.message != null) ...[
            const SizedBox(height: 12),
            Text(action.message!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: action.loading ? null : _submit,
            child: Text(action.loading ? 'Updating…' : 'Update password'),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      autofillHints: label.contains('Current')
          ? const [AutofillHints.password]
          : const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    final error = validatePasswordChangeForm(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    HapticFeedback.mediumImpact();
    final ok = await ref.read(securityActionControllerProvider.notifier).changePassword(
          current: _currentController.text,
          newPassword: _newController.text,
          confirm: _confirmController.text,
        );
    if (ok && mounted) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      setState(() {});
    }
  }
}
