import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_gradients.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/profile_domain.dart';

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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(gradient: DuoGradients.profileHero),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filledTonal(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: -56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: tag,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: DuoColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: photo.isNotEmpty
                        ? CachedNetworkImageProvider(photo)
                        : null,
                    child: photo.isEmpty
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                ),
                          ),
                        ),
                        if (profile.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, color: Colors.lightBlueAccent),
                          ),
                        if (profile.isPremium)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: DuoGradients.brandBr,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (profile.location != null && profile.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: DuoColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                profile.location!,
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (profile.occupation != null && profile.occupation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          profile.occupation!,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}
