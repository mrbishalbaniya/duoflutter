import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/verification_domain.dart';
import '../domain/verification_face_guide.dart';
import '../providers/verification_providers.dart';
import '../verification_controller.dart';
import 'verification_error_banner.dart';
import 'verification_face_overlay.dart';

class VerificationCameraStep extends ConsumerStatefulWidget {
  const VerificationCameraStep({
    super.key,
    required this.state,
    required this.isSelfie,
  });

  final VerificationState state;
  final bool isSelfie;

  @override
  ConsumerState<VerificationCameraStep> createState() => _VerificationCameraStepState();
}

class _VerificationCameraStepState extends ConsumerState<VerificationCameraStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final camera = ref.read(verificationCameraServiceProvider);
    if (camera.controller?.value.isInitialized ?? false) {
      ref.read(verificationControllerProvider.notifier).setCameraReady(true);
      if (mounted) setState(() => _initializing = false);
      return;
    }
    final error = await camera.initialize();
    if (!mounted) return;
    final notifier = ref.read(verificationControllerProvider.notifier);
    if (error != null) {
      notifier.setCameraError(error);
    } else {
      notifier.setCameraReady(true);
    }
    setState(() => _initializing = false);
  }

  Future<void> _capture() async {
    final camera = ref.read(verificationCameraServiceProvider);
    final notifier = ref.read(verificationControllerProvider.notifier);
    final file = await camera.capturePhoto();
    if (file == null) {
      notifier.setCameraError('Could not capture image. Try again.');
      return;
    }
    HapticFeedback.mediumImpact();
    final imageFile = File(file.path);
    if (widget.isSelfie) {
      await notifier.captureSelfie(imageFile);
    } else {
      await notifier.captureLiveness(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;
    final camera = ref.watch(verificationCameraServiceProvider);
    final controller = camera.controller;
    final livenessStep = state.currentLivenessStep;
    final livenessInfo = livenessStep != null ? livenessStepCatalog[livenessStep] : null;

    final guideState = deriveFaceGuideState(
      cameraReady: state.cameraReady,
      submitting: state.submitting,
      awaitingAction: state.stepActionReady,
      hasCameraError: state.cameraError != null,
    );

    final instruction = shortCameraInstruction(
      isSelfie: widget.isSelfie,
      awaitingAction: state.stepActionReady,
      livenessStep: livenessStep,
    );

    final stageLabel = verificationStageLabel(
      step: widget.isSelfie ? VerificationFlowStep.selfie : VerificationFlowStep.liveness,
      cameraReady: state.cameraReady,
      submitting: state.submitting,
      awaitingAction: state.stepActionReady,
      isSelfie: widget.isSelfie,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeader(
          stageLabel: stageLabel,
          title: widget.isSelfie ? 'Selfie' : (livenessInfo?.title ?? 'Liveness'),
          stepLabel: widget.isSelfie
              ? null
              : 'Step ${state.livenessIndex + 1} of ${state.session?.livenessSteps.length ?? 4}',
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 8,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null && controller.value.isInitialized)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159),
                    child: CameraPreview(controller),
                  )
                else
                  const ColoredBox(color: Colors.black),
                if (state.cameraReady && state.cameraError == null)
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, _) {
                      return VerificationFaceOverlay(
                        guideState: guideState,
                        instruction: instruction,
                        progress: _scanController.value,
                      );
                    },
                  ),
                if (_initializing || (!state.cameraReady && state.cameraError == null))
                  _CameraLoadingOverlay(stageLabel: stageLabel),
                if (state.cameraError != null)
                  _CameraErrorOverlay(message: state.cameraError!),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 280.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
        const SizedBox(height: 12),
        if (state.stepFeedback != null && !state.stepFeedback!.passed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VerificationInfoBanner(
              message: state.stepFeedback!.detail.isNotEmpty
                  ? state.stepFeedback!.detail
                  : state.stepFeedback!.baselineCaptured
                      ? 'Neutral pose saved. Perform the action, then capture again.'
                      : 'Adjust your pose and lighting, then retry.',
              tone: state.stepFeedback!.baselineCaptured
                  ? VerificationBannerTone.info
                  : VerificationBannerTone.warning,
            ),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VerificationErrorBanner(message: state.error!),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.submitting ? null : () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DuoGradientButton(
                label: state.submitting
                    ? 'Processing…'
                    : (widget.isSelfie ? 'Capture selfie' : 'Capture'),
                loading: state.submitting,
                onPressed: (state.submitting || !state.cameraReady) ? null : _capture,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _footerHint(state),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _footerHint(VerificationState state) {
    if (!state.cameraReady) return 'Allow camera access to continue.';
    if (state.stepActionReady) return 'Perform the action shown, then tap Capture.';
    if (!widget.isSelfie) return 'Hold a neutral pose first, then tap Capture.';
    return 'Remove hats and sunglasses. Ensure good lighting.';
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({
    required this.stageLabel,
    required this.title,
    this.stepLabel,
  });

  final String stageLabel;
  final String title;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stageLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: DuoColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (stepLabel != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(stepLabel!, style: theme.textTheme.labelMedium),
            ),
          ),
      ],
    );
  }
}

class _CameraLoadingOverlay extends StatelessWidget {
  const _CameraLoadingOverlay({required this.stageLabel});

  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              stageLabel,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Initializing secure camera preview…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorOverlay extends StatelessWidget {
  const _CameraErrorOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xE6000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
