import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../splash/widgets/splash_brand.dart';
import '../../models/permission_models.dart';
import '../../providers/permission_providers.dart';
import '../dialogs/permission_denied_dialog.dart';
import '../widgets/permission_card.dart';
import '../widgets/permission_progress_header.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen> {
  Future<void> _handleAllow() async {
    final controller = ref.read(permissionSetupControllerProvider.notifier);
    final state = ref.read(permissionSetupControllerProvider);

    if (state.showSuccess) {
      _goNext(controller, state);
      return;
    }

    HapticFeedback.mediumImpact();
    final status = await controller.allowCurrent();
    if (!mounted) return;

    final updated = ref.read(permissionSetupControllerProvider);
    if (status.isGranted || status == DuoPermissionStatus.limited) {
      if (updated.showSuccess) {
        return;
      }
      _goNext(controller, updated);
      return;
    }

    if (status == DuoPermissionStatus.permanentlyDenied || status == DuoPermissionStatus.denied) {
      await showPermissionDeniedDialog(
        context,
        definition: updated.currentDefinition,
        status: status,
        onOpenSettings: () => ref.read(permissionServiceProvider).openSystemSettings(),
      );
      if (!mounted) return;
      _goNext(controller, updated);
    }
  }

  void _goNext(PermissionSetupController controller, PermissionSetupState state) {
    if (state.isLastStep) {
      context.go(AppRoutes.permissionPersonalize);
      return;
    }
    controller.advance();
  }

  void _handleSkip() {
    HapticFeedback.selectionClick();
    final controller = ref.read(permissionSetupControllerProvider.notifier);
    final state = ref.read(permissionSetupControllerProvider);
    controller.skipCurrent();
    if (!mounted) return;
    final updated = ref.read(permissionSetupControllerProvider);
    if (updated.isLastStep && updated.currentStep == state.currentStep) {
      context.go(AppRoutes.permissionPersonalize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionSetupControllerProvider);
    final definition = state.currentDefinition;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SplashBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(isWide ? 40 : 20, 12, isWide ? 40 : 20, 0),
                  child: PermissionProgressHeader(
                    currentStep: state.currentStep,
                    totalSteps: state.totalSteps,
                    accent: definition.accent,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(definition.type),
                      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 16, isWide ? 48 : 20, 24),
                      child: PermissionCard(
                        definition: definition,
                        status: state.statuses[definition.type],
                        showSuccess: state.showSuccess,
                        isRequesting: state.isRequesting,
                        onAllow: _handleAllow,
                        onSkip: definition.optional ? _handleSkip : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
