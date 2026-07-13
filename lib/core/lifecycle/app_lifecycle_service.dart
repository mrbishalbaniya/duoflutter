import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global app foreground/background state for pausing expensive work.
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  AppLifecycleNotifier() : super(AppLifecycleState.resumed);

  void update(AppLifecycleState next) {
    if (state != next) state = next;
  }

  bool get isForeground => state == AppLifecycleState.resumed;
}

final appLifecycleProvider =
    StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>((ref) {
  return AppLifecycleNotifier();
});

/// Observes [WidgetsBinding] lifecycle and updates [appLifecycleProvider].
class AppLifecycleBridge extends ConsumerStatefulWidget {
  const AppLifecycleBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends ConsumerState<AppLifecycleBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).update(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
