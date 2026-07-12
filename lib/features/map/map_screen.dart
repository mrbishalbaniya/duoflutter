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
import 'widgets/match_friends_sheet.dart';
import 'widgets/zone_detail_sheet.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    MapProfile? focused;
    if (screenState.focusProfileId != null) {
      for (final profile in matches) {
        if (mapProfileKey(profile.profile) == screenState.focusProfileId) {
          focused = profile;
          break;
        }
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
        onProfileFocus: notifier.setFocus,
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
                  loading: () => !isFullscreen
                      ? Positioned(
                          top: MediaQuery.paddingOf(context).top + 12,
                          left: 12,
                          right: 72,
                          child: const _MapStatusBanner(
                            message: 'Finding your location…',
                            icon: Icons.location_searching,
                          ),
                        )
                      : const SizedBox.shrink(),
                  error: (_, __) => !isFullscreen
                      ? Positioned(
                          top: MediaQuery.paddingOf(context).top + 12,
                          left: 12,
                          right: 72,
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
                        top: MediaQuery.paddingOf(context).top + 12,
                        left: 12,
                        right: 72,
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
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.sizeOf(context).height * 0.22,
              child: const _EmptyMatchesCard(),
            ),
          if (!isFullscreen && focused != null && mapProfiles.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 168,
              child: MapFocusCard(
                profile: focused,
                onClose: () => notifier.setFocus(null),
              ),
            ),
          if (!isFullscreen)
            Positioned.fill(
              child: MatchFriendsSheet(
                matches: matches,
                loading: loadingMatches,
                waitingForLocation: userLocation.isLoading,
                error: matchesAsync.hasError ? 'Could not load your matches.' : null,
                focusProfileId: screenState.focusProfileId,
                onProfileFocus: notifier.setFocus,
                onRetry: () {
                  ref.invalidate(mapMatchesProvider);
                  ref.invalidate(rawMatchesProvider);
                },
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
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Match with someone to see them on the map.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.match),
              child: const Text('Start matching'),
            ),
          ],
        ),
      ),
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

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
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

class _LocationPermissionCard extends ConsumerWidget {
  const _LocationPermissionCard({
    required this.status,
    required this.onRetry,
  });

  final LocationPermissionStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_disabled, size: 48),
            const SizedBox(height: 12),
            const Text('Could not determine your location.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
            if (status == LocationPermissionStatus.deniedForever) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(locationServiceProvider).openAppSettings(),
                child: const Text('Open settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
