import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import 'conversation_tile.dart';

class SwipeableConversationTile extends StatelessWidget {
  const SwipeableConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onPin,
    this.onMute,
    this.onArchive,
    this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final VoidCallback? onMute;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(conversation.publicId),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onPin?.call(),
            backgroundColor: DuoColors.primary,
            foregroundColor: Colors.white,
            icon: conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: conversation.isPinned ? 'Unpin' : 'Pin',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            onPressed: (_) => onArchive?.call(),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            icon: conversation.isArchived ? Icons.unarchive : Icons.archive_outlined,
            label: conversation.isArchived ? 'Restore' : 'Archive',
          ),
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: ConversationTile(
        conversation: conversation,
        onTap: onTap,
        onPin: onPin,
        onMute: onMute,
        onArchive: onArchive,
        onDelete: onDelete,
      ),
    );
  }
}
