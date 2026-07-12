import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/match_models.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/discover_models.dart';

final discoverDataProvider = FutureProvider.autoDispose<DiscoverData>((ref) async {
  final matching = ref.read(matchingRepositoryProvider);
  final results = await Future.wait([
    matching.getProfileVisitors(),
    matching.getLikedByYou(),
    matching.getLikesYou(),
  ]);
  return DiscoverData(
    visitors: results[0] as PaywalledList<VisitedProfileEntry>,
    sent: results[1] as List<LikedProfileEntry>,
    received: results[2] as PaywalledList<LikedProfileEntry>,
  );
});

final discoverTabProvider = StateProvider<DiscoverTab>((ref) => DiscoverTab.visitors);

final discoverSearchProvider = StateProvider<String>((ref) => '');

final discoverLikingBackProvider = StateProvider<Set<int>>((ref) => {});

final discoverRemovedLikesProvider = StateProvider<Set<int>>((ref) => {});
