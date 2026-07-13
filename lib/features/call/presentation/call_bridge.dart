import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../providers/call_providers.dart';
import 'active_call_screen.dart';
import 'incoming_call_overlay.dart';

/// Global call overlay + inbox listener mounted at app root.
class CallBridge extends ConsumerStatefulWidget {
  const CallBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CallBridge> createState() => _CallBridgeState();
}

class _CallBridgeState extends ConsumerState<CallBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = ref.read(authControllerProvider);
    if (auth.user != null) {
      ref.read(callControllerProvider.notifier).setCurrentUserId(auth.user!.id);
      await ref.read(callControllerProvider.notifier).connectInbox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callControllerProvider);

    return Stack(
      children: [
        widget.child,
        if (call.phase == CallPhase.incoming || call.phase == CallPhase.outgoing)
          const Positioned.fill(child: IncomingCallOverlay()),
        if (call.phase == CallPhase.active || call.phase == CallPhase.connecting)
          const Positioned.fill(child: ActiveCallScreen()),
      ],
    );
  }
}
