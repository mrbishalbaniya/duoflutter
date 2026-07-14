import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/media/cloudinary_url.dart';
import '../../../core/media/media_url.dart';
import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../../core/widgets/duo_network_image.dart';

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

  String get _distanceLabel {
    final distance = profile.previewDistanceKm;
    if (distance == null) return 'Nearby';
    final rounded = distance == distance.roundToDouble()
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return '$rounded km away';
  }

  @override
  Widget build(BuildContext context) {
    final photo = resolveProfilePhotoUrl(profile, preset: CloudinaryPreset.discoverCard);
    final name = profile.displayName;
    final ageText = profile.age != null ? ', ${profile.age}' : '';

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
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x26000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.35, 0.65, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (locked) ...[
                      // Match web Discover: blurred name + age, distance below.
                      ClipRect(
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                          child: Text(
                            '$name$ageText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _distanceLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$name$ageText',
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
                    ],
                    if (!locked && (primaryAction != null || secondaryAction != null)) ...[
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
    final image = DuoNetworkImage(
      url: photo,
      fit: BoxFit.cover,
      preset: CloudinaryPreset.discoverCard,
      memCacheWidth: cloudinaryMemCacheWidth(CloudinaryPreset.discoverCard),
    );

    if (!locked) return SizedBox.expand(child: image);

    return SizedBox.expand(
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: image,
        ),
      ),
    );
  }
}

void discoverHaptic() => HapticFeedback.lightImpact();
