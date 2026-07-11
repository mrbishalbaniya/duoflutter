import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/models/user_models.dart';
import '../core/theme/duo_theme.dart';

class ProfileSwipeCard extends StatelessWidget {
  const ProfileSwipeCard({
    super.key,
    required this.profile,
    this.locked = false,
  });

  final DuoProfile profile;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final photo = profile.displayPhoto;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.isNotEmpty)
            CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: DuoColors.surfaceVariantDark),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          if (locked)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Icon(Icons.lock, color: Colors.white, size: 48),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locked
                            ? 'Premium member'
                            : '${profile.displayName}${profile.age != null ? ', ${profile.age}' : ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (profile.isVerified)
                      const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 22),
                  ],
                ),
                if (profile.location != null && profile.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: DuoColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.location!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (profile.bio != null && profile.bio!.isNotEmpty && !locked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      profile.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: DuoColors.surfaceVariantDark,
      child: const Center(
        child: Icon(Icons.person, size: 80, color: Colors.white24),
      ),
    );
  }
}
