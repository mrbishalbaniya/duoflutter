import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../providers/security_providers.dart';

/// Prompts for biometrics when a logged-in user resumes the app with
/// biometric login enabled on this device. Never stores passwords.
class BiometricUnlockBridge extends ConsumerStatefulWidget {
  const BiometricUnlockBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricUnlockBridge> createState() => _BiometricUnlockBridgeState();
}

class _BiometricUnlockBridgeState extends ConsumerState<BiometricUnlockBridge>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _prompting = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLockOnLaunch());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeLock();
    } else if (state == AppLifecycleState.paused) {
      _armLock();
    }
  }

  Future<void> _armLock() async {
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) return;
    final enabled = await ref.read(biometricAuthServiceProvider).isLocallyEnabled();
    if (enabled && mounted) setState(() => _locked = true);
  }

  Future<void> _maybeLockOnLaunch() async {
    if (_checked) return;
    _checked = true;
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) return;
    final enabled = await ref.read(biometricAuthServiceProvider).isLocallyEnabled();
    if (enabled && mounted) {
      setState(() => _locked = true);
      await _unlock();
    }
  }

  Future<void> _maybeLock() async {
    if (!_locked || _prompting) return;
    await _unlock();
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    setState(() => _prompting = true);
    final ok = await ref.read(biometricAuthServiceProvider).authenticate(
          reason: 'Unlock Duo',
        );
    if (!mounted) return;
    setState(() {
      _prompting = false;
      _locked = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ColoredBox(
          color: scheme.surface.withValues(alpha: 0.96),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 56, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock Duo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use Face ID, Touch ID, or your device PIN to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _prompting ? null : _unlock,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(_prompting ? 'Waiting…' : 'Unlock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
