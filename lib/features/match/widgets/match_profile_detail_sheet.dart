import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_url.dart';
import '../../../core/models/user_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/duo_theme.dart';

Future<void> showMatchProfileDetail(
  BuildContext context, {
  required DuoProfile profile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MatchProfileDetailSheet(profile: profile),
  );
}

class MatchProfileDetailSheet extends ConsumerStatefulWidget {
  const MatchProfileDetailSheet({
    super.key,
    required this.profile,
  });

  final DuoProfile profile;

  @override
  ConsumerState<MatchProfileDetailSheet> createState() =>
      _MatchProfileDetailSheetState();
}

class _MatchProfileDetailSheetState extends ConsumerState<MatchProfileDetailSheet> {
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
    final photos = p.allPhotos
        .map((url) => resolveMediaUrl(url) ?? url)
        .where((url) => url.isNotEmpty)
        .toList();
    if (photos.isEmpty) {
      final fallback = resolveProfilePhotoUrl(p);
      if (fallback.isNotEmpty) photos.add(fallback);
    }
    final extraPhotos = photos.length > 1 ? photos.sublist(1) : <String>[];
    final scheme = Theme.of(context).colorScheme;

    final detailItems = <({String label, String value, IconData icon})>[
      if (p.education != null && p.education!.isNotEmpty)
        (label: 'Education', value: p.education!, icon: Icons.school_outlined),
      if (p.occupation != null && p.occupation!.isNotEmpty)
        (label: 'Occupation', value: p.occupation!, icon: Icons.work_outline_rounded),
      if (p.religion != null && p.religion!.isNotEmpty)
        (label: 'Religion', value: p.religion!, icon: Icons.account_balance_outlined),
      if (p.workPreference != null && p.workPreference!.isNotEmpty)
        (label: 'Work', value: p.workPreference!, icon: Icons.business_center_outlined),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
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
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: photos.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photos.first,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Icon(Icons.person, size: 80),
                            ),
                          )
                        : Container(
                            color: scheme.surfaceContainerHighest,
                            child: const Icon(Icons.person, size: 80),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.displayName}${p.age != null ? ', ${p.age}' : ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (p.isVerified)
                                const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent),
                            ],
                          ),
                          if (p.location != null && p.location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: DuoColors.primary, size: 20),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(p.location!)),
                                ],
                              ),
                            ),
                          if (p.isVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: DuoColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        size: 16, color: DuoColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: DuoColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (p.bio != null && p.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ABOUT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(p.bio!, style: const TextStyle(height: 1.45)),
                          ],
                        ),
                      ),
                    ],
                    if (detailItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          for (final item in detailItems)
                            _InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(item.icon, size: 18, color: DuoColors.tertiary),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.label.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.value,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (p.lifestyleTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIFESTYLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final tag in p.lifestyleTags)
                                  Chip(
                                    label: Text(tag),
                                    backgroundColor:
                                        DuoColors.primary.withValues(alpha: 0.1),
                                    side: BorderSide(
                                      color: DuoColors.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (extraPhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'MORE PHOTOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3 / 4,
                        children: [
                          for (final url in extraPhotos)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                            ),
                        ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}
