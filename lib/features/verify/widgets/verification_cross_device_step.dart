import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_extensions.dart';
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
    final scheme = theme.colorScheme;
    final duo = context.duo;
    final completed = _progress?.session?.livenessStepsCompleted?.length ?? 0;
    final total = widget.session.livenessSteps.length;
    final expiry = DateFormat.jm().format(widget.session.expiresAt.toLocal());
    final onSelfie = _progress?.status == VerificationStatus.pending && completed >= total;
    final statusText = onSelfie
        ? 'Taking selfie on your phone…'
        : completed > 0
            ? 'Face check $completed of $total done'
            : 'Waiting for your phone…';

    Widget pill({required IconData icon, required String label, VoidCallback? onTap}) => Material(
          color: scheme.secondary.withValues(alpha: 0.6),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 8),
        Text(
          'Scan with your phone',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Open your phone camera and point it at the code. No login needed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        // QR in a white card with a brand-gradient rim.
        Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: duo.brandGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: scheme.primary.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: QrImageView(data: _handoffUrl, version: QrVersions.auto, size: 196, gapless: true),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Code expires at $expiry',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: pill(
                icon: _copied ? Icons.check_rounded : Icons.link_rounded,
                label: _copied ? 'Copied' : 'Copy link',
                onTap: _copyLink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: _emailSending || _emailSent ? 0.7 : 1,
                child: pill(
                  icon: _emailSent ? Icons.mark_email_read_outlined : Icons.mail_outline_rounded,
                  label: _emailSending ? 'Sending…' : _emailSent ? 'Email sent' : 'Email me',
                  onTap: (_emailSending || _emailSent) ? null : _sendEmail,
                ),
              ),
            ),
          ],
        ),
        if (_emailSent && widget.userEmail != null) ...[
          const SizedBox(height: 8),
          Text(
            'Sent to ${widget.userEmail}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
        if (_emailError != null) ...[
          const SizedBox(height: 12),
          VerificationErrorBanner(message: _emailError!),
        ],
        const SizedBox(height: 24),
        // Live status from the phone.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.35, end: 1, duration: 800.ms),
              const SizedBox(width: 12),
              Expanded(
                child: Text(statusText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: i < completed ? duo.brandGradient : null,
                    color: i < completed ? null : scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
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
        Center(
          child: TextButton.icon(
            onPressed: widget.onUseThisDevice,
            style: TextButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: const Text("Use this device's camera instead", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
