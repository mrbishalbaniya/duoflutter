import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../widgets/duo_ui.dart';
import '../splash/widgets/splash_brand.dart';
import 'onboarding_controller.dart';
import 'onboarding_models.dart';
import 'widgets/onboarding_illustration.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    ref.read(onboardingControllerProvider.notifier).setPage(index);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() {
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).complete();
    context.go(AppRoutes.login);
  }

  void _next(OnboardingState state) {
    HapticFeedback.mediumImpact();
    if (state.isLastPage) {
      ref.read(onboardingControllerProvider.notifier).complete();
      context.go(AppRoutes.login);
      return;
    }
    _goToPage(state.currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = introOnboardingPages;
    final current = pages[onboarding.currentPage];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SplashBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      const DuoBrandLogo(size: 24),
                      const Spacer(),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final active = index == onboarding.currentPage;
                      return _OnboardingSlide(page: page, isActive: active);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      OnboardingPageIndicator(
                        count: pages.length,
                        currentIndex: onboarding.currentPage,
                        accent: current.accent,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          if (onboarding.currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _goToPage(onboarding.currentPage - 1);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                          if (onboarding.currentPage > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: onboarding.currentPage > 0 ? 2 : 1,
                            child: DuoGradientButton(
                              label: onboarding.isLastPage ? 'Get Started' : 'Next',
                              icon: onboarding.isLastPage
                                  ? Icons.arrow_forward_rounded
                                  : Icons.chevron_right_rounded,
                              onPressed: () => _next(onboarding),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.page,
    required this.isActive,
  });

  final OnboardingPageData page;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final illustration = OnboardingIllustration(page: page, isActive: isActive);
        final card = OnboardingGlassCard(page: page, isActive: isActive);

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                Expanded(child: Center(child: illustration)),
                const SizedBox(width: 24),
                Expanded(child: Center(child: card)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            children: [
              illustration,
              const SizedBox(height: 20),
              card,
            ],
          ),
        );
      },
    );
  }
}
