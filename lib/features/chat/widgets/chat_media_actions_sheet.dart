import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/chat_models.dart';
import '../domain/chat_media_utils.dart';
import 'chat_media_save_dialog.dart';

/// Context for media actions in chat or profile viewers.
class ChatMediaActionContext {
  const ChatMediaActionContext({
    required this.remoteUrl,
    this.localPath,
    this.senderName,
    this.timestamp,
    this.isMine = false,
    this.canDeleteForEveryone = false,
    this.message,
    this.onReply,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  final String remoteUrl;
  final String? localPath;
  final String? senderName;
  final String? timestamp;
  final bool isMine;
  final bool canDeleteForEveryone;
  final ChatMessage? message;
  final VoidCallback? onReply;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  bool get hasRemoteLink => remoteUrl.startsWith('http');
}

Future<void> showChatMediaActionsSheet(
  BuildContext context, {
  required ChatMediaActionContext media,
}) async {
  await HapticFeedback.mediumImpact();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ChatMediaActionsSheet(media: media),
  );
}

class _ChatMediaActionsSheet extends StatelessWidget {
  const _ChatMediaActionsSheet({required this.media});

  final ChatMediaActionContext media;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = mediaTypeLabel(url: media.remoteUrl, localPath: media.localPath);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.perm_media_outlined, color: scheme.onPrimaryContainer),
            ),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              media.senderName ?? 'Shared media',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.download_rounded,
            title: 'Save to Gallery',
            onTap: () => _save(context),
          ),
          _ActionTile(
            icon: Icons.ios_share_rounded,
            title: 'Share',
            onTap: () => _share(context),
          ),
          if (media.onReply != null)
            _ActionTile(
              icon: Icons.forward_rounded,
              title: 'Forward',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Forward is not available yet.')),
                );
              },
            ),
          if (media.onReply != null)
            _ActionTile(
              icon: Icons.reply_rounded,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                media.onReply?.call();
              },
            ),
          if (media.hasRemoteLink)
            _ActionTile(
              icon: Icons.link_rounded,
              title: 'Copy link',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: media.remoteUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            ),
          if (media.canDeleteForEveryone && media.onDeleteForEveryone != null)
            _ActionTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete for everyone',
              iconColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                media.onDeleteForEveryone?.call();
              },
            ),
          if (media.onDeleteForMe != null)
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete for me',
              onTap: () {
                Navigator.pop(context);
                media.onDeleteForMe?.call();
              },
            ),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'View details',
            onTap: () {
              Navigator.pop(context);
              _showDetails(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    Navigator.pop(context);
    await saveChatMediaToGallery(
      context,
      remoteUrl: media.remoteUrl,
      localPath: media.localPath,
    );
  }

  Future<void> _share(BuildContext context) async {
    Navigator.pop(context);
    await shareChatMedia(
      context,
      remoteUrl: media.remoteUrl,
      localPath: media.localPath,
    );
  }

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Media details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: mediaTypeLabel(url: media.remoteUrl)),
            if (media.senderName != null)
              _DetailRow(label: 'From', value: media.senderName!),
            if (media.timestamp != null && media.timestamp!.isNotEmpty)
              _DetailRow(label: 'Sent', value: media.timestamp!),
            if (media.hasRemoteLink)
              _DetailRow(label: 'URL', value: media.remoteUrl, multiline: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: multiline ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
