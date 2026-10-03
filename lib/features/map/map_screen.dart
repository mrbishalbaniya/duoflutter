import '../../core/theme/duo_gradients.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import 'domain/map_domain.dart';
import 'map_models.dart';
import 'map_utils.dart';
import 'providers/map_providers.dart';
import 'widgets/duo_map_view.dart';
import 'widgets/map_focus_card.dart';
import 'widgets/match_avatar_strip.dart';
import 'widgets/zone_detail_sheet.dart';

/// Profile whose card is open: set only by tapping their marker after they
/// have been located (tapping the avatar strip just flies to them).
final _mapCardProfileIdProvider = StateProvider.autoDispose<String?>((ref) => null);

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(liveLocationSyncProvider);
    ref.watch(mapMatchRefreshProvider);
    final screenState = ref.watch(mapScreenControllerProvider);
    final notifier = ref.read(mapScreenControllerProvider.notifier);
    final userLocation = ref.watch(userLocationProvider);
    final matchesAsync = ref.watch(mapMatchesProvider);
    final matches = matchesAsync.valueOrNull ?? const <MapProfile>[];
    final loadingMatches = matchesAsync.isLoading;
    final isFullscreen = screenState.isFullscreen;

    final mapProfiles = matches
        .where((p) => p.locationShared && p.coordinates != null && p.distanceMeters != null)
        .toList();

    final cardId = ref.watch(_mapCardProfileIdProvider);
    MapProfile? cardProfile;
    for (final p in mapProfiles) {
      if (mapProfileKey(p.profile) == cardId) cardProfile = p;
    }

    // Strip avatar: locate only (closes any open card).
    void locateProfile(String id) {
      ref.read(_mapCardProfileIdProvider.notifier).state = null;
      notifier.setFocus(id);
    }

    // Marker on the map: first tap locates, tapping the located one opens the card.
    void onMarkerTap(String id) {
      if (screenState.focusProfileId == id) {
        ref.read(_mapCardProfileIdProvider.notifier).state = id;
      } else {
        locateProfile(id);
      }
    }

    void showZoneSheet(ActivityZone zone) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => ZoneDetailSheet(
          zone: zone,
          onClose: () => Navigator.pop(context),
        ),
      );
    }

    final fallbackCoords = ref.watch(authControllerProvider).user != null
        ? resolveProfileCoordinates(
            location: ref.watch(authControllerProvider).user?.profile.location,
            userId: ref.watch(authControllerProvider).user?.id,
          )
        : nepalMapDefaultCenter;

    Widget buildMap(LatLng userCoords) {
      return DuoMapView(
        profiles: mapProfiles,
        userCoordinates: userCoords,
        focusProfileId: screenState.focusProfileId,
        followMe: screenState.followMe,
        isFullscreen: isFullscreen,
        flyToTarget: screenState.flyToTarget,
        locateNonce: screenState.locateNonce,
        onProfileFocus: onMarkerTap,
        onZoneSelected: showZoneSheet,
        onToggleFollowMe: notifier.toggleFollowMe,
        onToggleFullscreen: () {
          notifier.toggleFullscreen();
          if (!isFullscreen) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        },
        onLocateMe: isFullscreen
            ? null
            : () {
                ref.invalidate(userLocationProvider);
                notifier.locateMe();
              },
        locateLoading: userLocation.isLoading,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                buildMap(
                  userLocation.valueOrNull?.coordinates ?? fallbackCoords,
                ),
                userLocation.when(
                  // No "Finding your location…" banner: the map shows a fallback
                  // view and the locate button spins while the fix comes in.
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => !isFullscreen
                      ? Positioned(
                          top: MediaQuery.paddingOf(context).top + 68,
                          left: 12,
                          right: 12,
                          child: _MapStatusBanner(
                            message: 'Could not determine your location.',
                            icon: Icons.location_disabled,
                            actionLabel: 'Retry',
                            onAction: () => ref.invalidate(userLocationProvider),
                          ),
                        )
                      : const SizedBox.shrink(),
                  data: (location) {
                    if (location.usingFallback &&
                        location.status != LocationPermissionStatus.granted &&
                        !isFullscreen) {
                      return Positioned(
                        top: MediaQuery.paddingOf(context).top + 68,
                        left: 12,
                        right: 12,
                        child: _LocationBanner(status: location.status),
                      );
                    }
                    if (matchesAsync.hasError && matches.isEmpty && !loadingMatches) {
                      return Positioned(
                        left: 16,
                        right: 16,
                        top: MediaQuery.sizeOf(context).height * 0.22,
                        child: _ErrorState(
                          message: 'Could not load your matches.',
                          onRetry: () {
                            ref.invalidate(mapMatchesProvider);
                            ref.invalidate(rawMatchesProvider);
                          },
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          if (!isFullscreen &&
              matches.isEmpty &&
              !loadingMatches &&
              !userLocation.isLoading &&
              userLocation.hasValue)
            // Sits just above the nav bar; the arrow points at the Match tab (centre).
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 2,
              child: const _EmptyMatchesCard(),
            ),
          // Match avatars: one horizontal row above the bottom navigation bar.
          if (!isFullscreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + kMatchStripBottom,
              child: MatchAvatarStrip(
                matches: matches,
                loading: loadingMatches,
                focusProfileId: screenState.focusProfileId,
                onProfileFocus: locateProfile,
              ),
            ),
          if (!isFullscreen && cardProfile != null)
            Positioned.fill(
              child: Center(
                child: MapFocusCard(
                  profile: cardProfile,
                  onClose: () => ref.read(_mapCardProfileIdProvider.notifier).state = null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMatchesCard extends StatelessWidget {
  const _EmptyMatchesCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: scheme.surface.withValues(alpha: 0.94),
          elevation: 6,
          shadowColor: Colors.black38,
          shape: StadiumBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.35))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.go(AppRoutes.match),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Match to see people here',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(gradient: DuoGradients.brand, borderRadius: BorderRadius.circular(999)),
                    child: const Text(
                      'Start',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bouncing arrow guiding to the Match tab right below.
        Icon(Icons.keyboard_double_arrow_down_rounded, size: 30, color: scheme.primary)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -2, end: 6, duration: 700.ms, curve: Curves.easeInOut),
      ],
    );
  }
}

class _MapStatusBanner extends StatelessWidget {
  const _MapStatusBanner({
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _LocationBanner extends ConsumerWidget {
  const _LocationBanner({required this.status});

  final LocationPermissionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = switch (status) {
      LocationPermissionStatus.serviceDisabled =>
        'Location services are off. Using approximate position.',
      LocationPermissionStatus.deniedForever =>
        'Location denied. Enable in settings for accuracy.',
      LocationPermissionStatus.denied =>
        'Location permission denied. Using approximate position.',
      _ => 'Using approximate location.',
    };

    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.location_off_outlined, size: 20),
      actions: [
        if (status == LocationPermissionStatus.deniedForever)
          TextButton(
            onPressed: () => ref.read(locationServiceProvider).openAppSettings(),
            child: const Text('Settings'),
          ),
        TextButton(
          onPressed: () => ref.invalidate(userLocationProvider),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
