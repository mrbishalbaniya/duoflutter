import '../auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import 'registration_controller.dart';
import 'registration_models.dart';
import 'steps/registration_steps.dart';
import 'steps/step_account.dart';
import 'steps/step_photos.dart';
import 'steps/step_review.dart';
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
      body: SizedBox.expand(
        child: Column(
          children: [
            _RegisterHeader(onClose: _close),
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

  /// A signed-in member who hasn't finished onboarding is always routed back
  /// to /register, so just navigating to /login did nothing. Sign out first.
  Future<void> _close() async {
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated) {
      context.go(AppRoutes.login);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave registration?'),
        content: const Text(
          "You'll be signed out. Your progress is saved, so you can log in later to finish your profile.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  Widget _buildStep(RegistrationState reg) {
    final controller = ref.read(registrationControllerProvider.notifier);

    switch (reg.step) {
      case 1:
        return StepAccount(onContinue: controller.handleContinue);
      case 2:
        return StepBasicInfo(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 3:
        return StepPhotos(onContinue: controller.handleContinue, onBack: controller.prevStep);
      case 4:
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
