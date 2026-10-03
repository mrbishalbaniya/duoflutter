import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/otp_cooldown_exception.dart';
import '../../core/network/two_factor_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_theme.dart';
import '../../core/widgets/otp_code_input.dart';
import '../../widgets/duo_ui.dart';
import '../../widgets/google_sign_in_button.dart';
import '../security/models/security_models.dart';
import '../security/providers/security_providers.dart';
import 'auth_controller.dart';
import 'domain/login_domain.dart';
import 'providers/login_providers.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/login_alert_banner.dart';
import 'widgets/login_brand_header.dart';
import 'widgets/login_footer_links.dart';

enum _AuthMode { password, otp }

/// Mirrors web `/login`: password sign-in, "Sign in with email code",
/// inline two-factor step, Google, plus mobile biometrics.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpEmailController = TextEditingController();
  final _twoFactorController = TextEditingController();
  final _otpKey = GlobalKey<OtpCodeInputState>();
  late final _cooldown = ResendCountdown(() {
    if (mounted) setState(() {});
  });

  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _accountDeleted = false;

  _AuthMode _mode = _AuthMode.password;
  bool _otpSent = false;
  bool _otpSending = false;
  bool _otpVerifying = false;
  OtpStatus _otpStatus = OtpStatus.idle;
  String _otpError = '';
  String _otpResendMessage = '';

  TwoFactorLoginChallenge? _twoFactor;
  bool _twoFactorBusy = false;
  bool _resendingTwoFactor = false;
  String _twoFactorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readQueryParams();
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    final bio = ref.read(biometricAuthServiceProvider);
    final enabled = await bio.isLocallyEnabled();
    final caps = await bio.getCapabilities();
    if (mounted) setState(() => _biometricAvailable = enabled && caps.supported);
  }

  void _readQueryParams() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['reset'] == 'success') {
      ref.read(loginControllerProvider.notifier).showPasswordResetBanner();
    }
    if (params['deleted'] == '1') setState(() => _accountDeleted = true);
  }

  @override
  void dispose() {
    _cooldown.stop();
    _emailController.dispose();
    _passwordController.dispose();
    _otpEmailController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Password -----------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final controller = ref.read(loginControllerProvider.notifier);
    final success = await controller.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
      return;
    }
    final challenge = ref.read(loginControllerProvider).pendingChallenge;
    if (challenge != null) setState(() => _twoFactor = challenge);
  }

  // --- Two-factor (inline, like web) -----------------------------------------

  Future<void> _submitTwoFactor() async {
    final challenge = _twoFactor;
    final code = _twoFactorController.text.trim();
    if (challenge == null || code.isEmpty) return;
    setState(() => _twoFactorBusy = true);
    try {
      await ref.read(authControllerProvider.notifier).completeTwoFactorLogin(
            challengeToken: challenge.challengeToken,
            code: code,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Invalid verification code.');
    } finally {
      if (mounted) setState(() => _twoFactorBusy = false);
    }
  }

  Future<void> _resendTwoFactor() async {
    final challenge = _twoFactor;
    if (challenge == null) return;
    setState(() {
      _resendingTwoFactor = true;
      _twoFactorMessage = '';
    });
    try {
      await ref.read(authRepositoryProvider).sendTwoFactorLoginOtp(challenge.challengeToken);
      if (mounted) setState(() => _twoFactorMessage = 'A new code was sent to your email.');
    } catch (_) {
      if (mounted) setState(() => _twoFactorMessage = 'Could not resend the code. Please try again.');
    } finally {
      if (mounted) setState(() => _resendingTwoFactor = false);
    }
  }

  void _backToPassword() {
    ref.read(loginControllerProvider.notifier).clearChallenge();
    setState(() {
      _twoFactor = null;
      _twoFactorController.clear();
      _twoFactorMessage = '';
    });
  }

  // --- Email code -------------------------------------------------------------

  Future<void> _sendLoginOtp({bool resend = false}) async {
    final email = _otpEmailController.text.trim();
    if (email.isEmpty) {
      _toast('Email is required.');
      return;
    }
    if (resend && (_cooldown.seconds > 0 || _otpSending)) return;
    setState(() {
      _otpSending = true;
      _otpResendMessage = '';
    });
    try {
      final retry = await ref.read(authControllerProvider.notifier).requestLoginOtp(email);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpStatus = OtpStatus.idle;
        _otpError = '';
        if (resend) _otpResendMessage = 'A new code was sent to your email.';
      });
      _cooldown.start(retry);
    } on OtpCooldownException catch (e) {
      // A code was sent recently: let them enter it; the countdown shows the wait.
      if (!mounted) return;
      setState(() => _otpSent = true);
      _cooldown.start(e.retryAfter);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (resend) {
        setState(() => _otpResendMessage = 'Could not resend the code. Please try again.');
      } else {
        _toast(e.message.isNotEmpty ? e.message : 'Could not send login code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  Future<void> _verifyLoginOtp(String code) async {
    if (code.length != 6 || _otpVerifying) return;
    setState(() => _otpVerifying = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithOtp(_otpEmailController.text.trim(), code);
      if (!mounted) return;
      setState(() => _otpStatus = OtpStatus.success);
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
    } on TwoFactorRequiredException catch (e) {
      if (mounted) setState(() => _twoFactor = e.challenge);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _otpStatus = OtpStatus.error;
        _otpError = e.message.isNotEmpty ? e.message : 'Invalid or expired code.';
      });
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _otpVerifying = false);
    }
  }

  void _switchMode(_AuthMode mode) {
    ref.read(loginControllerProvider.notifier).clearError();
    _cooldown.stop();
    setState(() {
      _mode = mode;
      _otpSent = false;
      _otpStatus = OtpStatus.idle;
      _otpError = '';
      _otpResendMessage = '';
      if (mode == _AuthMode.password) _otpEmailController.clear();
    });
  }

  // --- Other sign-in methods ---------------------------------------------------

  Future<void> _signInWithBiometric() async {
    HapticFeedback.lightImpact();
    final success = await ref.read(loginControllerProvider.notifier).signInWithBiometric();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
    }
  }

  Future<void> _signInWithGoogle() async {
    HapticFeedback.lightImpact();
    final success = await ref.read(loginControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
    }
  }

  void _navigateAfterAuth() {
    final user = ref.read(authControllerProvider).user;
    final onboarded = user?.profile.isOnboarded ?? false;
    if (!onboarded) {
      context.go(AppRoutes.register);
      return;
    }
    final next = sanitizeNextPath(GoRouterState.of(context).uri.queryParameters['next']);
    context.go(next ?? AppRoutes.match);
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(loginControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final twoFactor = _twoFactor;

    final title = twoFactor != null
        ? 'Two-factor verification'
        : _mode == _AuthMode.otp
            ? 'Sign in with a code'
            : 'Welcome back';
    final subtitle = twoFactor != null
        ? (twoFactor.methods.contains('totp')
            ? 'Enter the 6-digit code from your authenticator app.'
            : 'Enter the 6-digit code we emailed you.')
        : _mode == _AuthMode.otp
            ? (_otpSent
                ? 'Enter the 6-digit code we sent to ${_otpEmailController.text.trim()}.'
                : "Enter your email and we'll send you a one-time login code.")
            : 'Please enter your details to continue';

    final Widget body;
    if (twoFactor != null) {
      body = _twoFactorForm(twoFactor, scheme);
    } else if (_mode == _AuthMode.otp) {
      body = _otpForm(scheme, ui);
    } else {
      body = _passwordForm(scheme, ui);
    }

    return Scaffold(
      body: SizedBox.expand(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          const LoginBrandHeader(),
                          const SizedBox(height: 40),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: DuoGlassCard(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                                    const SizedBox(height: 24),
                                    if (ui.showPasswordResetSuccess) ...[
                                      const LoginSuccessBanner(
                                        message: 'Your password has been updated. Sign in with your new password.',
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (_accountDeleted) ...[
                                      const LoginSuccessBanner(
                                        message: 'Your account has been deactivated. Sorry to see you go.',
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (ui.error != null && twoFactor == null) ...[
                                      LoginErrorBanner(message: ui.error!),
                                      const SizedBox(height: 16),
                                    ],
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      child: KeyedSubtree(
                                        key: ValueKey('${twoFactor != null}-$_mode-$_otpSent'),
                                        child: body,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 360.ms, delay: 80.ms)
                                  .slideY(begin: 0.06, end: 0, duration: 400.ms),
                            ),
                          ),
                          if (twoFactor == null) ...[
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'New to Duo?',
                                  style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                                ),
                                TextButton(
                                  onPressed: ui.isBusy ? null : () => context.push(AppRoutes.register),
                                  child: Text(
                                    'Create an account',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: DuoColors.accent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const LoginFooterLinks(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _orDivider(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: [
            Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.25))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.25))),
          ],
        ),
      );

  /// Dark pill like the web "Sign in with email code" / "Use your password" buttons.
  Widget _altButton({required IconData icon, required String label, VoidCallback? onPressed}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF131314),
          foregroundColor: const Color(0xFFE3E3E3),
          side: const BorderSide(color: Color(0xFF747775)),
          shape: const StadiumBorder(),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _google(LoginUiState ui, {bool disabled = false}) {
    if (!AppConfig.isGoogleAuthConfigured) {
      return Text(
        'Google sign-in is not configured for this build.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return GoogleSignInButton(
      loading: ui.isGoogleLoading,
      enabled: !ui.isBusy && !disabled,
      onPressed: _signInWithGoogle,
    );
  }

  Widget _passwordForm(ColorScheme scheme, LoginUiState ui) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: validateLoginEmail,
            enabled: !ui.isBusy,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Your password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            validator: validateLoginPassword,
            enabled: !ui.isBusy,
            onFieldSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
              onPressed: ui.isBusy ? null : () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: ui.isBusy ? null : () => context.push(AppRoutes.forgotPassword),
              child: Text(
                'Forgot password?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DuoColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DuoGradientButton(
            label: ui.isLoading ? 'Signing in...' : 'Login',
            loading: ui.isLoading,
            onPressed: ui.isBusy ? null : _submit,
          ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: ui.isBusy ? null : _signInWithBiometric,
              icon: ui.isBiometricLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.fingerprint_rounded),
              label: Text(ui.isBiometricLoading ? 'Verifying…' : 'Sign in with biometrics'),
            ),
          ],
          _orDivider(scheme),
          _altButton(
            icon: Icons.alternate_email_rounded,
            label: 'Sign in with email code',
            onPressed: ui.isBusy ? null : () => _switchMode(_AuthMode.otp),
          ),
          const SizedBox(height: 12),
          _google(ui),
        ],
      ),
    );
  }

  Widget _otpForm(ColorScheme scheme, LoginUiState ui) {
    final busy = _otpSending || _otpVerifying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_otpSent) ...[
          AuthTextField(
            controller: _otpEmailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            enabled: !_otpSending,
            onFieldSubmitted: (_) => _sendLoginOtp(),
          ),
          const SizedBox(height: 24),
          DuoGradientButton(
            label: _otpSending ? 'Sending...' : 'Send login code',
            loading: _otpSending,
            onPressed: _otpSending ? null : _sendLoginOtp,
          ),
        ] else ...[
          OtpCodeInput(
            key: _otpKey,
            status: _otpStatus,
            errorMessage: _otpError,
            disabled: _otpVerifying,
            onComplete: _verifyLoginOtp,
          ),
          if (_otpResendMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _otpResendMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DuoColors.accent),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  _cooldown.stop();
                  setState(() {
                    _otpSent = false;
                    _otpStatus = OtpStatus.idle;
                    _otpError = '';
                    _otpResendMessage = '';
                  });
                },
                child: Text(
                  'Use a different email',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _otpSending || _cooldown.seconds > 0 ? null : () => _sendLoginOtp(resend: true),
                child: Text(
                  _otpSending
                      ? 'Sending...'
                      : _cooldown.seconds > 0
                          ? 'Resend code in ${_cooldown.seconds}s'
                          : 'Resend code',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        _orDivider(scheme),
        _altButton(
          icon: Icons.lock_outline,
          label: 'Use your password instead',
          onPressed: busy ? null : () => _switchMode(_AuthMode.password),
        ),
        const SizedBox(height: 12),
        _google(ui, disabled: busy),
      ],
    );
  }

  Widget _twoFactorForm(TwoFactorLoginChallenge challenge, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: _twoFactorController,
          label: 'Verification code',
          hint: '000000',
          icon: Icons.password_rounded,
          textInputAction: TextInputAction.done,
          enabled: !_twoFactorBusy,
          onFieldSubmitted: (_) => _submitTwoFactor(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'You can also enter one of your backup recovery codes.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        if (_twoFactorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              _twoFactorMessage,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DuoColors.accent),
            ),
          ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: _twoFactorController,
          builder: (context, _) => DuoGradientButton(
            label: _twoFactorBusy ? 'Verifying...' : 'Verify and sign in',
            loading: _twoFactorBusy,
            onPressed: _twoFactorBusy || _twoFactorController.text.trim().isEmpty ? null : _submitTwoFactor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: _backToPassword,
              child: Text(
                'Back to login',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
              ),
            ),
            const Spacer(),
            if (challenge.methods.contains('email'))
              TextButton(
                onPressed: _resendingTwoFactor ? null : _resendTwoFactor,
                child: Text(
                  _resendingTwoFactor ? 'Sending...' : 'Resend code',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DuoColors.accent),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
