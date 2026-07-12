import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';



import '../../../core/models/chat_models.dart';

import '../../../core/theme/duo_theme.dart';

import '../chat_utils.dart';



class ChatThreadHeader extends StatelessWidget implements PreferredSizeWidget {

  const ChatThreadHeader({

    super.key,

    required this.conversation,

    required this.isOtherUserTyping,

    this.wsConnected = true,

    this.onVoiceCall,

    this.onVideoCall,

    this.onUnmatch,

    this.onMute,

    this.onPin,

    this.onNickname,

    this.onClearHistory,

    this.onReport,

  });



  final Conversation conversation;

  final bool isOtherUserTyping;

  final bool wsConnected;

  final VoidCallback? onVoiceCall;

  final VoidCallback? onVideoCall;

  final VoidCallback? onUnmatch;

  final VoidCallback? onMute;

  final VoidCallback? onPin;

  final VoidCallback? onNickname;

  final VoidCallback? onClearHistory;

  final VoidCallback? onReport;



  @override

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);



  @override

  Widget build(BuildContext context) {

    final photo = conversation.otherUserProfile.displayPhoto;

    final subtitle = isOtherUserTyping
        ? 'Typing…'
        : matchSubtitle(conversation.matchCreatedAt);



    return AppBar(

      backgroundColor: Theme.of(context).colorScheme.surface,

      elevation: 0,

      titleSpacing: 0,

      title: Row(

        children: [

          Stack(

            clipBehavior: Clip.none,

            children: [

              CircleAvatar(

                radius: 18,

                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,

                backgroundImage:

                    photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,

                child: photo.isEmpty ? const Icon(Icons.person, size: 18) : null,

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

                        style: Theme.of(context).textTheme.titleMedium?.copyWith(

                              fontWeight: FontWeight.w700,

                            ),

                      ),

                    ),

                    if (conversation.otherUserProfile.isVerified) ...[

                      const SizedBox(width: 4),

                      Icon(Icons.verified, size: 16, color: Colors.lightBlue.shade300),

                    ],

                  ],

                ),

                AnimatedSwitcher(

                  duration: const Duration(milliseconds: 200),

                  child: Text(

                    subtitle,

                    key: ValueKey(subtitle),

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOtherUserTyping
                              ? DuoColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight:
                              isOtherUserTyping ? FontWeight.w600 : FontWeight.w400,
                        ),

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

      actions: [

        IconButton(

          icon: const Icon(Icons.call_outlined),

          tooltip: 'Voice call',

          onPressed: onVoiceCall,

        ),

        IconButton(

          icon: const Icon(Icons.videocam_outlined),

          tooltip: 'Video call',

          onPressed: onVideoCall,

        ),

        if (conversation.matchId != null)

          IconButton(

            icon: const Icon(Icons.insights_outlined),

            tooltip: 'Match insights',

            onPressed: () {

              ScaffoldMessenger.of(context).showSnackBar(

                const SnackBar(content: Text('Match insights coming soon on mobile.')),

              );

            },

          ),

        PopupMenuButton<String>(

          onSelected: (value) {

            switch (value) {

              case 'nickname':

                onNickname?.call();

              case 'mute':

                onMute?.call();

              case 'pin':

                onPin?.call();

              case 'clear':

                onClearHistory?.call();

              case 'report':

                onReport?.call();

              case 'unmatch':

                onUnmatch?.call();

            }

          },

          itemBuilder: (_) => [

            const PopupMenuItem(value: 'nickname', child: Text('Set nickname')),

            PopupMenuItem(

              value: 'mute',

              child: Text(conversation.isMuted ? 'Unmute' : 'Mute'),

            ),

            PopupMenuItem(

              value: 'pin',

              child: Text(conversation.isPinned ? 'Unpin' : 'Pin'),

            ),

            const PopupMenuItem(value: 'clear', child: Text('Clear history')),

            const PopupMenuItem(

              value: 'report',

              child: Text('Report', style: TextStyle(color: Colors.orange)),

            ),

            const PopupMenuItem(

              value: 'unmatch',

              child: Text('Unmatch & block', style: TextStyle(color: Colors.redAccent)),

            ),

          ],

        ),

      ],

    );

  }

}

