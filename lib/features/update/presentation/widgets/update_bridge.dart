import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/update_dialog.dart';
import '../../models/update_models.dart';
import '../../providers/update_providers.dart';

/// Startup and periodic OTA check bridge.
class UpdateBridge extends ConsumerStatefulWidget {
  const UpdateBridge({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateBridge> createState() => _UpdateBridgeState();
}

class _UpdateBridgeState extends ConsumerState<UpdateBridge> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnStartup());
  }

  Future<void> _checkOnStartup() async {
    if (!Platform.isAndroid) return;
    final latest = await ref.read(updateControllerProvider.notifier).checkForUpdates();
    if (!mounted || latest == null) return;

    final state = ref.read(updateControllerProvider);
    final shouldShow = state.phase == UpdatePhase.available || state.hasBlockingUpdate;
    if (!shouldShow || _dialogShown) return;

    _dialogShown = true;
    await showUpdateDialog(
      context,
      blocking: state.hasBlockingUpdate,
    );
    _dialogShown = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
