import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/security_providers.dart';
import '../widgets/security_widgets.dart';

class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caps = ref.watch(biometricCapabilitiesProvider);
    final overview = ref.watch(securityOverviewProvider);
    final action = ref.watch(securityActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Login')),
      body: caps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (capabilities) {
          if (!capabilities.supported) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Biometric authentication is not available on this device.'),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SecurityHeroHeader(
                title: 'Quick & secure sign-in',
                subtitle: _capabilityText(capabilities),
                icon: capabilities.hasFace ? Icons.face_retouching_natural_outlined : Icons.fingerprint_outlined,
              ),
              const SizedBox(height: 16),
              overview.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (ov) => Card(
                  child: SwitchListTile(
                    value: ov.biometricEnabled,
                    onChanged: action.loading
                        ? null
                        : (enabled) {
                            if (enabled) {
                              _enableBiometric();
                            } else {
                              _disableBiometric();
                            }
                          },
                    title: const Text('Biometric login'),
                    subtitle: Text(
                      ov.biometricEnabled
                          ? 'Use biometrics to unlock Duo on this device'
                          : 'Off — password required each time',
                    ),
                  ),
                ),
              ),
              if (!capabilities.canCheckBiometrics) ...[
                const SizedBox(height: 12),
                Text(
                  'Set up fingerprint, face unlock, or a device PIN in your phone settings first.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (action.error != null) ...[
                const SizedBox(height: 12),
                Text(action.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (action.message != null) ...[
                const SizedBox(height: 12),
                Text(action.message!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ],
          );
        },
      ),
    );
  }

  String _capabilityText(dynamic capabilities) {
    final parts = <String>[];
    if (capabilities.hasFingerprint) parts.add('fingerprint');
    if (capabilities.hasFace) parts.add('face unlock');
    if (capabilities.hasPin) parts.add('device PIN');
    if (parts.isEmpty) return 'Authenticate with your device security.';
    return 'Supports ${parts.join(', ')}.';
  }

  Future<void> _enableBiometric() async {
    final password = await _askPassword('Enable biometric login');
    if (password == null) return;
    final ok = await ref.read(securityActionControllerProvider.notifier).enableBiometric(password);
    if (ok && mounted) ref.invalidate(securityOverviewProvider);
  }

  Future<void> _disableBiometric() async {
    final password = await _askPassword('Disable biometric login');
    if (password == null) return;
    final ok = await ref.read(securityActionControllerProvider.notifier).disableBiometric(password);
    if (ok && mounted) ref.invalidate(securityOverviewProvider);
  }

  Future<String?> _askPassword(String title) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: c,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Continue')),
          ],
        );
      },
    );
  }
}
