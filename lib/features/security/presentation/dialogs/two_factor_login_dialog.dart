import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/security_models.dart';

/// Collects a 2FA / backup code during email-password login.
Future<String?> showTwoFactorLoginDialog(
  BuildContext context, {
  required TwoFactorLoginChallenge challenge,
  required Future<void> Function() onResendEmailOtp,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TwoFactorLoginDialog(
      challenge: challenge,
      onResendEmailOtp: onResendEmailOtp,
    ),
  );
}

class _TwoFactorLoginDialog extends StatefulWidget {
  const _TwoFactorLoginDialog({
    required this.challenge,
    required this.onResendEmailOtp,
  });

  final TwoFactorLoginChallenge challenge;
  final Future<void> Function() onResendEmailOtp;

  @override
  State<_TwoFactorLoginDialog> createState() => _TwoFactorLoginDialogState();
}

class _TwoFactorLoginDialogState extends State<_TwoFactorLoginDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _resending = false;
  String? _error;

  bool get _isEmail => widget.challenge.methods.contains('email');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(_controller.text.trim());
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await widget.onResendEmailOtp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final methodLabel = _isEmail
        ? 'email'
        : widget.challenge.methods.contains('totp')
            ? 'authenticator app'
            : 'backup code';

    return AlertDialog(
      title: const Text('Two-factor authentication'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the verification code from your $methodLabel to finish signing in.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                labelText: 'Verification code',
                hintText: '6-digit or backup code',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 4) return 'Enter a valid code';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
            ],
            if (_isEmail) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Sending…' : 'Resend email code'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}
