import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/matching_repository.dart';
import '../domain/discover_models.dart';

const _discoverTtl = Duration(minutes: 5);

class _DiscoverMemoryCache {
  DiscoverData? data;
  DateTime? cachedAt;
}

final _discoverMemoryCacheProvider = Provider<_DiscoverMemoryCache>((ref) {
  return _DiscoverMemoryCache();
});

final discoverDataProvider = FutureProvider.autoDispose<DiscoverData>((ref) async {
  final memory = ref.read(_discoverMemoryCacheProvider);
  final matching = ref.read(matchingRepositoryProvider);
  final now = DateTime.now();

  if (memory.data != null &&
      memory.cachedAt != null &&
      now.difference(memory.cachedAt!) < _discoverTtl) {
    unawaited(_refreshDiscoverInBackground(matching, memory));
    return memory.data!;
  }

  final fresh = await _fetchDiscover(matching);
  memory.data = fresh;
  memory.cachedAt = now;
  return fresh;
});

Future<void> _refreshDiscoverInBackground(
  MatchingRepository matching,
  _DiscoverMemoryCache memory,
) async {
  try {
    final fresh = await _fetchDiscover(matching);
    memory.data = fresh;
    memory.cachedAt = DateTime.now();
  } catch (_) {}
}

Future<DiscoverData> _fetchDiscover(MatchingRepository matching) async {
  final results = await Future.wait<Object?>([
    matching.getProfileVisitors(),
    matching.getLikedByYou(),
    matching.getLikesYou(),
  ]);
  return DiscoverData(
    visitors: results[0] as PaywalledList<VisitedProfileEntry>,
    sent: results[1] as List<LikedProfileEntry>,
    received: results[2] as PaywalledList<LikedProfileEntry>,
  );
}

final discoverTabProvider = StateProvider<DiscoverTab>((ref) => DiscoverTab.visitors);

final discoverSearchProvider = StateProvider<String>((ref) => '');

final discoverLikingBackProvider = StateProvider<Set<int>>((ref) => {});

final discoverRemovedLikesProvider = StateProvider<Set<int>>((ref) => {});

final discoverUnlikingProvider = StateProvider<Set<int>>((ref) => {});

final discoverRemovedSentProvider = StateProvider<Set<int>>((ref) => {});
