import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/router/app_router.dart';

import '../chat_utils.dart';
import 'chat_typing_indicator.dart';

class ChatThreadHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatThreadHeader({
    super.key,

    required this.conversation,

    required this.isOtherUserTyping,

    this.wsConnected = true,

    this.onVoiceCall,

    this.onVideoCall,

    this.onUnmatch,

    this.onBlock,

    this.onUnmatchAndBlock,

    this.onMute,

    this.onPin,

    this.onNickname,
    this.onProfile,

    this.onPrivacy,

    this.onClearHistory,

    this.onReport,
    this.onUseStarter,
  });

  final Conversation conversation;

  final bool isOtherUserTyping;

  final bool wsConnected;

  final VoidCallback? onVoiceCall;

  final VoidCallback? onVideoCall;

  final VoidCallback? onUnmatch;

  final VoidCallback? onBlock;

  final VoidCallback? onUnmatchAndBlock;

  final VoidCallback? onMute;

  final VoidCallback? onPin;

  final VoidCallback? onNickname;

  /// Web "Show profile".
  final VoidCallback? onProfile;

  final VoidCallback? onPrivacy;

  final VoidCallback? onClearHistory;

  final VoidCallback? onReport;

  /// Conversation starter picked on the Match insights screen ("Use").
  final ValueChanged<String>? onUseStarter;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final photo = conversation.otherUserProfile.displayPhoto;

    final subtitle = isOtherUserTyping
        ? null
        : matchSubtitle(conversation.matchCreatedAt);

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,

      elevation: 0,

      titleSpacing: 0,

      title: InkWell(
        onTap: onProfile,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,

              children: [
                CircleAvatar(
                  radius: 18,

                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,

                  backgroundImage: photo.isNotEmpty
                      ? CachedNetworkImageProvider(photo)
                      : null,

                  child: photo.isEmpty
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),

                if (wsConnected && !isOtherUserTyping)
                  Positioned(
                    right: -1,

                    bottom: -1,

                    child: Container(
                      width: 10,

                      height: 10,

                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,

                        shape: BoxShape.circle,

                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,

                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation.displayName,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),

                      if (conversation.otherUserProfile.isVerified) ...[
                        const SizedBox(width: 4),

                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.lightBlue.shade300,
                        ),
                      ],
                    ],
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isOtherUserTyping
                        ? const ChatTypingLabel(key: ValueKey('typing'))
                        : Text(
                            subtitle ?? '',
                            key: ValueKey(subtitle),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          color: Theme.of(context).colorScheme.primary,
          iconSize: 23,

          icon: const Icon(Icons.call_outlined),

          tooltip: 'Voice call',

          onPressed: onVoiceCall,
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          color: Theme.of(context).colorScheme.primary,
          iconSize: 23,

          icon: const Icon(Icons.videocam_outlined),

          tooltip: 'Video call',

          onPressed: onVideoCall,
        ),

        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert),

          onSelected: (value) async {
            switch (value) {
              case 'insights':
                final starter = await context.push<String>(
                  '${AppRoutes.insights}?match=${conversation.matchId}',
                );
                if (starter != null && starter.isNotEmpty) {
                  onUseStarter?.call(starter);
                }

              case 'profile':
                onProfile?.call();

              case 'nickname':
                onNickname?.call();

              case 'privacy':
                onPrivacy?.call();

              case 'mute':
                onMute?.call();

              case 'pin':
                onPin?.call();

              case 'clear':
                onClearHistory?.call();

              case 'report':
                onReport?.call();

              case 'block':
                onBlock?.call();

              case 'unmatch':
                onUnmatch?.call();

              case 'unmatchBlock':
                onUnmatchAndBlock?.call();
            }
          },

          // Web ChatConversationMenu order and labels; mute / pin / privacy
          // are mobile extras (web has them on the conversation row).
          itemBuilder: (context) {
            final scheme = Theme.of(context).colorScheme;
            PopupMenuItem<String> item(
              String value,
              IconData icon,
              String label, {
              bool danger = false,
            }) => PopupMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: danger ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(color: danger ? scheme.error : null),
                  ),
                ],
              ),
            );
            return [
              if (onProfile != null)
                item('profile', Icons.person_outline, 'Show profile'),
              if (conversation.matchId != null)
                item('insights', Icons.insights_outlined, 'Match insights'),
              item('nickname', Icons.edit_outlined, 'Edit nickname'),
              item('privacy', Icons.shield_outlined, 'Privacy & security'),
              item(
                'mute',
                conversation.isMuted
                    ? Icons.notifications_outlined
                    : Icons.notifications_off_outlined,
                conversation.isMuted ? 'Unmute' : 'Mute',
              ),
              item(
                'pin',
                conversation.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin,
                conversation.isPinned ? 'Unpin' : 'Pin',
              ),
              const PopupMenuDivider(),
              item('block', Icons.block, 'Block', danger: true),
              item(
                'unmatch',
                Icons.heart_broken_outlined,
                'Unmatch',
                danger: true,
              ),
              item(
                'unmatchBlock',
                Icons.do_not_disturb_on_outlined,
                'Unmatch & block',
                danger: true,
              ),
              item(
                'clear',
                Icons.delete_sweep_outlined,
                'Clear chat history',
                danger: true,
              ),
              item('report', Icons.flag_outlined, 'Report', danger: true),
            ];
          },
        ),
      ],
    );
  }
}
