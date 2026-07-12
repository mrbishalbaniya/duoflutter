import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/chat_media_save_service.dart';

/// Global hook so the save dialog can receive progress updates.
class ChatMediaSaveDialogController {
  ChatMediaSaveDialogController._();

  static ChatMediaSaveDialogController? instance;

  void Function(GallerySaveProgress progress)? _listener;

  void bind(void Function(GallerySaveProgress progress) listener) {
    _listener = listener;
  }

  void update(GallerySaveProgress progress) => _listener?.call(progress);

  void dispose() {
    if (identical(instance, this)) instance = null;
    _listener = null;
  }
}

class ChatMediaSaveDialog extends StatefulWidget {
  const ChatMediaSaveDialog({super.key, this.onCancel});

  final VoidCallback? onCancel;

  @override
  State<ChatMediaSaveDialog> createState() => _ChatMediaSaveDialogState();
}

class _ChatMediaSaveDialogState extends State<ChatMediaSaveDialog> {
  final _controller = ChatMediaSaveDialogController._();
  String _phase = 'Preparing';
  double? _progress;

  @override
  void initState() {
    super.initState();
    ChatMediaSaveDialogController.instance = _controller;
    _controller.bind((progress) {
      if (!mounted) return;
      setState(() {
        _phase = progress.phase;
        _progress = progress.progress;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.download_rounded, color: scheme.primary, size: 28),
      title: const Text('Saving to gallery'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_progress != null)
            LinearProgressIndicator(value: _progress)
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            _phase,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows a blocking save dialog with progress, then success/error feedback.
Future<void> saveChatMediaToGallery(
  BuildContext context, {
  required String? remoteUrl,
  String? localPath,
}) async {
  final saveService = ChatMediaSaveService();
  final navigator = Navigator.of(context, rootNavigator: true);
  var dialogOpen = true;

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChatMediaSaveDialog(
        onCancel: () {
          dialogOpen = false;
          navigator.pop();
        },
      ),
    ),
  );

  GallerySaveOutcome outcome;
  try {
    outcome = await saveService.saveToGallery(
      remoteUrl: remoteUrl,
      localPath: localPath,
      onProgress: (progress) {
        ChatMediaSaveDialogController.instance?.update(progress);
      },
    );
  } finally {
    if (dialogOpen && navigator.canPop()) {
      navigator.pop();
      dialogOpen = false;
    }
  }

  if (!context.mounted) return;

  if (outcome.isSuccess) {
    await HapticFeedback.lightImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(outcome.message ?? 'Saved to gallery'),
      ),
    );
    return;
  }

  void retry() => saveChatMediaToGallery(
        context,
        remoteUrl: remoteUrl,
        localPath: localPath,
      );

  if (outcome.status == GallerySaveStatus.permissionPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(outcome.message ?? 'Permission denied'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: ChatMediaSaveService.openSettings,
        ),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(outcome.message ?? 'Could not save media'),
      action: SnackBarAction(label: 'Retry', onPressed: retry),
    ),
  );
}

Future<void> shareChatMedia(
  BuildContext context, {
  required String? remoteUrl,
  String? localPath,
}) async {
  final saveService = ChatMediaSaveService();

  try {
    final file = await saveService.resolveMediaFile(
      remoteUrl: remoteUrl,
      localPath: localPath,
    );

    if (file != null && await file.exists()) {
      await Share.shareXFiles([XFile(file.path)]);
      return;
    }

    if (remoteUrl != null && remoteUrl.startsWith('http')) {
      await Share.share(remoteUrl);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not share this media')),
    );
  } catch (_) {
    if (!context.mounted) return;
    if (remoteUrl != null && remoteUrl.startsWith('http')) {
      await Share.share(remoteUrl);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not share this media')),
    );
  }
}
