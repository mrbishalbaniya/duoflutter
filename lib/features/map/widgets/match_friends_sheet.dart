import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';
import '../map_utils.dart';
import 'match_map_card.dart';

class MatchFriendsSheet extends StatelessWidget {
  const MatchFriendsSheet({
    super.key,
    required this.matches,
    required this.loading,
    required this.waitingForLocation,
    required this.error,
    required this.focusProfileId,
    required this.onProfileFocus,
    required this.onRetry,
  });

  final List<MapProfile> matches;
  final bool loading;
  final bool waitingForLocation;
  final String? error;
  final String? focusProfileId;
  final ValueChanged<String> onProfileFocus;
  final VoidCallback onRetry;

  String get _subtitle {
    if (loading) return 'Loading…';
    if (waitingForLocation) return 'Finding your location…';
    return '${matches.length} ${matches.length == 1 ? 'match' : 'matches'} near you';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.18,
      maxChildSize: 0.72,
      snap: true,
      snapSizes: const [0.18, 0.28, 0.72],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DuoColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map, color: DuoColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your matches',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            _subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _FriendsListBody(
                  scrollController: scrollController,
                  matches: matches,
                  loading: loading,
                  waitingForLocation: waitingForLocation,
                  error: error,
                  focusProfileId: focusProfileId,
                  onProfileFocus: onProfileFocus,
                  onRetry: onRetry,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendsListBody extends StatelessWidget {
  const _FriendsListBody({
    required this.scrollController,
    required this.matches,
    required this.loading,
    required this.waitingForLocation,
    required this.error,
    required this.focusProfileId,
    required this.onProfileFocus,
    required this.onRetry,
  });

  final ScrollController scrollController;
  final List<MapProfile> matches;
  final bool loading;
  final bool waitingForLocation;
  final String? error;
  final String? focusProfileId;
  final ValueChanged<String> onProfileFocus;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading) {
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: scheme.surfaceContainerHighest,
            highlightColor: scheme.surfaceContainer,
            child: Row(
              children: [
                const CircleAvatar(radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 90, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (error != null && matches.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (matches.isEmpty && !waitingForLocation) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Match with someone to see them on the map.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.match),
              child: const Text('Start matching'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: matches.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 68,
        color: scheme.outline.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        final item = matches[index];
        final key = mapProfileKey(item.profile);
        return MatchMapCard(
          profile: item,
          isActive: focusProfileId == key,
          onTap: () => onProfileFocus(key),
        );
      },
    );
  }
}
