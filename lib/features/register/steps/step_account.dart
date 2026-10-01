import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/otp_cooldown_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/otp_code_input.dart';
import '../../../widgets/google_sign_in_button.dart';
import '../../auth/auth_controller.dart';
import '../registration_controller.dart';
import '../registration_models.dart';
import '../registration_validators.dart';
import '../widgets/duo_phone_field.dart';
import '../widgets/registration_widgets.dart';

class StepAccount extends ConsumerStatefulWidget {
  const StepAccount({super.key, required this.onContinue, this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback? onBack;

  @override
  ConsumerState<StepAccount> createState() => _StepAccountState();
}

class _StepAccountState extends ConsumerState<StepAccount> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _phone = '';
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _googleLoading = false;
  String? _formError;
  String? _googleError;
  String? _phoneFieldError;

  // Email verification (web "Verify your email" sub-step).
  final _otpKey = GlobalKey<OtpCodeInputState>();
  bool _otpSending = false;
  bool _otpVerifying = false;
  OtpStatus _otpStatus = OtpStatus.idle;
  String _otpError = '';
  late final _cooldown = ResendCountdown(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    final data = ref.read(registrationControllerProvider).data;
    _phone = data.phone;
    _emailController.text = data.email;
    _passwordController.text = data.password;
    _confirmController.text = data.confirmPassword;
  }

  @override
  void dispose() {
    _cooldown.stop();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _patchFromForm({bool signedUpWithGoogle = false}) {
    ref.read(registrationControllerProvider.notifier).patchData(
          (d) => d.copyWith(
            phone: _phone.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
            confirmPassword: _confirmController.text,
            signedUpWithGoogle: signedUpWithGoogle,
          ),
        );
  }

  Future<void> _submitAccountForm() async {
    HapticFeedback.selectionClick();
    _phoneFieldError = null;
    _formError = validateAccount(
      phone: _phone.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );
    if (_formError != null) {
      if (_formError!.toLowerCase().contains('mobile')) {
        _phoneFieldError = _formError;
      }
      setState(() {});
      return;
    }
    _patchFromForm();
    final email = _emailController.text.trim().toLowerCase();
    final current = ref.read(registrationControllerProvider).data;
    final alreadyVerified = current.otpVerified && current.verifiedEmail == email;
    final controller = ref.read(registrationControllerProvider.notifier);
    controller.patchData(
      (d) => d.copyWith(
        signedUpWithGoogle: false,
        otpVerified: alreadyVerified,
        verifiedEmail: alreadyVerified ? email : '',
      ),
    );
    setState(() => _formError = null);
    if (alreadyVerified) {
      HapticFeedback.mediumImpact();
      await widget.onContinue();
      return;
    }
    setState(() {
      _otpStatus = OtpStatus.idle;
      _otpError = '';
    });
    if (await _sendCode(email)) controller.setAccountSubStep(AccountSubStep.otp);
  }

  /// Sends the email code; true when the user can now enter one.
  Future<bool> _sendCode(String email) async {
    setState(() => _otpSending = true);
    try {
      final retry = await ref.read(authRepositoryProvider).sendEmailOtp(email);
      _cooldown.start(retry);
      _toast('We sent a 6-digit code to $email.');
      return true;
    } on OtpCooldownException catch (e) {
      // A code is already on its way; let the user enter it.
      _cooldown.start(e.retryAfter);
      return true;
    } on ApiException catch (e) {
      _toast(e.message.isNotEmpty ? e.message : 'Could not send verification code.');
      return false;
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyCode(String code) async {
    final email = ref.read(registrationControllerProvider).data.email.trim().toLowerCase();
    setState(() {
      _otpVerifying = true;
      _otpStatus = OtpStatus.idle;
      _otpError = '';
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(email: email, otp: code);
      if (!mounted) return;
      setState(() => _otpStatus = OtpStatus.success);
      final controller = ref.read(registrationControllerProvider.notifier);
      controller.patchData((d) => d.copyWith(otpVerified: true, verifiedEmail: email));
      _toast("Email verified. Let's build your profile.");
      controller.setAccountSubStep(AccountSubStep.form);
      HapticFeedback.mediumImpact();
      await widget.onContinue();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _otpStatus = OtpStatus.error;
        _otpError = e.message.isNotEmpty ? e.message : 'Invalid or expired verification code.';
      });
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _otpVerifying = false);
    }
  }

  Widget _otpStep(BuildContext context, RegistrationState reg) {
    final scheme = Theme.of(context).colorScheme;
    final email = reg.data.email;
    return RegistrationStepCard(
      title: 'Verify your email',
      subtitle: 'Enter the 6-digit code we sent to $email. You can continue once your email is verified.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_email_unread_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code sent to', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      Text(email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OtpCodeInput(
            key: _otpKey,
            status: _otpStatus,
            errorMessage: _otpError,
            disabled: _otpVerifying,
            onComplete: _verifyCode,
          ),
          const SizedBox(height: 12),
          if (_otpVerifying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verifying...', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Checking your code', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            )
          else
            Text(
              "The code expires in 10 minutes. Check your spam folder if you don't see it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ref.read(registrationControllerProvider.notifier).setAccountSubStep(AccountSubStep.form);
                  setState(() {
                    _otpStatus = OtpStatus.idle;
                    _otpError = '';
                  });
                },
                child: Text('Change email',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _otpSending || _cooldown.seconds > 0
                    ? null
                    : () async {
                        setState(() {
                          _otpStatus = OtpStatus.idle;
                          _otpError = '';
                        });
                        _otpKey.currentState?.clear();
                        await _sendCode(email);
                      },
                child: Text(
                  _otpSending
                      ? 'Sending…'
                      : _cooldown.seconds > 0
                          ? 'Resend code in ${_cooldown.seconds}s'
                          : 'Resend code',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitGooglePhone() async {
    final error = validateGooglePhone(_phone.trim());
    if (error != null) {
      setState(() {
        _formError = error;
        _phoneFieldError = error;
      });
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData(
          (d) => d.copyWith(phone: _phone.trim()),
        );
    HapticFeedback.mediumImpact();
    await widget.onContinue();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _googleError = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
      final user = ref.read(authControllerProvider).user;
      final email = (user?.email ?? '').trim().toLowerCase();
      final fullName = user?.profile.fullName ?? '';
      final parts = fullName.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      ref.read(registrationControllerProvider.notifier)
        ..patchData(
          (d) => d.copyWith(
            email: email,
            signedUpWithGoogle: true,
            otpVerified: true,
            verifiedEmail: email,
            password: '',
            confirmPassword: '',
            firstName: d.firstName.isNotEmpty ? d.firstName : firstName,
            lastName: d.lastName.isNotEmpty ? d.lastName : lastName,
          ),
        )
        ..setAccountCreated(true)
        ..setAccountSubStep(AccountSubStep.phone);
      HapticFeedback.mediumImpact();
    } on ApiException catch (e) {
      setState(() => _googleError = e.message);
    } catch (e) {
      setState(() => _googleError = e.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(registrationControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final strength = getPasswordStrength(_passwordController.text);

    if (reg.accountSubStep == AccountSubStep.otp && !reg.data.signedUpWithGoogle) {
      return _otpStep(context, reg);
    }

    if (reg.accountSubStep == AccountSubStep.phone) {
      return RegistrationStepCard(
        title: 'Add your mobile number',
        subtitle:
            'Your Google email is already verified. We only need your phone number to continue.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reg.data.email.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signed in with Google', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    Text(reg.data.email, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            DuoPhoneField(
              value: _phone,
              onChanged: (value) => setState(() {
                _phone = value;
                _phoneFieldError = null;
                _formError = null;
              }),
              errorText: _phoneFieldError,
            ),
            RegistrationFieldError(message: _formError),
            RegistrationStepNavigation(
              showBack: true,
              onBack: () =>
                  ref.read(registrationControllerProvider.notifier).setAccountSubStep(AccountSubStep.form),
              onNext: _submitGooglePhone,
            ),
          ],
        ),
      );
    }

    return RegistrationStepCard(
      title: 'Create your account',
      subtitle: 'Register with your email and password, or sign up with Google.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_googleError != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_googleError!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          DuoPhoneField(
            value: _phone,
            onChanged: (value) => setState(() {
              _phone = value;
              _phoneFieldError = null;
            }),
            errorText: _phoneFieldError,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a strong password',
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Password strength', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(strength.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: strength.score / 5,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmController,
            obscureText: !_showConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              hintText: 'Re-enter your password',
              suffixIcon: IconButton(
                icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ),
          ),
          RegistrationFieldError(message: _formError),
          RegistrationStepNavigation(
            showBack: widget.onBack != null,
            onBack: widget.onBack,
            onNext: _submitAccountForm,
            loading: _otpSending,
            nextLabel: reg.data.otpVerified &&
                    reg.data.verifiedEmail == _emailController.text.trim().toLowerCase()
                ? 'Continue'
                : 'Send code',
          ),
          if (AppConfig.isGoogleAuthConfigured) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: scheme.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 20),
            GoogleSignInButton(
              loading: _googleLoading,
              enabled: !_googleLoading,
              onPressed: _signInWithGoogle,
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
