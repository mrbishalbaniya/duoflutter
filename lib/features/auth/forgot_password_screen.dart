import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/otp_cooldown_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_theme.dart';
import '../../core/widgets/otp_code_input.dart';
import '../../widgets/duo_ui.dart';
import '../register/registration_validators.dart';
import 'widgets/auth_text_field.dart';

enum _Step { email, code, password }

/// Mirrors web `/login/forgot-password`: email → 6-digit code boxes →
/// new password (with strength), resend cooldown, and invalid codes sent
/// back to the code step.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpKey = GlobalKey<OtpCodeInputState>();
  late final _cooldown = ResendCountdown(() {
    if (mounted) setState(() {});
  });

  _Step _step = _Step.email;
  String _otp = '';
  OtpStatus _otpStatus = OtpStatus.idle;
  String _otpError = '';
  bool _loading = false;
  bool _sending = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cooldown.stop();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _toast('Enter a valid email');
      return;
    }
    setState(() => _loading = true);
    try {
      final retry = await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      _toast('Reset code sent if the email exists.');
      setState(() => _step = _Step.code);
      _cooldown.start(retry);
    } on OtpCooldownException catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.code);
      _cooldown.start(e.retryAfter);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message.isNotEmpty ? e.message : 'Could not send reset code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown.seconds > 0 || _sending) return;
    setState(() => _sending = true);
    try {
      final retry = await ref.read(authRepositoryProvider).requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      _toast('Reset code sent if the email exists.');
      _cooldown.start(retry);
    } on OtpCooldownException catch (e) {
      _cooldown.start(e.retryAfter);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message.isNotEmpty ? e.message : 'Could not resend code. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onCode(String code) => setState(() {
        _otp = code;
        _otpStatus = OtpStatus.idle;
        _otpError = '';
        _step = _Step.password;
      });

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      _toast('Password must be at least 8 characters');
      return;
    }
    if (password != _confirmController.text) {
      _toast('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            otp: _otp,
            password: password,
          );
      if (mounted) context.go('${AppRoutes.login}?reset=success');
    } on ApiException catch (e) {
      // Code and password are validated together, so a bad code surfaces here:
      // go back to the code boxes and show the error there (web behaviour).
      if (!mounted) return;
      setState(() {
        _step = _Step.code;
        _otpStatus = OtpStatus.error;
        _otpError = e.message.isNotEmpty ? e.message : 'Could not reset password. Please try again.';
        _otp = '';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useDifferentEmail() {
    _cooldown.stop();
    setState(() {
      _step = _Step.email;
      _otp = '';
      _passwordController.clear();
      _confirmController.clear();
      _otpStatus = OtpStatus.idle;
      _otpError = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final email = _emailController.text.trim();

    final title = switch (_step) {
      _Step.email => 'Forgot Password',
      _Step.code => 'Reset Code',
      _Step.password => 'Set New Password',
    };
    final description = _step == _Step.email
        ? "Enter your email and we'll send you a code to reset your password."
        : 'We sent a 6-digit code to $email. Enter it below along with your new password.';

    return Scaffold(
      body: DuoAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Login',
                  onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const DuoLogoMark(size: 72),
                          const SizedBox(height: 6),
                          Text(
                            'Reset your password',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 36),
                          DuoGlassCard(
                            padding: const EdgeInsets.all(28),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(description, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
                                  const SizedBox(height: 24),
                                  switch (_step) {
                                    _Step.email => _emailStep(),
                                    _Step.code => _codeStep(scheme),
                                    _Step.password => _passwordStep(scheme),
                                  },
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, end: 0),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () => context.go(AppRoutes.login),
                            icon: const Icon(Icons.arrow_back, size: 18),
                            label: const Text('Back to Login'),
                            style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          enabled: !_loading,
          onFieldSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 24),
        DuoGradientButton(
          label: _loading ? 'Sending...' : 'Send Reset Code',
          loading: _loading,
          onPressed: _loading ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _codeStep(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpCodeInput(
          key: _otpKey,
          label: 'Reset Code',
          status: _otpStatus,
          errorMessage: _otpError,
          disabled: _loading,
          onComplete: _onCode,
        ),
        const SizedBox(height: 20),
        _footerRow(
          scheme,
          left: ('Use a different email', _useDifferentEmail),
          right: (
            _sending
                ? 'Resending...'
                : _cooldown.seconds > 0
                    ? 'Resend code in ${_cooldown.seconds}s'
                    : 'Resend Code',
            _sending || _cooldown.seconds > 0 ? null : _resend,
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(ColorScheme scheme) {
    final password = _passwordController.text;
    final strength = getPasswordStrength(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _passwordController,
          label: 'New Password',
          hint: 'Create a strong password',
          icon: Icons.lock_outline,
          obscureText: !_showPassword,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          enabled: !_loading,
          suffix: IconButton(
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
        if (password.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Strength: ${strength.label}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _confirmController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline,
          obscureText: !_showConfirm,
          textInputAction: TextInputAction.done,
          enabled: !_loading,
          onFieldSubmitted: (_) => _resetPassword(),
          suffix: IconButton(
            icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _showConfirm = !_showConfirm),
          ),
        ),
        const SizedBox(height: 24),
        DuoGradientButton(
          label: _loading ? 'Updating...' : 'Update Password',
          loading: _loading,
          onPressed: _loading ? null : _resetPassword,
        ),
        const SizedBox(height: 12),
        _footerRow(
          scheme,
          left: (
            'Use a different code',
            () => setState(() {
                  _step = _Step.code;
                  _otp = '';
                  _otpStatus = OtpStatus.idle;
                  _otpError = '';
                }),
          ),
          right: ('Use a different email', _useDifferentEmail),
        ),
      ],
    );
  }

  Widget _footerRow(
    ColorScheme scheme, {
    required (String, VoidCallback?) left,
    required (String, VoidCallback?) right,
  }) {
    return Row(
      children: [
        TextButton(
          onPressed: left.$2,
          child: Text(left.$1,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
        ),
        const Spacer(),
        TextButton(
          onPressed: right.$2,
          child: Text(right.$1,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DuoColors.accent)),
        ),
      ],
    );
  }
}
