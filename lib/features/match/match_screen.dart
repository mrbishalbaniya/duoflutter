import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_models.dart';
import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/duo_ui.dart';
import '../auth/auth_controller.dart';
import '../discover/domain/discover_models.dart';
import '../discover/widgets/premium_upgrade_sheet.dart';
import 'domain/match_domain.dart';
import 'providers/match_providers.dart';
import 'widgets/discovery_filters_sheet.dart';
import 'widgets/match_action_bar.dart';
import 'widgets/match_card_overlay.dart';
import 'widgets/match_empty_state.dart';
import 'widgets/match_menu_sheet.dart';
import 'widgets/match_profile_detail_sheet.dart';
import 'widgets/match_skeleton.dart';
import 'widgets/match_tour.dart';
import 'widgets/swipeable_card_stack.dart';
import '../../widgets/duo_profile_avatar_button.dart';

/// Mirrors web `/match` (`DiscoverExperience`): menu + filters top bar, swipe
/// deck, Skip · Rewind · Like, like limit and rewind paywalls, empty states
/// and the first-visit tour.
class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  // Recreated whenever the deck version (stackKey) changes. Reusing one
  // GlobalKey made Flutter *reparent* the old SwipeableCardStack state into the
  // "new" deck after filters/refresh, so it kept stale cards / a stuck swipe.
  var _stackKey = GlobalKey<SwipeableCardStackState>();
  int? _stackKeyVersion;
  final _menuKey = GlobalKey();
  final _filtersKey = GlobalKey();
  var _cardKey = GlobalKey();
  final _skipKey = GlobalKey();
  final _rewindKey = GlobalKey();
  final _likeKey = GlobalKey();
  final _infoKey = GlobalKey();

  bool _tourOpen = false;
  bool _tourChecked = false;

  MatchDeckController get _deck => ref.read(matchDeckControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // A freshly mounted Match screen can't have its filters/detail sheet open,
    // so clear any stale lock left by a previous instance (kept-alive deck).
    Future.microtask(() {
      if (!mounted) return;
      final deck = ref.read(matchDeckControllerProvider);
      if (deck.filtersOpen) _deck.setFiltersOpen(false);
      if (deck.detailOpen) _deck.setDetailOpen(false);
    });
  }

  String? get _tourStorageKey {
    final id = ref.read(authControllerProvider).user?.id;
    return id == null ? null : 'duo-match-tour-done:$id';
  }

  /// Show the tour once per user, after the deck has loaded.
  void _maybeStartTour() {
    if (_tourChecked) return;
    final key = _tourStorageKey;
    if (key == null) return;
    _tourChecked = true;
    try {
      if (ref.read(localStorageProvider).settings.get(key) == true) return;
    } catch (_) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tourOpen = true);
    });
  }

  void _finishTour() {
    setState(() => _tourOpen = false);
    final key = _tourStorageKey;
    if (key == null) return;
    try {
      ref.read(localStorageProvider).settings.put(key, true);
    } catch (_) {}
  }

  List<MatchTourStep> get _tourSteps => [
        MatchTourStep(
          target: _cardKey,
          icon: Icons.swipe_rounded,
          title: 'Discover people',
          body: 'This is a profile card. Swipe right to like or swipe left to skip. '
              'Tap the photo to see more pictures.',
        ),
        MatchTourStep(
          target: _skipKey,
          icon: Icons.close_rounded,
          title: 'Skip',
          body: 'Not interested? Tap the cross to pass on this profile and see the next one.',
        ),
        MatchTourStep(
          target: _likeKey,
          icon: Icons.favorite_rounded,
          title: 'Like',
          body: "Tap the heart to like someone. If they like you back, it's a match and you can start chatting.",
        ),
        MatchTourStep(
          target: _rewindKey,
          icon: Icons.replay_rounded,
          title: 'Rewind',
          body: 'Skipped someone by mistake? Rewind brings back your last swipe. This is a premium feature.',
        ),
        MatchTourStep(
          target: _infoKey,
          icon: Icons.keyboard_arrow_up_rounded,
          title: 'View profile',
          body: 'Swipe the card up or tap this arrow to open the full profile with bio, interests and more details.',
        ),
        MatchTourStep(
          target: _filtersKey,
          icon: Icons.tune_rounded,
          title: 'Filters',
          body: 'Set age, distance, religion and other preferences to choose who appears in your deck.',
        ),
        MatchTourStep(
          target: _menuKey,
          icon: Icons.help_outline_rounded,
          title: 'Replay anytime',
          body: 'Tap the question mark next to your photo whenever you want to see this guide again.',
        ),
      ];

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openFilters() async {
    if (ref.read(matchDeckControllerProvider).controlsDisabled) return;
    // Capture the (kept-alive) controller up front: `ref` is unusable if this
    // screen is disposed while the sheet is open.
    final deck = _deck;
    deck.setFiltersOpen(true);
    final before = ref.read(authControllerProvider).user?.profile;
    try {
      await showDiscoveryFiltersSheet(context, ref);
    } catch (e, st) {
      debugPrint('[Match] filters sheet failed: $e $st');
    } finally {
      // Always unlock, or the deck stays disabled (no swipes/buttons).
      deck.setFiltersOpen(false);
    }
    if (!mounted) return;
    final after = ref.read(authControllerProvider).user?.profile;
    if (!identical(before, after)) {
      final found = ref.read(matchDeckControllerProvider).profiles.isNotEmpty;
      _snack(found ? 'Filters updated' : 'Filters updated. No one matches yet.');
    }
  }

  void _openMenu() {
    if (ref.read(matchDeckControllerProvider).controlsDisabled) return;
    showMatchMenuSheet(context, onOpenFilters: _openFilters);
  }

  void _openLikesPaywall() {
    showPremiumUpgradeSheet(
      context,
      variant: PremiumSheetVariant.unlimitedLikes,
      count: 0,
      onPurchased: () {
        _deck.refreshLikeQuota();
        _snack('Unlimited likes unlocked. Like away!');
      },
    );
  }

  void _openRewindPaywall() {
    showPremiumUpgradeSheet(
      context,
      variant: PremiumSheetVariant.rewind,
      count: 0,
      onPurchased: () {
        _deck.markRewindUnlocked();
        _snack('Rewind unlocked. Bringing back your last swipe…');
        _rewind();
      },
    );
  }

  Future<void> _rewind() async {
    final outcome = await _deck.rewind();
    if (!mounted) return;
    switch (outcome) {
      case RewindNeedsPass():
        _openRewindPaywall();
      case RewindFailed(:final message):
        _snack(message);
      case RewindDone():
        break;
    }
  }

  Future<void> _widen() async {
    try {
      await _deck.widenSearch();
    } catch (_) {
      if (mounted) _snack('Could not update your search. Please try again.');
    }
  }

  /// Returns false when the swipe should not happen (out of free Likes).
  bool _onSwipe(SwipeDirection direction, DuoProfile profile) {
    final deck = ref.read(matchDeckControllerProvider);
    if (deck.controlsDisabled) return false;
    final action = direction == SwipeDirection.right ? SwipeAction.like : SwipeAction.skip;
    if (action == SwipeAction.like && deck.likesExhausted) {
      _openLikesPaywall();
      return false;
    }
    _handleSwipe(profile, action);
    return true;
  }

  Future<void> _handleSwipe(DuoProfile profile, SwipeAction action) async {
    try {
      final result = await _deck.swipeProfile(profile: profile, action: action);
      if (!mounted) return;
      if (result?.isMatch == true && result?.match != null) {
        context.push(AppRoutes.matchCelebration, extra: result!.match);
      }
    } on LikeLimitException catch (e) {
      if (!mounted) return;
      _snack(e.message);
      _openLikesPaywall();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _openDetail(DuoProfile profile) {
    final deck = _deck;
    deck.setDetailOpen(true);
    try {
      showMatchProfileDetail(context, profile: profile).whenComplete(() => deck.setDetailOpen(false));
    } catch (_) {
      deck.setDetailOpen(false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(matchDeckControllerProvider);
    final profile = ref.watch(authControllerProvider).user?.profile;
    final filters = profile != null ? DiscoveryFilters.fromProfile(profile) : DiscoveryFilters.defaults;
    final activeFilterCount = filters.activeCount;
    final rewindLocked = deck.rewindUnlocked == false;

    if (!deck.loading) _maybeStartTour();

    final Widget body;
    if (deck.loading) {
      body = const MatchSkeleton();
    } else if (deck.currentProfile == null && deck.loadError != null) {
      body = DuoStateView.error(
        deck.loadError!,
        title: "Couldn't load profiles",
        onRetry: () => _deck.loadProfiles(refresh: true),
      );
    } else if (deck.currentProfile == null) {
      final canWiden = !filters.prefExpandDistance || !filters.prefExpandAge;
      body = MatchEmptyState(
        filtered: activeFilterCount > 0 || canWiden,
        canWiden: canWiden,
        activeFilterCount: activeFilterCount,
        widening: deck.widening,
        refreshing: deck.refreshing,
        onWiden: _widen,
        onRefresh: () => _deck.loadProfiles(refresh: true, clearSwiped: true),
        onAdjustFilters: _openFilters,
        showRewind: deck.swipeHistoryCount > 0,
        rewindLocked: rewindLocked,
        rewinding: deck.rewinding,
        onRewind: () => rewindLocked ? _openRewindPaywall() : _rewind(),
      );
    } else {
      if (_stackKeyVersion != deck.stackKey) {
        _stackKeyVersion = deck.stackKey;
        _stackKey = GlobalKey<SwipeableCardStackState>();
        _cardKey = GlobalKey();
      }
      // Bottom → top: last entry is the front card (current profile).
      final displayDeck = deck.deckProfiles.reversed.toList();
      body = Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: KeyedSubtree(
                key: _cardKey,
                child: SwipeableCardStack(
                  // Remount only on explicit refresh/filter/rewind — not every swipe.
                  key: _stackKey,
                  profiles: displayDeck,
                  disabled: deck.controlsDisabled,
                  overlayBuilder: (p, isTop) => MatchCardOverlay(
                    profile: p,
                    isTopCard: isTop,
                    infoDisabled: deck.controlsDisabled,
                    infoKey: isTop ? _infoKey : null,
                    onInfoTap: isTop ? () => _openDetail(p) : null,
                  ),
                  onSwipe: _onSwipe,
                  onSwipeUp: (p) {
                    if (!deck.controlsDisabled) _openDetail(p);
                  },
                ),
              ),
            ),
            MatchActionBar(
              disabled: deck.controlsDisabled,
              skipKey: _skipKey,
              rewindKey: _rewindKey,
              likeKey: _likeKey,
              onSkip: () => _stackKey.currentState?.swipeTop(SwipeDirection.left),
              onLike: () {
                if (ref.read(matchDeckControllerProvider).likesExhausted) {
                  _openLikesPaywall();
                  return;
                }
                _stackKey.currentState?.swipeTop(SwipeDirection.right);
              },
              onRewind: () => rewindLocked ? _openRewindPaywall() : _rewind(),
              rewindDisabled: deck.swipeHistoryCount == 0,
              rewindLocked: rewindLocked,
              rewinding: deck.rewinding,
            ),
            const SizedBox(height: 88),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _TopBar(
                  menuKey: _menuKey,
                  filtersKey: _filtersKey,
                  disabled: deck.controlsDisabled,
                  activeFilterCount: activeFilterCount,
                  onOpenMenu: _openMenu,
                  onOpenFilters: _openFilters,
                  onHelp: () => setState(() => _tourOpen = true),
                ),
                Expanded(
                  child: KeyedSubtree(key: ValueKey('deck-${deck.stackKey}'), child: body),
                ),
              ],
            ),
          ),
          if (_tourOpen) Positioned.fill(child: MatchTourOverlay(steps: _tourSteps, onFinish: _finishTour)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.menuKey,
    required this.filtersKey,
    required this.disabled,
    required this.activeFilterCount,
    required this.onOpenMenu,
    required this.onOpenFilters,
    required this.onHelp,
  });

  final Key menuKey;
  final Key filtersKey;
  final bool disabled;
  final int activeFilterCount;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenFilters;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const DuoProfileAvatarButton(),
          const SizedBox(width: 10),
          // Help sits right of the profile picture; keyed for the tour.
          KeyedSubtree(key: menuKey, child: MatchHelpButton(onPressed: onHelp)),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleButton(
                key: filtersKey,
                icon: Icons.tune_rounded,
                tooltip: activeFilterCount > 0
                    ? 'Open discovery filters, $activeFilterCount active'
                    : 'Open discovery filters',
                disabled: disabled,
                onTap: onOpenFilters,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: context.duo.brandGradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$activeFilterCount',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: CircleBorder(side: BorderSide(color: scheme.primary.withValues(alpha: 0.2))),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: disabled ? null : onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: scheme.primary)),
          ),
        ),
      ),
    );
  }
}
