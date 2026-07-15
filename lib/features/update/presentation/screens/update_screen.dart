import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../widgets/duo_ui.dart';
import '../../models/update_models.dart';
import '../../providers/update_providers.dart';
import '../dialogs/update_dialog.dart';

/// Deep-link destination for "Update Available" notifications.
class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final controller = ref.read(updateControllerProvider.notifier);
    await controller.checkForUpdates(force: true, manual: true);
    if (!mounted) return;
    final state = ref.read(updateControllerProvider);
    final shouldShow = state.phase == UpdatePhase.available || state.hasBlockingUpdate;
    if (shouldShow) {
      await showUpdateDialog(context, blocking: state.hasBlockingUpdate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final latest = state.latest;

    return Scaffold(
      appBar: AppBar(title: const Text('App update'), centerTitle: false),
      body: DuoAmbientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DuoGlassCard(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  latest?.updateAvailable == true
                      ? 'A new version of the app is available. Update now for the latest improvements and fixes.'
                      : state.message?.isNotEmpty == true
                          ? state.message!
                          : 'Checking for the latest Duo release…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Latest: ${latest.latestVersion} (build ${latest.buildNumber})',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                DuoGradientButton(
                  onPressed: state.phase == UpdatePhase.checking ? null : _open,
                  label: state.hasBlockingUpdate ? 'Update required' : 'Check / update',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
