import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/security_providers.dart';
import '../widgets/security_widgets.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _disablePasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _codeController.dispose();
    _disablePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(securityOverviewProvider);
    final state = ref.watch(twoFactorControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (ov) {
          if (ov.twoFactorEnabled && state.step == TwoFactorStep.intro) {
            return _buildManageView(context, ov.twoFactorMethod);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildStep(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManageView(BuildContext context, String? method) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SecurityHeroHeader(
          title: '2FA is enabled',
          subtitle: 'Your account requires a verification code when signing in.',
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 16),
        if (method != null)
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Method'),
            subtitle: Text(method.toUpperCase()),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _disablePasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password to disable 2FA'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: ref.watch(twoFactorControllerProvider).loading
              ? null
              : () => ref.read(twoFactorControllerProvider.notifier).disable(_disablePasswordController.text),
          child: const Text('Disable 2FA'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _regenerateCodes(context),
          child: const Text('Regenerate backup codes'),
        ),
      ],
    );
  }

  Future<void> _regenerateCodes(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Regenerate backup codes'),
          content: TextField(
            controller: c,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Confirm')),
          ],
        );
      },
    );
    if (password == null || password.isEmpty) return;
    try {
      final codes = await ref.read(securityRepositoryProvider).regenerateBackupCodes(password);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New backup codes'),
          content: SingleChildScrollView(child: Text(codes.join('\n'))),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _buildStep(BuildContext context, TwoFactorState state) {
    switch (state.step) {
      case TwoFactorStep.intro:
        return Column(
          key: const ValueKey('intro'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SecurityHeroHeader(
              title: 'Secure your account',
              subtitle: 'Enable two-factor authentication to protect against unauthorized access.',
              icon: Icons.phonelink_lock_outlined,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref.read(twoFactorControllerProvider.notifier).goTo(TwoFactorStep.verifyPassword),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Enable 2FA'),
            ),
          ],
        );
      case TwoFactorStep.verifyPassword:
        return Column(
          key: const ValueKey('password'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 1 · Verify password', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 16),
            const Text('Choose a method'),
            const SizedBox(height: 8),
            _MethodCard(
              icon: Icons.email_outlined,
              title: 'Email OTP',
              subtitle: 'Receive a code by email',
              onTap: () => _startSetup('email'),
            ),
            const SizedBox(height: 8),
            _MethodCard(
              icon: Icons.qr_code_2_outlined,
              title: 'Authenticator app',
              subtitle: 'Google Authenticator, Authy, etc.',
              onTap: () => _startSetup('totp'),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        );
      case TwoFactorStep.setup:
        final setup = state.totpSetup!;
        return Column(
          key: const ValueKey('setup'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Scan this QR code', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            QrImageView(data: setup.otpauthUri, size: 200, backgroundColor: Colors.white),
            const SizedBox(height: 12),
            SelectableText(setup.secret, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SecurityCodeField(
              controller: _codeController,
              onSubmitted: (_) => _verifyCode(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.loading ? null : _verifyCode,
              child: Text(state.loading ? 'Verifying…' : 'Verify & enable'),
            ),
          ],
        );
      case TwoFactorStep.verifyCode:
        return Column(
          key: const ValueKey('verify'),
          children: [
            const SecurityHeroHeader(
              title: 'Enter verification code',
              subtitle: 'We sent a 6-digit code to your email.',
              icon: Icons.mark_email_read_outlined,
            ),
            const SizedBox(height: 16),
            SecurityCodeField(controller: _codeController, onSubmitted: (_) => _verifyCode()),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.loading ? null : _verifyCode,
              child: Text(state.loading ? 'Verifying…' : 'Verify & enable'),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        );
      case TwoFactorStep.backupCodes:
        return Column(
          key: const ValueKey('backup'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SecurityHeroHeader(
              title: 'Save your backup codes',
              subtitle: 'Store these codes safely. Each can be used once if you lose access.',
              icon: Icons.backup_table_outlined,
            ),
            const SizedBox(height: 16),
            ...state.backupCodes.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(c, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.invalidate(securityOverviewProvider);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      case TwoFactorStep.done:
        return const SecurityHeroHeader(
          title: '2FA updated',
          subtitle: 'Your two-factor settings have been saved.',
          icon: Icons.check_circle_outline,
        );
    }
  }

  void _startSetup(String method) {
    ref.read(twoFactorControllerProvider.notifier).verifyPasswordAndContinue(
          _passwordController.text,
          method,
        );
  }

  void _verifyCode() {
    ref.read(twoFactorControllerProvider.notifier).verifyAndEnable(_codeController.text.trim());
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
