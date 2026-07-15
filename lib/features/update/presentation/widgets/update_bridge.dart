import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/providers/notifications_providers.dart';
import '../dialogs/update_dialog.dart';
import '../../models/update_models.dart';
import '../../providers/update_providers.dart';

/// Startup and periodic OTA check bridge.
///
/// Shows an in-app dialog for forced updates and a local notification for
/// optional updates (deduped per version+build until a newer release appears).
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
    if (state.phase == UpdatePhase.failed) return;

    final shouldPrompt = state.phase == UpdatePhase.available || state.hasBlockingUpdate;
    if (!shouldPrompt) return;

    if (state.hasBlockingUpdate) {
      await ref.read(pushMessagingCoordinatorProvider).showUpdateAvailableNotification(
            version: latest.latestVersion,
            buildNumber: latest.buildNumber,
            forceUpdate: true,
          );
      if (!mounted || _dialogShown) return;
      _dialogShown = true;
      await showUpdateDialog(context, blocking: true);
      _dialogShown = false;
      return;
    }

    // Soft update: one local notification per version+build (no repeat after dismiss
    // until a newer build is released). Do not auto-open the dialog every launch.
    await ref.read(pushMessagingCoordinatorProvider).showUpdateAvailableNotification(
          version: latest.latestVersion,
          buildNumber: latest.buildNumber,
          forceUpdate: false,
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
