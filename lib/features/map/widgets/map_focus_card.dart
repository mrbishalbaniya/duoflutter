import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';
import '../map_utils.dart';
import '../providers/map_providers.dart';

class MapFocusCard extends ConsumerWidget {
  const MapFocusCard({
    super.key,
    required this.profile,
    required this.onClose,
  });

  final MapProfile profile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile.profile;
    final photo = p.displayPhoto;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'map-focus-${mapProfileKey(p)}',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage:
                    photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                child: photo.isEmpty
                    ? Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${p.displayName}${p.age != null ? ', ${p.age}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (profile.distanceMeters != null)
                    Text(
                      formatDistanceAway(profile.distanceMeters!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DuoColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  Text(
                    p.location?.isNotEmpty == true ? p.location! : 'Nepal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final map = ref.read(matchConversationIdsProvider).valueOrNull;
                final conversationId = map?[profile.matchId];
                if (conversationId != null) {
                  context.push('/chat/$conversationId');
                } else {
                  context.go(AppRoutes.chat);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              color: DuoColors.primary,
              tooltip: 'Open chat',
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Close preview',
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
