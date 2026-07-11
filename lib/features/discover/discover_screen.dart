import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../widgets/profile_swipe_card.dart';

enum DiscoverTab { visitors, sent, received }

final discoverDataProvider = FutureProvider.autoDispose<Map<DiscoverTab, dynamic>>((ref) async {
  final matching = ref.read(matchingRepositoryProvider);
  final results = await Future.wait([
    matching.getProfileVisitors(),
    matching.getLikedByYou(),
    matching.getLikesYou(),
  ]);
  return {
    DiscoverTab.visitors: results[0] as PaywalledList<LikedProfileEntry>,
    DiscoverTab.sent: results[1] as List<LikedProfileEntry>,
    DiscoverTab.received: results[2] as PaywalledList<LikedProfileEntry>,
  };
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  DiscoverTab _tab = DiscoverTab.visitors;

  Future<void> _likeBack(LikedProfileEntry entry) async {
    final userId = entry.profile.userId;
    if (userId == null) return;
    try {
      final result = await ref.read(matchingRepositoryProvider).swipe(
            toUserId: userId,
            action: SwipeAction.like,
          );
      ref.invalidate(discoverDataProvider);
      if (result.isMatch && result.match != null && mounted) {
        context.push(AppRoutes.matchCelebration, extra: result.match);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(discoverDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push(AppRoutes.wallet),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(discoverDataProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<DiscoverTab>(
              segments: const [
                ButtonSegment(value: DiscoverTab.visitors, label: Text('Visited')),
                ButtonSegment(value: DiscoverTab.sent, label: Text('Sent')),
                ButtonSegment(value: DiscoverTab.received, label: Text('Liked you')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (map) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(discoverDataProvider),
                child: _buildList(map),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Map<DiscoverTab, dynamic> map) {
    switch (_tab) {
      case DiscoverTab.visitors:
        final list = map[DiscoverTab.visitors] as PaywalledList<LikedProfileEntry>;
        return _paywalledGrid(list, premiumHint: 'See who viewed your profile');
      case DiscoverTab.sent:
        final list = map[DiscoverTab.sent] as List<LikedProfileEntry>;
        return _simpleGrid(list);
      case DiscoverTab.received:
        final list = map[DiscoverTab.received] as PaywalledList<LikedProfileEntry>;
        return _paywalledGrid(
          list,
          premiumHint: 'See who liked you',
          onLikeBack: _likeBack,
        );
    }
  }

  Widget _paywalledGrid(
    PaywalledList<LikedProfileEntry> list, {
    required String premiumHint,
    Future<void> Function(LikedProfileEntry)? onLikeBack,
  }) {
    if (list.results.isEmpty) {
      return ListView(
        children: const [SizedBox(height: 120), Center(child: Text('Nothing here yet'))],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (list.premiumRequired && !list.isPremium)
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: Text(premiumHint),
              subtitle: const Text('Unlock with Duo Premium'),
              trailing: FilledButton(
                onPressed: () => context.push(AppRoutes.wallet),
                child: const Text('Wallet'),
              ),
            ),
          ),
        ...list.results.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 320,
              child: Stack(
                children: [
                  ProfileSwipeCard(profile: entry.profile, locked: entry.locked),
                  if (onLikeBack != null && !entry.locked)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FilledButton(
                        onPressed: () => onLikeBack(entry),
                        child: const Text('Like back'),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _simpleGrid(List<LikedProfileEntry> list) {
    if (list.isEmpty) {
      return ListView(
        children: const [SizedBox(height: 120), Center(child: Text('Nothing here yet'))],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 320,
            child: ProfileSwipeCard(profile: list[i].profile),
          ),
        );
      },
    );
  }
}
