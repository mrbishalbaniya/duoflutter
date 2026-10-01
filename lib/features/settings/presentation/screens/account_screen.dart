import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/auth_controller.dart';
import '../../../security/providers/security_providers.dart';
import '../../domain/settings_domain.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// Mirrors the web `/account` page: username, email, phone and verification,
/// plus links to profile, match preferences and security.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _usernameController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _editingUsername = false;
  bool _editingPhone = false;
  bool _savingUsername = false;
  bool _savingPhone = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneCodeController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _showError(Object error, String fallback) {
    final message = error is ApiException ? error.message : fallback;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveUsername() async {
    final next = _usernameController.text.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (next.length < 3 || next.length > 30) {
      _showError('', 'Username must be 3-30 characters.');
      return;
    }
    setState(() => _savingUsername = true);
    try {
      await ref.read(dioClientProvider).patch<Map<String, dynamic>>(
        '/auth/me/username/',
        data: {'username': next},
      );
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) setState(() => _editingUsername = false);
    } catch (e) {
      if (mounted) _showError(e, 'Could not update your username.');
    } finally {
      if (mounted) setState(() => _savingUsername = false);
    }
  }

  Future<void> _savePhone() async {
    var code = _phoneCodeController.text.trim();
    final number = _phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.length < 6) {
      _showError('', 'Enter a valid phone number.');
      return;
    }
    if (code.isEmpty) code = '+977';
    if (!code.startsWith('+')) code = '+$code';
    setState(() => _savingPhone = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'phone_country_code': code,
        'phone_number': number,
      });
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) setState(() => _editingPhone = false);
    } catch (e) {
      if (mounted) _showError(e, 'Could not update your phone number.');
    } finally {
      if (mounted) setState(() => _savingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final profile = user?.profile;
    final overview = ref.watch(securityOverviewProvider).valueOrNull;
    final emailVerified = overview?.emailVerified ?? false;
    final phoneVerified = overview?.phoneVerified ?? false;
    final hasPhone = profile?.phoneNumber?.trim().isNotEmpty == true;
    // A verified number is locked; only an unverified or missing one can change.
    final canEditPhone = !(phoneVerified && hasPhone);
    final isVerified = profile?.isVerified ?? false;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Manage your username, email and phone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SettingsSection(
            title: 'Account details',
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Username',
                  value: user?.username.isNotEmpty == true ? '@${user!.username}' : 'Not set',
                  onEdit: _editingUsername
                      ? null
                      : () => setState(() {
                            _usernameController.text = user?.username ?? '';
                            _editingUsername = true;
                          }),
                  editor: !_editingUsername
                      ? null
                      : _InlineEditor(
                          saving: _savingUsername,
                          onCancel: () => setState(() => _editingUsername = false),
                          onSave: _saveUsername,
                          helper: '3-30 characters. Letters, numbers, dots and underscores.',
                          fields: [
                            Expanded(
                              child: TextField(
                                controller: _usernameController,
                                autofocus: true,
                                maxLength: 30,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                                  TextInputFormatter.withFunction(
                                    (_, v) => v.copyWith(text: v.text.toLowerCase()),
                                  ),
                                ],
                                onSubmitted: (_) => _saveUsername(),
                                decoration: const InputDecoration(
                                  prefixText: '@',
                                  hintText: 'your.username',
                                  counterText: '',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SettingsDivider(),
                _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: user?.email?.isNotEmpty == true ? user!.email! : 'Not set',
                  verified: emailVerified,
                ),
                const SettingsDivider(),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: formatPhoneLabel(profile?.phoneCountryCode, profile?.phoneNumber),
                  verified: phoneVerified && hasPhone,
                  onEdit: canEditPhone && !_editingPhone
                      ? () => setState(() {
                            _phoneCodeController.text = profile?.phoneCountryCode?.trim().isNotEmpty == true
                                ? profile!.phoneCountryCode!.trim()
                                : '+977';
                            _phoneNumberController.text = profile?.phoneNumber ?? '';
                            _editingPhone = true;
                          })
                      : null,
                  editor: !_editingPhone
                      ? null
                      : _InlineEditor(
                          saving: _savingPhone,
                          onCancel: () => setState(() => _editingPhone = false),
                          onSave: _savePhone,
                          fields: [
                            SizedBox(
                              width: 84,
                              child: TextField(
                                controller: _phoneCodeController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _phoneNumberController,
                                autofocus: true,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onSubmitted: (_) => _savePhone(),
                                decoration: const InputDecoration(
                                  labelText: 'Phone number',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SettingsDivider(),
                _InfoRow(
                  icon: Icons.photo_camera_front_outlined,
                  label: 'Profile verification',
                  value: isVerified ? 'Verified' : 'Not verified',
                  verified: isVerified,
                  editor: isVerified
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton(
                              onPressed: () => context.push(AppRoutes.verify),
                              child: const Text('Verify with a selfie'),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'More',
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.person_outline,
                  title: 'Edit profile',
                  onTap: () => context.push(AppRoutes.profile),
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.favorite_border_rounded,
                  title: 'Match preferences',
                  onTap: () => context.push(AppRoutes.matchPreferences),
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  onTap: () => context.push(AppRoutes.security),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.verified = false,
    this.onEdit,
    this.editor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final VoidCallback? onEdit;
  final Widget? editor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        if (verified) const _VerifiedBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit ${label.toLowerCase()}',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (editor != null) editor!,
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF34D399);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: green),
          SizedBox(width: 4),
          Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
        ],
      ),
    );
  }
}

class _InlineEditor extends StatelessWidget {
  const _InlineEditor({
    required this.fields,
    required this.saving,
    required this.onCancel,
    required this.onSave,
    this.helper,
  });

  final List<Widget> fields;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: fields),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(helper!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: saving ? null : onCancel, child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
