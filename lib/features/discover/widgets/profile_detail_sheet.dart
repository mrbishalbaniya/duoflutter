import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/discover_models.dart';

class ProfileDetailSheet extends ConsumerStatefulWidget {
  const ProfileDetailSheet({
    super.key,
    required this.profile,
    required this.heroTag,
    this.timeLabel,
  });

  final DuoProfile profile;
  final String heroTag;
  final String? timeLabel;

  @override
  ConsumerState<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends ConsumerState<ProfileDetailSheet> {
  @override
  void initState() {
    super.initState();
    final profileId = widget.profile.id;
    if (profileId != null) {
      Future.microtask(
        () => ref.read(profileRepositoryProvider).recordVisit(profileId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final photo = p.displayPhoto;
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: Hero(
                  tag: widget.heroTag,
                  child: photo.isNotEmpty
                      ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          child: const Icon(Icons.person, size: 80),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${p.displayName}${p.age != null ? ', ${p.age}' : ''}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (p.isVerified)
                          const Icon(Icons.verified, color: Colors.lightBlueAccent),
                      ],
                    ),
                    if (widget.timeLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.timeLabel!,
                        style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (p.location?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: DuoColors.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(p.location!)),
                        ],
                      ),
                    ],
                    if (p.previewDistanceKm != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${p.previewDistanceKm!.toStringAsFixed(1)} km away',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (p.bio?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      Text(
                        p.bio!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void showProfileDetailSheet(
  BuildContext context, {
  required DuoProfile profile,
  String? timeLabel,
}) {
  final tag = profileHeroTag(profile);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileDetailSheet(
      profile: profile,
      heroTag: tag,
      timeLabel: timeLabel,
    ),
  );
}
