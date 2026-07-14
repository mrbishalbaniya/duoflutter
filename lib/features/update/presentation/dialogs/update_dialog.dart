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
          scale: Tween<double>(begin: 0.96, end: 1).animate(
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(updateControllerProvider);
    final latest = state.latest;
    final installed = state.installed;

    if (latest == null) {
      return const SizedBox.shrink();
    }

    final canSkip = !widget.blocking && latest.canSkip;
    final headline = latest.emergencyUpdate
        ? 'Critical update required'
        : latest.forceUpdate
            ? 'Update required'
            : 'Update available';
    final visibleNotes = latest.visibleNotes;
    final moreCount = latest.moreNotesCount;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.98),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        headline,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Duo ${latest.latestVersion} (Build ${latest.buildNumber})'
                        '${latest.fileSize.isNotEmpty && latest.fileSize != 'Unknown' ? ' · ${latest.fileSize}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (latest.releaseTitle.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          latest.releaseTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _VersionBlock(
                        label: 'Installed Version',
                        value: installed == null ? '—' : installed.version,
                      ),
                      const SizedBox(height: 12),
                      _VersionBlock(
                        label: 'Latest Version',
                        value: '${latest.latestVersion} (Build ${latest.buildNumber})',
                        emphasize: true,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        "What's New",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...visibleNotes.map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: scheme.onSurfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  note,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.35,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (moreCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: Text(
                            '+$moreCount more improvements',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (state.phase == UpdatePhase.downloading ||
                          state.phase == UpdatePhase.paused ||
                          state.phase == UpdatePhase.readyToInstall) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: state.progress > 0 ? state.progress : null,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.phase == UpdatePhase.readyToInstall
                              ? 'Ready to install'
                              : '${(state.progress * 100).toStringAsFixed(0)}% · ${formatSpeed(state.downloadSpeedBps)} · ${formatEta(state.etaSeconds)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _buildActions(context, state, latest, canSkip),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: 0.03, end: 0);
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
          const SizedBox(width: 12),
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
          const SizedBox(width: 12),
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
        if (canSkip) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: state.phase == UpdatePhase.downloading ? null : controller.startDownload,
            child: const Text('Update Now'),
          ),
        ),
      ],
    );
  }
}

class _VersionBlock extends StatelessWidget {
  const _VersionBlock({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: emphasize ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
