import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/verification_domain.dart';
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
  late final AnimationController _pulseController;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final camera = ref.read(verificationCameraServiceProvider);
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
    final statusMessage = faceOverlayStatusMessage(
      step: widget.isSelfie ? VerificationFlowStep.selfie : VerificationFlowStep.liveness,
      livenessStep: livenessStep,
      awaitingAction: state.stepActionReady,
      cameraReady: state.cameraReady,
    );

    final flowProgress = state.session == null
        ? 0.0
        : widget.isSelfie
            ? 0.85
            : state.completedSteps.length / state.session!.livenessSteps.length;

    return Column(
      children: [
        if (widget.isSelfie)
          Text(
            'Take your selfie',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          )
        else if (livenessInfo != null) ...[
          Icon(livenessInfo.icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(livenessInfo.title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            livenessInfo.hint,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${state.livenessIndex + 1} of ${state.session?.livenessSteps.length ?? 4}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null && controller.value.isInitialized)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Transform(
                      key: ValueKey(controller.description),
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: CameraPreview(controller),
                    ),
                  )
                else
                  const ColoredBox(color: Colors.black),
                if (state.cameraReady)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return VerificationFaceOverlay(
                        statusMessage: state.autoStatus ?? statusMessage,
                        progress: _pulseController.value,
                      );
                    },
                  ),
                if (_initializing || !state.cameraReady && state.cameraError == null)
                  const ColoredBox(
                    color: Color(0x99000000),
                    child: Center(
                      child: Text('Starting camera…', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                if (state.cameraError != null)
                  ColoredBox(
                    color: const Color(0xCC000000),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          state.cameraError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (state.stepFeedback != null && !state.stepFeedback!.passed) ...[
          const SizedBox(height: 10),
          VerificationInfoBanner(
            message: state.stepFeedback!.detail.isNotEmpty
                ? state.stepFeedback!.detail
                : state.stepFeedback!.baselineCaptured
                    ? 'Neutral pose saved. Perform the action and capture again.'
                    : 'Try again — adjust your pose and lighting.',
            tone: state.stepFeedback!.baselineCaptured
                ? VerificationBannerTone.info
                : VerificationBannerTone.warning,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 10),
          VerificationErrorBanner(message: state.error!),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: (state.submitting || !state.cameraReady) ? null : _capture,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(state.submitting ? 'Processing…' : 'Capture manually'),
        ),
        const SizedBox(height: 8),
        Text(
          'Progress ${(flowProgress * 100).round()}%',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
