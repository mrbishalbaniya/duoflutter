import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';
import '../map_utils.dart';

class MatchMapCard extends StatelessWidget {
  const MatchMapCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.isActive = false,
  });

  final MapProfile profile;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final p = profile.profile;
    final photo = p.displayPhoto;
    final canFocus = profile.canFocusOnMap;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canFocus ? onTap : null,
        child: Opacity(
          opacity: canFocus ? 1 : 0.7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.surfaceContainerHighest,
                      backgroundImage:
                          photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                      child: photo.isEmpty
                          ? Text(
                              p.displayName.isNotEmpty
                                  ? p.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            )
                          : null,
                    ),
                    if (isActive)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: DuoColors.primary, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.displayName}${p.age != null ? ', ${p.age}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.locationShared && profile.distanceMeters != null
                            ? formatDistanceAway(profile.distanceMeters!)
                            : 'Location hidden',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DuoColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.locationShared
                            ? (p.location?.isNotEmpty == true ? p.location! : 'Nepal')
                            : 'Not sharing location with you',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
