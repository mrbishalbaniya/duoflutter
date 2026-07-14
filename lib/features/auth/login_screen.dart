import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_theme.dart';
import '../../widgets/duo_ui.dart';
import '../../widgets/google_sign_in_button.dart';
import '../security/presentation/dialogs/two_factor_login_dialog.dart';
import '../security/providers/security_providers.dart';
import 'auth_controller.dart';
import 'domain/login_domain.dart';
import 'providers/login_providers.dart';
import 'widgets/login_alert_banner.dart';
import 'widgets/login_brand_header.dart';
import 'widgets/login_footer_links.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

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
    if (mounted) {
      setState(() => _biometricAvailable = enabled && caps.supported);
    }
  }

  void _readQueryParams() {
    final params = GoRouterState.of(context).uri.queryParameters;
    if (params['reset'] == 'success') {
      ref.read(loginControllerProvider.notifier).showPasswordResetBanner();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

    final ui = ref.read(loginControllerProvider);
    final challenge = ui.pendingChallenge;
    if (challenge == null) return;

    final code = await showTwoFactorLoginDialog(
      context,
      challenge: challenge,
      onResendEmailOtp: controller.resendTwoFactorOtp,
    );
    if (!mounted || code == null || code.isEmpty) {
      controller.clearChallenge();
      return;
    }

    final verified = await controller.completeTwoFactor(code);
    if (verified && mounted) {
      HapticFeedback.mediumImpact();
      _navigateAfterAuth();
    }
  }

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
    final next = sanitizeNextPath(GoRouterState.of(context).uri.queryParameters['next']);

    if (next != null) {
      context.go(next);
      return;
    }

    final onboarded = user?.profile.isOnboarded ?? false;
    context.go(onboarded ? AppRoutes.match : AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(loginControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DuoAmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        const LoginBrandHeader(),
                        const SizedBox(height: 40),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: DuoGlassCard(
                                padding: const EdgeInsets.all(28),
                                child: Form(
                                  key: _formKey,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Welcome back',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Please enter your details to continue',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 24),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 240),
                                        child: ui.showPasswordResetSuccess
                                            ? const Padding(
                                                key: ValueKey('success'),
                                                padding: EdgeInsets.only(bottom: 16),
                                                child: LoginSuccessBanner(
                                                  message:
                                                      'Your password has been updated. Sign in with your new password.',
                                                ),
                                              )
                                            : const SizedBox.shrink(key: ValueKey('no-success')),
                                      ),
                                      if (ui.error != null) ...[
                                        LoginErrorBanner(message: ui.error!),
                                        const SizedBox(height: 16),
                                      ],
                                      _LoginField(
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
                                      Row(
                                        children: [
                                          Text(
                                            'Password',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: ui.isBusy
                                                ? null
                                                : () => context.push(AppRoutes.forgotPassword),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: DuoColors.accent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _LoginField(
                                        controller: _passwordController,
                                        label: '',
                                        hint: 'Your password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        autofillHints: const [AutofillHints.password],
                                        textInputAction: TextInputAction.done,
                                        validator: validateLoginPassword,
                                        enabled: !ui.isBusy,
                                        onFieldSubmitted: (_) => _submit(),
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          onPressed: ui.isBusy
                                              ? null
                                              : () => setState(
                                                    () => _obscurePassword = !_obscurePassword,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      DuoGradientButton(
                                        label: ui.isLoading ? 'Signing in…' : 'Login',
                                        loading: ui.isLoading,
                                        onPressed: ui.isBusy ? null : _submit,
                                      ),
                                      if (_biometricAvailable) ...[
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          onPressed: ui.isBusy ? null : _signInWithBiometric,
                                          icon: ui.isBiometricLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.fingerprint_rounded),
                                          label: Text(
                                            ui.isBiometricLoading
                                                ? 'Verifying…'
                                                : 'Sign in with biometrics',
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: scheme.outline.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              'OR',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    letterSpacing: 1.4,
                                                    fontWeight: FontWeight.w800,
                                                    color: scheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: scheme.outline.withValues(alpha: 0.25),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      if (AppConfig.isGoogleAuthConfigured)
                                        GoogleSignInButton(
                                          loading: ui.isGoogleLoading,
                                          enabled: !ui.isBusy,
                                          onPressed: _signInWithGoogle,
                                        )
                                      else
                                        Text(
                                          'Google sign-in is not configured for this build.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 360.ms, delay: 80.ms)
                                  .slideY(begin: 0.06, end: 0, duration: 400.ms),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'New to Duo?',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: ui.isBusy ? null : () => context.push(AppRoutes.register),
                              child: Text(
                                'Create an account',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: DuoColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const LoginFooterLinks(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.validator,
    this.enabled = true,
    this.suffix,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            suffixIcon: suffix,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.55), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
