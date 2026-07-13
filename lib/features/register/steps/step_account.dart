import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
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
    ref.read(registrationControllerProvider.notifier).patchData(
          (d) => d.copyWith(otpVerified: true, signedUpWithGoogle: false),
        );
    HapticFeedback.mediumImpact();
    await widget.onContinue();
    setState(() => _formError = null);
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
      subtitle: 'Sign up with Google or register with your email and password.',
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
          if (AppConfig.isGoogleAuthConfigured) ...[
            GoogleSignInButton(
              loading: _googleLoading,
              enabled: true,
              onPressed: _signInWithGoogle,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or register with email',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 20),
          ],
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
          ),
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
