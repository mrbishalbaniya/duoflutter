import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/update_models.dart';
import '../../providers/update_providers.dart';
import '../../utils/update_utils.dart';

Future<void> showUpdateDialog(
  BuildContext context, {
  required bool blocking,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: !blocking,
    barrierLabel: 'Update',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    pageBuilder: (context, animation, secondaryAnimation) {
      return UpdateDialog(blocking: blocking);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key, required this.blocking});

  final bool blocking;

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(updateControllerProvider);
    final latest = state.latest;
    final installed = state.installed;

    if (latest == null) {
      return const SizedBox.shrink();
    }

    final canSkip = !widget.blocking && latest.canSkip;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/logo.png', width: 52, height: 52),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latest.emergencyUpdate
                                      ? 'Critical update required'
                                      : latest.forceUpdate
                                          ? 'Update required'
                                          : 'Update available',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  'Duo ${latest.latestVersion} · ${latest.fileSize}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _VersionRow(
                        label: 'Installed',
                        value: installed == null
                            ? '—'
                            : '${installed.version} (${installed.buildNumber})',
                      ),
                      const SizedBox(height: 6),
                      _VersionRow(
                        label: 'Latest',
                        value: '${latest.latestVersion} (${latest.buildNumber})',
                        highlight: true,
                      ),
                      if (latest.releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'What\'s new',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...latest.releaseNotes.take(6).map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.fiber_manual_record, size: 8, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(note)),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      if (state.phase == UpdatePhase.downloading ||
                          state.phase == UpdatePhase.paused ||
                          state.phase == UpdatePhase.readyToInstall) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: state.progress > 0 ? state.progress : null,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.phase == UpdatePhase.readyToInstall
                              ? 'Ready to install'
                              : '${(state.progress * 100).toStringAsFixed(0)}% · ${formatSpeed(state.downloadSpeedBps)} · ${formatEta(state.etaSeconds)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildActions(context, state, latest, canSkip),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildActions(
    BuildContext context,
    UpdateUiState state,
    AppUpdateInfo latest,
    bool canSkip,
  ) {
    final controller = ref.read(updateControllerProvider.notifier);

    if (state.phase == UpdatePhase.readyToInstall) {
      return FilledButton(
        onPressed: () => controller.installDownloadedApk(),
        child: const Text('Install update'),
      );
    }

    if (state.phase == UpdatePhase.downloading) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.pauseDownload,
              child: const Text('Pause'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                controller.cancelDownload();
                if (canSkip) Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    if (state.phase == UpdatePhase.paused) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: controller.resumeDownload,
              child: const Text('Resume'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: controller.cancelDownload,
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (canSkip)
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await controller.ignoreCurrentVersion();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
          ),
        if (canSkip) const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: state.phase == UpdatePhase.downloading ? null : controller.startDownload,
            child: Text(latest.emergencyUpdate ? 'Update now' : 'Download update'),
          ),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? scheme.primary : scheme.onSurface,
              ),
        ),
      ],
    );
  }
}
