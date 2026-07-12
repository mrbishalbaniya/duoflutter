import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/verification_domain.dart';
import '../models/verification_models.dart';
import 'verification_error_banner.dart';

class VerificationCrossDeviceStep extends ConsumerStatefulWidget {
  const VerificationCrossDeviceStep({
    super.key,
    required this.session,
    required this.userEmail,
    required this.onComplete,
    required this.onUseThisDevice,
  });

  final VerificationStartResponse session;
  final String? userEmail;
  final ValueChanged<VerificationStatusResponse> onComplete;
  final VoidCallback onUseThisDevice;

  @override
  ConsumerState<VerificationCrossDeviceStep> createState() => _VerificationCrossDeviceStepState();
}

class _VerificationCrossDeviceStepState extends ConsumerState<VerificationCrossDeviceStep> {
  bool _copied = false;
  bool _emailSending = false;
  bool _emailSent = false;
  String? _emailError;
  String? _pollError;
  VerificationSessionDetail? _progress;
  Timer? _pollTimer;

  String get _handoffUrl =>
      widget.session.handoffUrl ??
      'https://duo.app/verify/device?session=${widget.session.sessionToken}';

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final detail = await ref.read(verificationRepositoryProvider).getVerificationSession(
            widget.session.sessionToken,
          );
      if (!mounted) return;
      setState(() {
        _progress = detail;
        _pollError = null;
      });
      if (finalVerificationStatuses.contains(detail.status)) {
        widget.onComplete(detail);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pollError = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _handoffUrl));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _sendEmail() async {
    setState(() {
      _emailSending = true;
      _emailError = null;
    });
    try {
      await ref.read(verificationRepositoryProvider).sendVerificationHandoffEmail(
            sessionToken: widget.session.sessionToken,
          );
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _emailSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailSending = false;
        _emailError = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = _progress?.session?.livenessStepsCompleted?.length ?? 0;
    final total = widget.session.livenessSteps.length;
    final expiry = DateFormat.yMMMd().add_jm().format(widget.session.expiresAt.toLocal());

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.secondary.withValues(alpha: 0.45),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open this link on your phone or tablet — no login needed. This screen updates when verification finishes.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text('Link expires $expiry', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: QrImageView(
                data: _handoffUrl,
                version: QrVersions.auto,
                size: 148,
                gapless: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Verification link', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Text(_handoffUrl, style: theme.textTheme.bodySmall),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
                    label: Text(_copied ? 'Link copied' : 'Copy link'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: (_emailSending || _emailSent) ? null : _sendEmail,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(
                      _emailSending
                          ? 'Sending…'
                          : _emailSent
                              ? 'Email sent'
                              : widget.userEmail != null
                                  ? 'Email link to ${widget.userEmail}'
                                  : 'Email link to me',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_emailError != null) ...[
          const SizedBox(height: 12),
          VerificationErrorBanner(message: _emailError!),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waiting on your other device', style: theme.textTheme.bodyMedium),
                  Text('$completed/$total liveness steps', style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: total == 0 ? 0 : (completed / total).clamp(0, 1),
                ),
              ),
              if (_progress?.status == VerificationStatus.pending && completed >= total) ...[
                const SizedBox(height: 8),
                Text(
                  'Selfie capture in progress…',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (_pollError != null) ...[
          const SizedBox(height: 12),
          VerificationInfoBanner(message: _pollError!, tone: VerificationBannerTone.warning),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.onUseThisDevice,
          child: const Text('Use this device instead'),
        ),
      ],
    );
  }
}