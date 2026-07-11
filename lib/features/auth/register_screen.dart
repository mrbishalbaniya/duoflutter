import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../widgets/google_sign_in_button.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      setState(() => _otpSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your email.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_otpSent && _otpController.text.trim().isNotEmpty) {
        await auth.verifyEmailOtp(
          email: _emailController.text,
          otp: _otpController.text.trim(),
        );
      }
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (mounted) context.go(AppRoutes.match);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithGoogle();
      if (mounted) context.go(AppRoutes.match);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('StateError: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (AppConfig.isGoogleAuthConfigured) ...[
                  GoogleSignInButton(
                    loading: _googleLoading,
                    enabled: !_loading,
                    onPressed: _signInWithGoogle,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or register with email',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4))),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Email is required' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: Text(_otpSent ? 'Resend code' : 'Send verification code'),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Email OTP'),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Use at least 8 characters' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading || _googleLoading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
