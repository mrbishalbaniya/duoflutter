import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';
import '../map_utils.dart';
import '../providers/map_providers.dart';
import '../../match/widgets/match_profile_detail_sheet.dart';

class MapFocusCard extends ConsumerWidget {
  const MapFocusCard({super.key, required this.profile, required this.onClose});

  final MapProfile profile;
  final VoidCallback onClose;

  Future<void> _openRoute(BuildContext context) async {
    final c = profile.coordinates;
    if (c == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not shared')));
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${c.latitude},${c.longitude}&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openChat(BuildContext context, WidgetRef ref) {
    final map = ref.read(matchConversationIdsProvider).valueOrNull;
    final conversationId = map?[profile.matchId];
    if (conversationId != null) {
      context.push('/chat/$conversationId');
    } else {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile.profile;
    final photo = p.displayPhoto;
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final initial = p.displayName.isNotEmpty
        ? p.displayName[0].toUpperCase()
        : '?';

    Widget action(
      IconData icon,
      String tip,
      VoidCallback onTap, {
      bool primary = false,
    }) => Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: primary ? duo.brandGradient : null,
            color: primary ? null : scheme.surfaceContainerHighest,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(
              icon,
              color: primary ? Colors.white : scheme.onSurface,
              size: 24,
            ),
          ),
        ),
      ),
    );

    return Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DuoColors.primary.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: DuoColors.primary.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => showMatchProfileDetail(context, profile: p),
                  child: Hero(
                    tag: 'map-focus-${mapProfileKey(p)}',
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: duo.brandGradient,
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: scheme.surfaceContainerHighest,
                        backgroundImage: photo.isNotEmpty
                            ? CachedNetworkImageProvider(photo)
                            : null,
                        child: photo.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${p.displayName}${p.age != null ? ', ${p.age}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.distanceMeters != null
                      ? formatDistanceAway(profile.distanceMeters!)
                      : (p.location?.isNotEmpty == true
                            ? p.location!
                            : 'Distance unknown'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DuoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    action(
                      Icons.directions_rounded,
                      'Find route',
                      () => _openRoute(context),
                      primary: true,
                    ),
                    action(
                      Icons.chat_bubble_outline_rounded,
                      'Open chat',
                      () => _openChat(context, ref),
                    ),
                    action(Icons.close_rounded, 'Close', onClose),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}
