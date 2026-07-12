import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../../widgets/duo_ui.dart';
import 'domain/verification_domain.dart';
import 'providers/verification_providers.dart';
import 'verification_controller.dart';
import 'widgets/verification_camera_step.dart';
import 'widgets/verification_cross_device_step.dart';
import 'widgets/verification_instructions_step.dart';
import 'widgets/verification_processing_step.dart';
import 'widgets/verification_progress_bar.dart';
import 'widgets/verification_result_step.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({
    super.key,
    this.mode = VerificationMode.defaultMode,
    this.initialSessionToken,
  });

  final VerificationMode mode;
  final String? initialSessionToken;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationControllerProvider.notifier).configure(
            mode: widget.mode,
            initialSessionToken: widget.initialSessionToken,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationControllerProvider);
    final notifier = ref.read(verificationControllerProvider.notifier);
    final userEmail = ref.watch(authControllerProvider).user?.email;

    ref.listen<VerificationState>(verificationControllerProvider, (prev, next) {
      final prevStep = prev?.step;
      final nextStep = next.step;
      final cameraSteps = {VerificationFlowStep.liveness, VerificationFlowStep.selfie};
      if (prevStep != null &&
          cameraSteps.contains(prevStep) &&
          !cameraSteps.contains(nextStep)) {
        ref.read(verificationCameraServiceProvider).dispose();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: DuoAmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                VerificationProgressBar(progress: state.progressPercent),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _buildStep(
                      context,
                      state: state,
                      notifier: notifier,
                      userEmail: userEmail,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required VerificationState state,
    required VerificationController notifier,
    required String? userEmail,
  }) {
    if (state.deviceLoading) {
      return const Center(
        key: ValueKey('device_loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading verification session…'),
          ],
        ),
      );
    }

    Widget child;
    switch (state.step) {
      case VerificationFlowStep.instructions:
        child = VerificationInstructionsStep(
          state: state,
          onStartDevice: notifier.startOnDevice,
          onStartCrossDevice: notifier.startCrossDevice,
        );
      case VerificationFlowStep.crossDevice:
        child = state.session == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing cross-device session…'),
                  ],
                ),
              )
            : VerificationCrossDeviceStep(
                session: state.session!,
                userEmail: userEmail,
                onComplete: notifier.onRemoteComplete,
                onUseThisDevice: notifier.useThisDevice,
              );
      case VerificationFlowStep.liveness:
        child = VerificationCameraStep(state: state, isSelfie: false);
      case VerificationFlowStep.selfie:
        child = VerificationCameraStep(state: state, isSelfie: true);
      case VerificationFlowStep.processing:
        child = const VerificationProcessingStep();
      case VerificationFlowStep.result:
        child = state.result == null
            ? const VerificationProcessingStep()
            : VerificationResultStep(
                result: state.result!,
                mode: state.mode,
                session: state.session,
                onTryAgain: notifier.tryAgain,
              );
    }

    return KeyedSubtree(
      key: ValueKey('${state.step}_${state.livenessIndex}'),
      child: child,
    );
  }
}
