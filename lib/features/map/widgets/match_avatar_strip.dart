import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/media_url.dart';
import '../../../core/theme/theme_extensions.dart';
import '../map_models.dart';
import '../map_utils.dart';

/// Height of the strip (avatar + name) — used to place controls above it.
const double kMatchAvatarStripHeight = 58;

/// Gap above the bottom navigation bar. The shell's Scaffold uses
/// `extendBody`, so MediaQuery bottom padding here already includes the nav
/// bar height; only a small gap is added on top.
const double kMatchStripBottom = 6;

/// Height of the layers + locate button stack that sits on the strip's top-right.
const double kMapBottomControlsHeight = 132;

/// Horizontally scrolling row of match avatars over the map (replaces the
/// iOS-style "Your matches" sheet). Tap an avatar to focus that person.
class MatchAvatarStrip extends StatelessWidget {
  const MatchAvatarStrip({
    super.key,
    required this.matches,
    required this.loading,
    required this.focusProfileId,
    required this.onProfileFocus,
  });

  final List<MapProfile> matches;
  final bool loading;
  final String? focusProfileId;
  final ValueChanged<String> onProfileFocus;

  @override
  Widget build(BuildContext context) {
    if (!loading && matches.isEmpty) return const SizedBox.shrink();
    // Nearest first; people without a known distance go last.
    final sorted = [...matches]
      ..sort((a, b) {
        final da = a.distanceMeters, db = b.distanceMeters;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    return SizedBox(
      height: kMatchAvatarStripHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: loading && matches.isEmpty ? 5 : sorted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (loading && matches.isEmpty) {
                  return const _AvatarPlaceholder();
                }
                final item = sorted[i];
                final key = mapProfileKey(item.profile);
                return _MatchAvatar(
                  item: item,
                  active: focusProfileId == key,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onProfileFocus(key);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MapProfile item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final p = item.profile;
    final url = resolveProfilePhotoUrl(p);
    final first = p.displayName.split(' ').first;
    final initial = first.isNotEmpty ? first[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? duo.brandGradient : null,
                color: active ? null : Colors.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: duo.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest,
                    ),
                    child: SizedBox.expand(
                      child: url.isEmpty
                          ? Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Green dot = sharing live location.
                  if (item.locationShared)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
