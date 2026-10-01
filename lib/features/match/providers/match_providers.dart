import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_models.dart';
import '../../../core/models/user_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/auth_controller.dart';
import '../../../repositories/matching_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../domain/match_domain.dart';
import '../services/match_location_service.dart';

final matchLocationServiceProvider = Provider<MatchLocationService>((ref) {
  return MatchLocationService();
});

/// How many of this session's swipes Rewind can bring back (matches web).
const _rewindHistoryLimit = 20;

class MatchDeckState {
  const MatchDeckState({
    this.profiles = const [],
    this.loading = true,
    this.refreshing = false,
    this.stackKey = 0,
    this.detailOpen = false,
    this.filtersOpen = false,
    this.locationSynced = false,
    this.loadError,
    this.likeQuota,
    this.rewindUnlocked,
    this.swipeHistoryCount = 0,
    this.rewinding = false,
    this.widening = false,
  });

  final List<DuoProfile> profiles;
  final bool loading;
  final bool refreshing;
  final int stackKey;
  final bool detailOpen;
  final bool filtersOpen;
  final bool locationSynced;

  /// Set when the last discover fetch failed and the deck is empty, so the UI
  /// can show an error + Retry instead of the misleading "no more profiles".
  final Object? loadError;

  /// Free-tier Like allowance; null until loaded.
  final LikeQuota? likeQuota;

  /// Whether the viewer has an active Rewind pass; null until known.
  final bool? rewindUnlocked;
  final int swipeHistoryCount;
  final bool rewinding;
  final bool widening;

  DuoProfile? get currentProfile => profiles.isEmpty ? null : profiles.first;

  List<DuoProfile> get deckProfiles =>
      profiles.length <= 4 ? profiles : profiles.sublist(0, 4);

  /// Sheets/detail block controls — do not lock the deck while a swipe API runs.
  bool get controlsDisabled => detailOpen || filtersOpen;

  bool get likesExhausted => likeQuota?.exhausted ?? false;

  MatchDeckState copyWith({
    List<DuoProfile>? profiles,
    bool? loading,
    bool? refreshing,
    int? stackKey,
    bool? detailOpen,
    bool? filtersOpen,
    bool? locationSynced,
    Object? loadError,
    bool clearLoadError = false,
    LikeQuota? likeQuota,
    bool? rewindUnlocked,
    int? swipeHistoryCount,
    bool? rewinding,
    bool? widening,
  }) {
    return MatchDeckState(
      profiles: profiles ?? this.profiles,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      stackKey: stackKey ?? this.stackKey,
      detailOpen: detailOpen ?? this.detailOpen,
      filtersOpen: filtersOpen ?? this.filtersOpen,
      locationSynced: locationSynced ?? this.locationSynced,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      likeQuota: likeQuota ?? this.likeQuota,
      rewindUnlocked: rewindUnlocked ?? this.rewindUnlocked,
      swipeHistoryCount: swipeHistoryCount ?? this.swipeHistoryCount,
      rewinding: rewinding ?? this.rewinding,
      widening: widening ?? this.widening,
    );
  }
}

/// Outcome of [MatchDeckController.rewind].
sealed class RewindOutcome {
  const RewindOutcome();
}

class RewindDone extends RewindOutcome {
  const RewindDone();
}

/// The viewer needs a Rewind pass; show the paywall.
class RewindNeedsPass extends RewindOutcome {
  const RewindNeedsPass();
}

class RewindFailed extends RewindOutcome {
  const RewindFailed(this.message);
  final String message;
}

class MatchDeckController extends StateNotifier<MatchDeckState> {
  MatchDeckController(this._ref) : super(const MatchDeckState());

  final Ref _ref;
  final Set<int> _swipedUserIds = {};
  final Set<int> _inFlightSwipeIds = {};

  /// This session's swipes, newest last — what Rewind can bring back.
  final List<(int, DuoProfile)> _history = [];

  /// In-flight swipe requests, so a rewind never races the swipe it undoes.
  final Map<int, Future<void>> _pendingSwipes = {};
  bool _refilling = false;
  Timer? _quotaTimer;

  ProfileRepository get _profiles => _ref.read(profileRepositoryProvider);
  MatchingRepository get _matching => _ref.read(matchingRepositoryProvider);

  @override
  void dispose() {
    _quotaTimer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    unawaited(refreshLikeQuota());
    unawaited(refreshRewindStatus());
    if (!state.loading && state.profiles.isNotEmpty) return;
    await loadProfiles();
    await _syncDefaultLocation();
  }

  Future<void> refreshLikeQuota() async {
    try {
      final quota = await _matching.getLikeQuota();
      if (mounted) _setQuota(quota);
    } catch (_) {
      // Quota is advisory; the server still enforces it on swipe.
    }
  }

  Future<void> refreshRewindStatus() async {
    try {
      final status = await _ref.read(walletRepositoryProvider).getSubscriptionStatus();
      final features = status['features'];
      final rewind = features is Map ? features['rewind'] : null;
      final active = rewind is Map && rewind['is_active'] == true;
      if (mounted) state = state.copyWith(rewindUnlocked: active);
    } catch (_) {
      if (mounted) state = state.copyWith(rewindUnlocked: false);
    }
  }

  /// Store the quota and re-check it once the oldest counted Like expires.
  void _setQuota(LikeQuota quota) {
    state = state.copyWith(likeQuota: quota);
    _quotaTimer?.cancel();
    final reset = quota.resetAt;
    if (quota.unlimited || reset == null) return;
    final wait = reset.difference(DateTime.now());
    if (wait.isNegative || wait > const Duration(hours: 24)) return;
    _quotaTimer = Timer(wait + const Duration(seconds: 1), refreshLikeQuota);
  }

  Future<void> loadProfiles({bool refresh = false, bool clearSwiped = false}) async {
    if (refresh) {
      state = state.copyWith(refreshing: true);
    } else {
      state = state.copyWith(loading: true);
    }

    if (clearSwiped) {
      _swipedUserIds.clear();
    }

    try {
      final profiles = await _profiles.discoverProfiles();
      if (!mounted) return;
      state = state.copyWith(
        profiles: _filterAndDedupe(profiles),
        loading: false,
        refreshing: false,
        clearLoadError: true,
      );
    } catch (e) {
      if (!mounted) return;
      // Keep whatever cards are still on screen; only an empty deck shows the error.
      state = state.copyWith(
        loading: false,
        refreshing: false,
        loadError: e,
      );
    }
  }

  List<DuoProfile> _filterAndDedupe(List<DuoProfile> profiles) {
    final seen = <int>{};
    final filtered = <DuoProfile>[];
    for (final profile in profiles) {
      final id = profile.resolvedUserId;
      if (id != null) {
        if (_swipedUserIds.contains(id) || seen.contains(id)) continue;
        seen.add(id);
      }
      filtered.add(profile);
    }
    return filtered;
  }

  Future<void> _syncDefaultLocation() async {
    if (state.locationSynced) return;
    final user = _ref.read(authControllerProvider).user;
    final location = user?.profile.location;
    if (!isDefaultLocation(location)) {
      state = state.copyWith(locationSynced: true);
      return;
    }

    state = state.copyWith(locationSynced: true);
    try {
      final detected = await _ref.read(matchLocationServiceProvider).detectUserLocation();
      await _profiles.updateProfile({'location': detected.label});
      await _ref.read(authControllerProvider.notifier).refreshUser();
    } catch (_) {
      if (mounted) state = state.copyWith(locationSynced: false);
    }
  }

  void setDetailOpen(bool open) {
    state = state.copyWith(detailOpen: open);
  }

  void setFiltersOpen(bool open) {
    state = state.copyWith(filtersOpen: open);
  }

  Future<void> _applyFilterPayload(Map<String, dynamic> payload) async {
    await _profiles.updateProfile(payload);
    await _ref.read(authControllerProvider.notifier).refreshUser();
    if (!mounted) return;
    state = state.copyWith(stackKey: state.stackKey + 1);
    await loadProfiles(refresh: true, clearSwiped: true);
  }

  Future<void> applyFilters(DiscoveryFilters filters) => _applyFilterPayload(filters.toApiPayload());

  /// Preferences were saved elsewhere (Match preferences screen): rebuild the
  /// deck so the new filters apply right away.
  Future<void> reloadForNewPreferences() async {
    if (!mounted) return;
    state = state.copyWith(stackKey: state.stackKey + 1);
    await loadProfiles(refresh: true, clearSwiped: true);
  }

  /// "Widen my search": let the server expand distance and age when empty.
  Future<void> widenSearch() async {
    state = state.copyWith(widening: true);
    try {
      await _applyFilterPayload({'pref_expand_distance': true, 'pref_expand_age': true});
    } finally {
      if (mounted) state = state.copyWith(widening: false);
    }
  }

  void _pushHistory(int userId, DuoProfile profile) {
    _history
      ..removeWhere((e) => e.$1 == userId)
      ..add((userId, profile));
    if (_history.length > _rewindHistoryLimit) _history.removeAt(0);
    state = state.copyWith(swipeHistoryCount: _history.length);
  }

  void _dropHistory(int userId) {
    _history.removeWhere((e) => e.$1 == userId);
    if (mounted) state = state.copyWith(swipeHistoryCount: _history.length);
  }

  Future<SwipeResult?> swipeProfile({
    required DuoProfile profile,
    required SwipeAction action,
  }) async {
    final userId = profile.resolvedUserId;
    if (userId == null) {
      _removeProfile(profile);
      await _refillIfNeeded();
      return null;
    }

    if (_inFlightSwipeIds.contains(userId) || _swipedUserIds.contains(userId)) {
      _removeProfile(profile);
      return null;
    }

    _inFlightSwipeIds.add(userId);
    _swipedUserIds.add(userId);
    _pushHistory(userId, profile);
    _removeProfile(profile);

    final done = Completer<void>();
    _pendingSwipes[userId] = done.future;
    try {
      final (result, quota) = await _matching.swipe(toUserId: userId, action: action);
      if (quota != null && mounted) _setQuota(quota);
      if (result.isMatch) _dropHistory(userId); // A match can't be rewound.
      await _refillIfNeeded();
      return result;
    } on LikeLimitException catch (e) {
      _swipedUserIds.remove(userId);
      _dropHistory(userId);
      if (!mounted) rethrow;
      if (e.quota != null) _setQuota(e.quota!);
      _restoreToFront(profile, userId);
      rethrow;
    } catch (_) {
      _swipedUserIds.remove(userId);
      _dropHistory(userId);
      if (!mounted) rethrow;
      _restoreToFront(profile, userId);
      rethrow;
    } finally {
      _inFlightSwipeIds.remove(userId);
      _pendingSwipes.remove(userId);
      done.complete();
    }
  }

  void _restoreToFront(DuoProfile profile, int userId) {
    final current = state.profiles;
    final restored = current.any((p) => p.resolvedUserId == userId) ? current : [profile, ...current];
    state = state.copyWith(profiles: restored, stackKey: state.stackKey + 1, clearLoadError: true);
  }

  /// Bring back the last swiped profile (premium). Mirrors web error handling.
  Future<RewindOutcome> rewind() async {
    if (_history.isEmpty || state.rewinding) return const RewindFailed('Nothing to rewind.');
    if (state.rewindUnlocked == false) return const RewindNeedsPass();
    final (userId, profile) = _history.last;
    state = state.copyWith(rewinding: true);
    try {
      await _pendingSwipes[userId];
      final restored = await _matching.rewind(toUserId: userId) ?? profile;
      if (!mounted) return const RewindDone();
      _history.removeLast();
      _swipedUserIds.remove(userId);
      state = state.copyWith(
        profiles: [restored, ...state.profiles.where((p) => p.resolvedUserId != userId)],
        stackKey: state.stackKey + 1,
        swipeHistoryCount: _history.length,
        clearLoadError: true,
      );
      return const RewindDone();
    } catch (e) {
      final message = e is ApiException ? e.message : 'Could not rewind. Please try again.';
      if (RegExp('premium|rewind pass', caseSensitive: false).hasMatch(message)) {
        if (mounted) state = state.copyWith(rewindUnlocked: false);
        return const RewindNeedsPass();
      }
      if (RegExp('no swipe|already matched', caseSensitive: false).hasMatch(message)) {
        _dropHistory(userId);
      }
      return RewindFailed(message);
    } finally {
      if (mounted) state = state.copyWith(rewinding: false);
    }
  }

  /// Called after buying a Rewind pass.
  void markRewindUnlocked() => state = state.copyWith(rewindUnlocked: true);

  /// Auto-refill when the deck runs out — never clear session swipes, or
  /// recycled discover results will immediately show the same people again.
  Future<void> _refillIfNeeded() async {
    if (state.profiles.isNotEmpty || _refilling) return;
    _refilling = true;
    try {
      await loadProfiles(refresh: true, clearSwiped: false);
    } finally {
      _refilling = false;
    }
  }

  void _removeProfile(DuoProfile profile) {
    final id = profile.resolvedUserId;
    state = state.copyWith(
      profiles: state.profiles
          .where((p) {
            if (id != null) return p.resolvedUserId != id;
            return !identical(p, profile);
          })
          .toList(growable: false),
    );
  }
}

final matchDeckControllerProvider =
    StateNotifierProvider.autoDispose<MatchDeckController, MatchDeckState>((ref) {
  ref.keepAlive();
  final controller = MatchDeckController(ref);
  controller.initialize();
  return controller;
});
