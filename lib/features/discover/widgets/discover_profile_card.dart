import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';

class DiscoverProfileCard extends StatelessWidget {
  const DiscoverProfileCard({
    super.key,
    required this.profile,
    required this.timeLabel,
    this.locked = false,
    this.heroTag,
    this.primaryAction,
    this.secondaryAction,
    this.onTap,
    this.onLockedTap,
    this.animationIndex = 0,
  });

  final DuoProfile profile;
  final String timeLabel;
  final bool locked;
  final String? heroTag;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final photo = profile.optimizedDisplayPhoto;
    final distance = profile.previewDistanceKm;

    return GestureDetector(
      onTap: locked ? onLockedTap : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroTag != null)
                Hero(
                  tag: heroTag!,
                  child: _Photo(photo: photo, locked: locked),
                )
              else
                _Photo(photo: photo, locked: locked),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: locked ? 0.55 : 0.8),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              if (locked)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        distance != null
                            ? '${distance.toStringAsFixed(1)} km away'
                            : 'Nearby',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!locked) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${profile.displayName}${profile.age != null ? ', ${profile.age}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (profile.isVerified)
                            const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 18),
                          if (profile.isPremium)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: DuoColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ] else
                      Text(
                        'Premium member',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    Text(
                      timeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (primaryAction != null || secondaryAction != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (primaryAction != null) Expanded(child: primaryAction!),
                          if (secondaryAction != null) ...[
                            const SizedBox(width: 6),
                            secondaryAction!,
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 220.ms,
          delay: (animationIndex.clamp(0, 8) * 40).ms,
        )
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photo, required this.locked});

  final String photo;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (photo.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.person, size: 64, color: Colors.white24),
      );
    }
    return CachedNetworkImage(
      imageUrl: photo,
      fit: BoxFit.cover,
      color: locked ? Colors.black45 : null,
      colorBlendMode: locked ? BlendMode.darken : null,
      placeholder: (_, __) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

void discoverHaptic() => HapticFeedback.lightImpact();
