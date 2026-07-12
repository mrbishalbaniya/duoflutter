import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/theme/duo_gradients.dart';
import '../../../../core/theme/theme_extensions.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.profile,
    required this.email,
    this.onTap,
    this.heroTag,
  });

  final DuoProfile profile;
  final String email;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final photo = profile.displayPhoto;
    final tag = heroTag ?? 'settings-profile-avatar';

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surfaceContainerHigh,
                  scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                ],
              ),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Hero(
                    tag: tag,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: scheme.surfaceContainerHighest,
                          backgroundImage:
                              photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                          child: photo.isEmpty
                              ? Icon(Icons.person_rounded, size: 34, color: scheme.onSurfaceVariant)
                              : null,
                        ),
                        if (profile.isVerified)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified_rounded, size: 18, color: duo.success),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ),
                            if (profile.isPremium) ...[
                              const SizedBox(width: 8),
                              _PremiumChip(color: duo.premium),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.username?.isNotEmpty == true ? '@${profile.username}' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Profile ${profile.profileCompleteness}%',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: profile.profileCompleteness / 100),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) => LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                    backgroundColor: scheme.surfaceContainerHighest,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DuoGradients.brand,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 14, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
