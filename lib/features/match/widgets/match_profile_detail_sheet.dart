import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/media_url.dart';
import '../../../core/models/user_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../profile/domain/public_profile.dart';

/// Port of DuoFrontend `ProfileDetailSheet` (components/discover/profileDiscoverUi.tsx)
/// shown from the Match card's info button: iOS-style grouped sheet, records a
/// profile visit when opened.
Future<void> showMatchProfileDetail(
  BuildContext context, {
  required DuoProfile profile,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    // The sheet draws its own grabber; the theme's default handle doubled it.
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => MatchProfileDetailSheet(profile: profile, subtitle: subtitle),
  );
}

class MatchProfileDetailSheet extends ConsumerStatefulWidget {
  const MatchProfileDetailSheet({super.key, required this.profile, this.subtitle});

  final DuoProfile profile;

  /// Extra context line under the location (Discover: "Viewed your profile · 6m ago").
  final String? subtitle;

  @override
  ConsumerState<MatchProfileDetailSheet> createState() => _MatchProfileDetailSheetState();
}

class _MatchProfileDetailSheetState extends ConsumerState<MatchProfileDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Web: `api.recordProfileVisit(profile.id)` when the sheet opens, so the
    // person sees you in their "Visited you" list.
    final profileId = widget.profile.id;
    if (profileId != null) {
      Future.microtask(() => ref.read(profileRepositoryProvider).recordVisit(profileId).catchError((_) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final muted = scheme.onSurfaceVariant;
    final accent = scheme.primary;
    final firstName = p.displayName.split(' ').first;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // Grabber
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          // Navbar: Close · First name · Done
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, size: 20, color: muted),
                    label: const SizedBox.shrink(),
                    style: TextButton.styleFrom(foregroundColor: muted, minimumSize: const Size(44, 44)),
                  ),
                  Expanded(
                    child: Text(
                      firstName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ProfileDetailList(profile: widget.profile, subtitle: widget.subtitle),
          ),
        ],
      ),
    );
  }
}


/// The iOS grouped profile layout (hero, identity, about, details, photos,
/// interests). Shared by the profile sheet and the user's own Profile tab.
class ProfileDetailList extends StatelessWidget {
  const ProfileDetailList({
    super.key,
    required this.profile,
    this.subtitle,
    this.footer = const [],
    this.bottomPadding = 20,
  });

  final DuoProfile profile;
  final String? subtitle;

  /// Extra grouped rows after the profile content (own profile: settings links).
  final List<Widget> footer;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // iOS grouped colours (web --dfs-* tokens).
    final cardBg = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final muted = scheme.onSurfaceVariant;
    final accent = scheme.primary;

    final photos = p.allPhotos.map((u) => resolveMediaUrl(u) ?? u).where((u) => u.isNotEmpty).toList();
    final hero = photos.isNotEmpty ? photos.first : '';
    final more = photos.length > 1 ? photos.sublist(1) : const <String>[];
    final details = buildPublicProfile(p);
    final distance = p.previewDistanceKm;
    final where = distance != null
        ? (distance < 1 ? 'Less than 1 km away' : '${distance.round()} km away')
        : (p.location ?? '').trim();
    final age = '${p.age ?? ''}'.trim();

    Widget caption(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(text, style: TextStyle(fontSize: 13, color: muted)),
        );
    Widget group(Widget child) => Container(
          width: double.infinity,
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
    Widget text(String t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(t, style: const TextStyle(fontSize: 16, height: 1.5)),
        );
    Widget chips() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in details.interests)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        );
    Widget photo(String url) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.5),
                errorWidget: (_, __, ___) => ColoredBox(color: cardBg),
              ),
            ),
          ),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + MediaQuery.paddingOf(context).bottom),
      children: [
                // Hero
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: hero.isEmpty
                        ? ColoredBox(
                            color: cardBg,
                            child: Icon(Icons.person, size: 72, color: muted),
                          )
                        : CachedNetworkImage(
                            imageUrl: hero,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.5),
                            errorWidget: (_, __, ___) =>
                                ColoredBox(color: cardBg, child: Icon(Icons.person, size: 72, color: muted)),
                          ),
                  ),
                ),
                // Identity
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 2),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: p.displayName,
                            children: [
                              if (age.isNotEmpty)
                                TextSpan(
                                  text: ', $age',
                                  style: TextStyle(fontWeight: FontWeight.w500, color: muted),
                                ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
                        ),
                      ),
                      if (p.isVerified) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.verified, size: 22, color: accent),
                      ],
                    ],
                  ),
                ),
                if (where.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Row(
                      children: [
                        Icon(distance != null ? Icons.near_me_outlined : Icons.location_on_outlined,
                            size: 17, color: accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(where,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, color: muted)),
                        ),
                      ],
                    ),
                  ),
                if ((subtitle ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 16, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: muted)),
                        ),
                      ],
                    ),
                  ),
                if (details.bio.isNotEmpty) ...[caption('About'), group(text(details.bio))],
                if (details.lookingFor.isNotEmpty) ...[
                  caption("What I'm looking for"),
                  group(text(details.lookingFor)),
                ],
                for (final section in details.sections) ...[
                  caption(section.title),
                  group(
                    Column(
                      children: [
                        for (var i = 0; i < section.rows.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 58),
                              child: Divider(height: 1, thickness: 0.5, color: muted.withValues(alpha: 0.25)),
                            ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 50),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(section.rows[i].icon, size: 18, color: accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(section.rows[i].label, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
                                    child: Text(
                                      section.rows[i].value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 15, color: muted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (details.interests.isNotEmpty && more.isEmpty) ...[caption('Interests'), group(chips())],
                if (details.futureGoals.isNotEmpty) ...[caption('Future goals'), group(text(details.futureGoals))],
                if (more.isNotEmpty) ...[
                  caption('Photos'),
                  for (var i = 0; i < more.length; i++) ...[
                    photo(more[i]),
                    // Web: interests sit right below the 2nd photo.
                    if (i == 0 && details.interests.isNotEmpty) ...[caption('Interests'), group(chips())],
                  ],
                ],
        ...footer,
      ],
    );
  }
}
