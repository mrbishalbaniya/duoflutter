import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_models.dart';
import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../widgets/duo_ui.dart';
import '../auth/auth_controller.dart';
import 'domain/match_domain.dart';
import 'providers/match_providers.dart';
import 'widgets/discovery_filters_sheet.dart';
import 'widgets/match_action_bar.dart';
import 'widgets/match_card_overlay.dart';
import 'widgets/match_empty_state.dart';
import 'widgets/match_profile_detail_sheet.dart';
import 'widgets/match_skeleton.dart';
import 'widgets/swipeable_card_stack.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  final _stackKey = GlobalKey<SwipeableCardStackState>();

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(matchDeckControllerProvider);
    final userPrefs = ref.watch(authControllerProvider).user?.profile;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  DuoIconCircleButton(
                    icon: Icons.tune_rounded,
                    onTap: () {
                      if (!deck.controlsDisabled) {
                        showDiscoveryFiltersSheet(context, ref);
                      }
                    },
                  ),
                  const Expanded(child: Center(child: DuoBrandLogo(size: 22))),
                  DuoIconCircleButton(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      if (!deck.refreshing && !deck.loading) {
                        ref.read(matchDeckControllerProvider.notifier).loadProfiles(
                              refresh: true,
                              clearSwiped: true,
                            );
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: deck.loading
                  ? const MatchSkeleton()
                  : deck.currentProfile == null
                      ? MatchEmptyState(
                          userPrefs: userPrefs,
                          refreshing: deck.refreshing,
                          onAdjustFilters: () => showDiscoveryFiltersSheet(context, ref),
                          onRefresh: () => ref
                              .read(matchDeckControllerProvider.notifier)
                              .loadProfiles(refresh: true, clearSwiped: true),
                        )
                      : _MatchDeckView(
                          // Remount only on explicit refresh/filter — not every swipe
                          // (rebuilding the full id list remounted the same top card).
                          key: ValueKey('deck-${deck.stackKey}'),
                          stackKey: _stackKey,
                          deck: deck,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDeckView extends ConsumerWidget {
  const _MatchDeckView({
    super.key,
    required this.stackKey,
    required this.deck,
  });

  final GlobalKey<SwipeableCardStackState> stackKey;
  final MatchDeckState deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bottom → top: last entry is the front card (current profile).
    final displayDeck = deck.deckProfiles.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Expanded(
            child: SwipeableCardStack(
              key: stackKey,
              profiles: displayDeck,
              disabled: deck.controlsDisabled,
              overlayBuilder: (profile, isTop) => MatchCardOverlay(
                profile: profile,
                isTopCard: isTop,
                infoDisabled: deck.controlsDisabled,
                onInfoTap: isTop
                    ? () => _openDetail(context, ref, profile)
                    : null,
              ),
              onSwipe: (direction, profile) {
                if (deck.controlsDisabled) return false;
                final action = direction == SwipeDirection.right
                    ? SwipeAction.like
                    : SwipeAction.skip;
                _handleSwipe(context, ref, profile, action);
                return true;
              },
            ),
          ),
          MatchActionBar(
            disabled: deck.controlsDisabled,
            onSkip: () => stackKey.currentState?.swipeTop(SwipeDirection.left),
            onInfo: () {
              // Always read latest current profile at tap time.
              final live = ref.read(matchDeckControllerProvider).currentProfile;
              if (live != null) _openDetail(context, ref, live);
            },
            onLike: () => stackKey.currentState?.swipeTop(SwipeDirection.right),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, DuoProfile profile) {
    ref.read(matchDeckControllerProvider.notifier).setDetailOpen(true);
    showMatchProfileDetail(
      context,
      profile: profile,
    ).whenComplete(
      () => ref.read(matchDeckControllerProvider.notifier).setDetailOpen(false),
    );
  }

  Future<void> _handleSwipe(
    BuildContext context,
    WidgetRef ref,
    DuoProfile profile,
    SwipeAction action,
  ) async {
    try {
      final result = await ref.read(matchDeckControllerProvider.notifier).swipeProfile(
            profile: profile,
            action: action,
          );
      if (!context.mounted) return;
      if (result?.isMatch == true && result?.match != null) {
        context.push(AppRoutes.matchCelebration, extra: result!.match);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
