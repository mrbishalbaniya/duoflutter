import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../auth/auth_controller.dart';

class SplashState {
  const SplashState({
    this.assetsReady = false,
    this.sessionReady = false,
    this.minTimeElapsed = false,
    this.isExiting = false,
    this.versionLabel = 'v1.0.0',
  });

  final bool assetsReady;
  final bool sessionReady;
  final bool minTimeElapsed;
  final bool isExiting;
  final String versionLabel;

  bool get canExit => assetsReady && sessionReady && minTimeElapsed;

  SplashState copyWith({
    bool? assetsReady,
    bool? sessionReady,
    bool? minTimeElapsed,
    bool? isExiting,
    String? versionLabel,
  }) {
    return SplashState(
      assetsReady: assetsReady ?? this.assetsReady,
      sessionReady: sessionReady ?? this.sessionReady,
      minTimeElapsed: minTimeElapsed ?? this.minTimeElapsed,
      isExiting: isExiting ?? this.isExiting,
      versionLabel: versionLabel ?? this.versionLabel,
    );
  }
}

final splashMinDurationProvider = Provider<Duration>((ref) {
  if (kDebugMode) return const Duration(milliseconds: 400);
  return const Duration(milliseconds: 700);
});

class SplashController extends StateNotifier<SplashState> {
  SplashController(this._ref, {SplashState? initialState}) : super(initialState ?? const SplashState()) {
    if (initialState != null) return;
    _startMinTimer();
    _resolveSession();
  }

  final Ref _ref;

  factory SplashController.testing(Ref ref) {
    return SplashController(
      ref,
      initialState: const SplashState(
        assetsReady: true,
        sessionReady: true,
        minTimeElapsed: true,
        versionLabel: 'v1.0.0',
      ),
    );
  }

  void markAssetsReady() {
    if (state.assetsReady) return;
    state = state.copyWith(assetsReady: true);
  }

  void markExiting() {
    state = state.copyWith(isExiting: true);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = state.copyWith(versionLabel: 'v${info.version}');
    } catch (_) {}
  }

  Future<void> _startMinTimer() async {
    await Future<void>.delayed(_ref.read(splashMinDurationProvider));
    state = state.copyWith(minTimeElapsed: true);
  }

  Future<void> _resolveSession() async {
    final auth = _ref.read(authControllerProvider.notifier);
    await Future.wait([
      auth.bootstrap(),
      _loadVersion(),
    ]);

    final status = _ref.read(authControllerProvider).status;
    if (status == AuthStatus.authenticated) {
      await auth.refreshUser();
    }

    state = state.copyWith(sessionReady: true);
  }
}

final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
  return SplashController(ref);
});
