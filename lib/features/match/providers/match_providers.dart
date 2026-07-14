import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_models.dart';
import '../../../core/models/user_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/auth_controller.dart';
import '../../../repositories/matching_repository.dart';
import '../../../repositories/profile_repository.dart';
import '../domain/match_domain.dart';
import '../services/match_location_service.dart';

final matchLocationServiceProvider = Provider<MatchLocationService>((ref) {
  return MatchLocationService();
});

class MatchDeckState {
  const MatchDeckState({
    this.profiles = const [],
    this.loading = true,
    this.refreshing = false,
    this.stackKey = 0,
    this.detailOpen = false,
    this.filtersOpen = false,
    this.locationSynced = false,
  });

  final List<DuoProfile> profiles;
  final bool loading;
  final bool refreshing;
  final int stackKey;
  final bool detailOpen;
  final bool filtersOpen;
  final bool locationSynced;

  DuoProfile? get currentProfile => profiles.isEmpty ? null : profiles.first;

  List<DuoProfile> get deckProfiles =>
      profiles.length <= 4 ? profiles : profiles.sublist(0, 4);

  /// Sheets/detail block controls — do not lock the deck while a swipe API runs.
  bool get controlsDisabled => detailOpen || filtersOpen;

  MatchDeckState copyWith({
    List<DuoProfile>? profiles,
    bool? loading,
    bool? refreshing,
    int? stackKey,
    bool? detailOpen,
    bool? filtersOpen,
    bool? locationSynced,
  }) {
    return MatchDeckState(
      profiles: profiles ?? this.profiles,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      stackKey: stackKey ?? this.stackKey,
      detailOpen: detailOpen ?? this.detailOpen,
      filtersOpen: filtersOpen ?? this.filtersOpen,
      locationSynced: locationSynced ?? this.locationSynced,
    );
  }
}

class MatchDeckController extends StateNotifier<MatchDeckState> {
  MatchDeckController(this._ref) : super(const MatchDeckState());

  final Ref _ref;
  final Set<int> _swipedUserIds = {};
  final Set<int> _inFlightSwipeIds = {};

  ProfileRepository get _profiles => _ref.read(profileRepositoryProvider);
  MatchingRepository get _matching => _ref.read(matchingRepositoryProvider);

  Future<void> initialize() async {
    if (!state.loading && state.profiles.isNotEmpty) return;
    await loadProfiles();
    await _syncDefaultLocation();
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
      final filtered = profiles
          .where((profile) {
            final id = profile.resolvedUserId;
            return id == null || !_swipedUserIds.contains(id);
          })
          .toList(growable: false);
      state = state.copyWith(
        profiles: filtered,
        loading: false,
        refreshing: false,
      );
    } catch (_) {
      state = state.copyWith(
        profiles: const [],
        loading: false,
        refreshing: false,
      );
    }
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
      state = state.copyWith(locationSynced: false);
    }
  }

  void setDetailOpen(bool open) {
    state = state.copyWith(detailOpen: open);
  }

  void setFiltersOpen(bool open) {
    state = state.copyWith(filtersOpen: open);
  }

  Future<void> applyFilters(DiscoveryFilters filters) async {
    await _profiles.updateProfile(filters.toApiPayload());
    await _ref.read(authControllerProvider.notifier).refreshUser();
    state = state.copyWith(stackKey: state.stackKey + 1);
    await loadProfiles(refresh: true, clearSwiped: true);
  }

  Future<SwipeResult?> swipeProfile({
    required DuoProfile profile,
    required SwipeAction action,
  }) async {
    final userId = profile.resolvedUserId;
    if (userId == null) {
      _removeProfile(profile);
      return null;
    }

    if (_inFlightSwipeIds.contains(userId) || _swipedUserIds.contains(userId)) {
      return null;
    }

    _inFlightSwipeIds.add(userId);
    _swipedUserIds.add(userId);
    _removeProfile(profile);

    try {
      final result = await _matching.swipe(toUserId: userId, action: action);
      if (state.profiles.isEmpty) {
        await loadProfiles(refresh: true, clearSwiped: true);
      }
      return result;
    } catch (_) {
      _swipedUserIds.remove(userId);
      state = state.copyWith(stackKey: state.stackKey + 1);
      await loadProfiles(refresh: true);
      rethrow;
    } finally {
      _inFlightSwipeIds.remove(userId);
    }
  }

  void _removeProfile(DuoProfile profile) {
    final id = profile.resolvedUserId;
    state = state.copyWith(
      profiles: state.profiles
          .where((p) => p.resolvedUserId != id)
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
