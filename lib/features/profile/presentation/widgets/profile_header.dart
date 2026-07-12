import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/theme/duo_gradients.dart';
import '../../../../core/theme/duo_theme.dart';
import '../../domain/profile_domain.dart';
import 'profile_responsive.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onSettings,
    this.heroTag,
  });

  final DuoProfile profile;
  final VoidCallback onSettings;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = profile.displayPhoto;
    final tag = heroTag ?? profileHeroTag(profile);
    final heroHeight = ProfileResponsive.heroHeight(context);
    final avatarRadius = ProfileResponsive.avatarRadius(context);
    final coverPhoto = profile.allPhotos.isNotEmpty ? profile.allPhotos.first : photo;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: heroHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverPhoto.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: coverPhoto,
                      fit: BoxFit.cover,
                      color: scheme.surface.withValues(alpha: 0.15),
                      colorBlendMode: BlendMode.darken,
                    )
                  else
                    const DecoratedBox(decoration: BoxDecoration(gradient: DuoGradients.profileHero)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.surface.withValues(alpha: 0.05),
                          scheme.surface.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 4,
                    right: 12,
                    child: IconButton.filledTonal(
                      tooltip: 'Settings',
                      onPressed: onSettings,
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.surface.withValues(alpha: 0.65),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: ProfileResponsive.horizontalPadding(context),
              right: ProfileResponsive.horizontalPadding(context),
              bottom: -(avatarRadius + 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Hero(
                                tag: tag,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: scheme.surface, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DuoColors.primary.withValues(alpha: 0.28),
                                        blurRadius: 24,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: scheme.surfaceContainerHighest,
                                    backgroundImage: photo.isNotEmpty
                                        ? CachedNetworkImageProvider(photo)
                                        : null,
                                    child: photo.isEmpty
                                        ? Icon(Icons.person, size: avatarRadius, color: scheme.onSurfaceVariant)
                                        : null,
                                  ),
                                ),
                              ),
                              if (profile.isVerified)
                                Positioned(
                                  right: 2,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.shadow.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 20,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${profile.displayName}${profile.age != null ? ', ${profile.age}' : ''}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              height: 1.1,
                                            ),
                                      ),
                                    ),
                                    if (profile.isPremium)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: DuoGradients.brandBr,
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Text(
                                          'PRO',
                                          style: TextStyle(
                                            color: scheme.onPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (profile.location != null && profile.location!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 16, color: scheme.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          profile.location!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: scheme.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (profile.occupation != null && profile.occupation!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      profile.occupation!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if ((profile.bio ?? '').trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      profile.bio!.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: scheme.onSurface.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
            ),
          ],
        );
      },
    );
  }
}
