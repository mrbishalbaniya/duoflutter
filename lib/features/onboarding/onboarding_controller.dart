import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import 'onboarding_models.dart';

class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.isComplete = false,
  });

  final int currentPage;
  final bool isComplete;

  bool get isLastPage => currentPage >= introOnboardingPages.length - 1;

  OnboardingState copyWith({
    int? currentPage,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

const _storageKey = 'duo_intro_onboarding_complete';

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref)
      : super(
          OnboardingState(
            isComplete: _ref.read(localStorageProvider).settings.get(_storageKey) == true,
          ),
        );

  final Ref _ref;

  factory OnboardingController.testing(Ref ref, {bool isComplete = true}) {
    return OnboardingController._testing(ref, isComplete: isComplete);
  }

  OnboardingController._testing(this._ref, {bool isComplete = true})
      : super(OnboardingState(isComplete: isComplete));

  void setPage(int page) {
    final clamped = page.clamp(0, introOnboardingPages.length - 1);
    state = state.copyWith(currentPage: clamped);
  }

  void nextPage() {
    if (state.isLastPage) return;
    setPage(state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage <= 0) return;
    setPage(state.currentPage - 1);
  }

  void complete() {
    _ref.read(localStorageProvider).settings.put(_storageKey, true);
    state = state.copyWith(isComplete: true);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});
