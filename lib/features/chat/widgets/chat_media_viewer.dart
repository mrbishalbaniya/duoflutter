import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/chat_models.dart';
import '../domain/chat_media_utils.dart';
import 'chat_media_actions_sheet.dart';

/// Full-screen chat media viewer with Material 3 actions.
class ChatMediaViewer extends StatelessWidget {
  const ChatMediaViewer({
    super.key,
    required this.remoteUrl,
    this.localPath,
    this.heroTag,
    this.senderName,
    this.timestamp,
    this.isMine = false,
    this.message,
    this.onReply,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  final String remoteUrl;
  final String? localPath;
  final String? heroTag;
  final String? senderName;
  final String? timestamp;
  final bool isMine;
  final ChatMessage? message;
  final VoidCallback? onReply;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  static void open(
    BuildContext context, {
    required String remoteUrl,
    String? localPath,
    String? heroTag,
    String? senderName,
    String? timestamp,
    bool isMine = false,
    ChatMessage? message,
    VoidCallback? onReply,
    VoidCallback? onDeleteForMe,
    VoidCallback? onDeleteForEveryone,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatMediaViewer(
          remoteUrl: remoteUrl,
          localPath: localPath,
          heroTag: heroTag,
          senderName: senderName,
          timestamp: timestamp,
          isMine: isMine,
          message: message,
          onReply: onReply,
          onDeleteForMe: onDeleteForMe,
          onDeleteForEveryone: onDeleteForEveryone,
        ),
      ),
    );
  }

  ChatMediaActionContext get _actionContext => ChatMediaActionContext(
        remoteUrl: remoteUrl,
        localPath: localPath,
        senderName: senderName,
        timestamp: timestamp,
        isMine: isMine,
        canDeleteForEveryone:
            isMine && message != null && !message!.isDeletedForEveryone,
        message: message,
        onReply: onReply,
        onDeleteForMe: onDeleteForMe,
        onDeleteForEveryone: onDeleteForEveryone,
      );

  @override
  Widget build(BuildContext context) {
    final isVideo = isVideoMediaUrl(remoteUrl) || isVideoMediaUrl(localPath);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        title: Text(mediaTypeLabel(url: remoteUrl, localPath: localPath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onPressed: () => showChatMediaActionsSheet(
              context,
              media: _actionContext,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showChatMediaActionsSheet(context, media: _actionContext);
        },
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: _MediaBody(
              remoteUrl: remoteUrl,
              localPath: localPath,
              heroTag: heroTag,
              isVideo: isVideo,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaBody extends StatelessWidget {
  const _MediaBody({
    required this.remoteUrl,
    this.localPath,
    this.heroTag,
    required this.isVideo,
  });

  final String remoteUrl;
  final String? localPath;
  final String? heroTag;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (isVideo) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white70, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Video preview is not available.\nUse Save to Gallery to download.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    Widget image;
    if (localPath != null && File(localPath!).existsSync()) {
      image = Image.file(
        File(localPath!),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: remoteUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: image);
    }
    return image;
  }
}

/// Opens chat media in the full-screen viewer.
void openChatMediaViewer(
  BuildContext context, {
  required ChatMessage message,
  VoidCallback? onReply,
  VoidCallback? onDeleteForMe,
  VoidCallback? onDeleteForEveryone,
}) {
  final url = message.imageUrl;
  if (url == null || url.isEmpty) return;
  if (!hasSavableChatMedia(message)) return;

  ChatMediaViewer.open(
    context,
    remoteUrl: url,
    localPath: message.localMediaPath,
    heroTag: 'chat-image-$url',
    senderName: message.senderName,
    timestamp: message.timestamp,
    isMine: message.isMine,
    message: message,
    onReply: onReply,
    onDeleteForMe: onDeleteForMe,
    onDeleteForEveryone: onDeleteForEveryone,
  );
}
