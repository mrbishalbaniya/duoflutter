import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../widgets/duo_ui.dart';
import 'registration_controller.dart';
import 'registration_models.dart';
import 'steps/registration_steps.dart';
import 'steps/step_account.dart';
import 'widgets/registration_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _animatedStep = 1;

  @override
  Widget build(BuildContext context) {
    final reg = ref.watch(registrationControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (_animatedStep != reg.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _animatedStep = reg.step);
      });
    }

    return Scaffold(
      body: DuoAmbientBackground(
        child: Column(
          children: [
            _RegisterHeader(onClose: () => context.go(AppRoutes.login)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RegistrationStepper(currentStep: reg.step)
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
                        if (reg.error != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              reg.error!,
                              style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w500),
                            ),
                          ).animate().fadeIn(duration: 200.ms).shake(hz: 2, duration: 300.ms),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final offset = Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: offset, child: child),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(reg.step),
                            child: _buildStep(reg),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(RegistrationState reg) {
    final controller = ref.read(registrationControllerProvider.notifier);

    switch (reg.step) {
      case 1:
        return StepAccount(onContinue: controller.handleContinue);
      case 2:
        return StepBasicInfo(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 3:
        return StepLocation(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 4:
        return StepEducation(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 5:
        return StepReligion(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 6:
        return StepLifestyle(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 7:
        return StepInterests(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 8:
        return StepPreferences(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 9:
        return StepAbout(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 10:
        return StepPhotos(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 11:
        return StepReview(
          onSubmit: () async {
            await controller.handleSubmit();
            if (!mounted) return;
            final error = ref.read(registrationControllerProvider).error;
            if (error == null) context.go(AppRoutes.match);
          },
          onBack: controller.prevStep,
          onEditStep: controller.goToStep,
          loading: reg.isSubmitting,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const DuoBrandLogo(size: 28)
                .animate()
                .fadeIn(duration: 320.ms)
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
            const Spacer(),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onClose();
              },
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }
}
