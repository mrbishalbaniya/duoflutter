import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../repositories/support_repository.dart';
import '../../auth/auth_controller.dart';
import '../support_providers.dart';

/// Contact-support and bug-report form, mirroring the web `SupportRequestForm`.
class SupportRequestScreen extends ConsumerStatefulWidget {
  const SupportRequestScreen({super.key, required this.category});

  final SupportRequestCategory category;

  @override
  ConsumerState<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends ConsumerState<SupportRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late final TextEditingController _email;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  bool get _isBug => widget.category == SupportRequestCategory.bug;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: ref.read(authControllerProvider).user?.email ?? '');
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<String> _deviceInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return 'Duo Mobile ${info.version}+${info.buildNumber}; '
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'Duo Mobile; ${Platform.operatingSystem}';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(supportRepositoryProvider).submitSupportRequest(
            category: widget.category,
            subject: _subject.text.trim(),
            message: _message.text.trim(),
            contactEmail: _email.text.trim(),
            deviceInfo: _isBug ? await _deviceInfo() : '',
          );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isBug ? 'Report a Bug' : 'Contact Support')),
      body: _sent ? _buildSuccess(theme) : _buildForm(theme),
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Request received', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Thanks for reaching out. Our team will get back to you as soon as possible.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to Help'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(
                _isBug ? Icons.bug_report_outlined : Icons.support_agent_outlined,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isBug
                      ? "Found something broken? Let us know and we'll look into it."
                      : 'Have a question or need help? Send us a message and our team will get back to you.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Your Email', hintText: 'you@example.com'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _subject,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: _isBug ? 'Briefly describe the issue' : 'What can we help with?',
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _message,
            minLines: 5,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: _isBug ? 'Details' : 'Message',
              hintText: _isBug
                  ? 'Tell us what happened, what you expected, and steps to reproduce'
                  : 'Describe your question or issue',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v ?? '').trim().length < 5 ? 'Please provide a bit more detail.' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: Text(_sending ? 'Sending...' : (_isBug ? 'Submit Report' : 'Send Message')),
          ),
        ],
      ),
    );
  }
}
