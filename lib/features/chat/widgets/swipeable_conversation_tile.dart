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
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onPin;
  final VoidCallback? onMute;

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
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onMute?.call(),
            backgroundColor: Colors.blueGrey.shade700,
            foregroundColor: Colors.white,
            icon: conversation.isMuted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            label: conversation.isMuted ? 'Unmute' : 'Mute',
          ),
        ],
      ),
      child: ConversationTile(
        conversation: conversation,
        onTap: onTap,
      ),
    );
  }
}
