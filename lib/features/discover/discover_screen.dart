import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../match/domain/match_domain.dart';
import '../../core/models/match_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../notifications/providers/notifications_providers.dart';
import 'domain/discover_models.dart';
import 'providers/discover_providers.dart';
import 'widgets/discover_empty_state.dart';
import 'widgets/discover_profile_card.dart';
import 'widgets/discover_skeleton.dart';
import 'widgets/discover_tab_bar.dart';
import 'widgets/premium_upgrade_sheet.dart';
import 'widgets/profile_detail_sheet.dart';
import '../../widgets/duo_profile_avatar_button.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(discoverDataProvider);
    final tab = ref.watch(discoverTabProvider);
    final search = ref.watch(discoverSearchProvider);
    final likingBack = ref.watch(discoverLikingBackProvider);
    final removed = ref.watch(discoverRemovedLikesProvider);
    final unliking = ref.watch(discoverUnlikingProvider);
    final removedSent = ref.watch(discoverRemovedSentProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DuoPageHeader(
              leading: const DuoProfileAvatarButton(),
              title: 'Discover',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DuoIconCircleButton(
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push(AppRoutes.wallet),
                  ),
                  const SizedBox(width: 8),
                  _NotificationBell(),
                ],
              ),
            ),
            data.maybeWhen(
              data: (d) => DiscoverTabBar(
                counts: {
                  DiscoverTab.visitors: d.countFor(DiscoverTab.visitors),
                  DiscoverTab.sent: d.countFor(DiscoverTab.sent),
                  DiscoverTab.received: d.countFor(DiscoverTab.received),
                  DiscoverTab.matched: d.countFor(DiscoverTab.matched),
                },
              ),
              orElse: () => const SizedBox(height: 48),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: data.when(
                loading: () => const DiscoverSkeleton(),
                error: (e, _) => DiscoverErrorState(
                  message: e is ApiException ? e.message : '$e',
                  onRetry: () => ref.invalidate(discoverDataProvider),
                ),
                data: (discover) => RefreshIndicator(
                    onRefresh: () async {
                    ref.invalidate(discoverDataProvider);
                    ref.read(discoverRemovedLikesProvider.notifier).state = {};
                    ref.read(discoverRemovedSentProvider.notifier).state = {};
                  },
                  child: _DiscoverFeed(
                    data: discover,
                    tab: tab,
                    search: search,
                    likingBack: likingBack,
                    removed: removed,
                    unliking: unliking,
                    removedSent: removedSent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverFeed extends ConsumerWidget {
  const _DiscoverFeed({
    required this.data,
    required this.tab,
    required this.search,
    required this.likingBack,
    required this.removed,
    required this.unliking,
    required this.removedSent,
  });

  final DiscoverData data;
  final DiscoverTab tab;
  final String search;
  final Set<int> likingBack;
  final Set<int> removed;
  final Set<int> unliking;
  final Set<int> removedSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (tab) {
      DiscoverTab.visitors => _VisitorsGrid(
        list: data.visitors,
        search: search,
      ),
      DiscoverTab.sent => _SentGrid(
        entries: filterLiked(data.sent, search)
            .where((entry) {
              final userId = entry.profile.userId;
              return userId == null || !removedSent.contains(userId);
            })
            .toList(),
        unliking: unliking,
      ),
      DiscoverTab.received => _ReceivedGrid(
        list: data.received,
        search: search,
        likingBack: likingBack,
        removed: removed,
      ),
      DiscoverTab.matched => _MatchedGrid(matches: data.matches),
    };
  }
}

class _MatchedGrid extends ConsumerWidget {
  const _MatchedGrid({required this.matches});

  final List<MatchSession> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) return DiscoverEmptyState(tab: DiscoverTab.matched);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _AdaptiveGrid(
          itemCount: matches.length,
          builder: (context, index) {
            final match = matches[index];
            final profile = match.otherUserProfile;
            final label = interactionTimeLabel(kind: 'matched', time: match.matchedAt);
            return DiscoverProfileCard(
              profile: profile,
              timeLabel: label,
              heroTag: 'discover-match-${match.id}',
              animationIndex: index,
              onTap: () => showProfileDetailSheet(context, profile: profile, timeLabel: label),
              primaryAction: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () {
                  final conversationId = match.conversationId;
                  if (conversationId != null && conversationId.isNotEmpty) {
                    context.push('/chat/$conversationId');
                  } else {
                    context.go(AppRoutes.chat);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                label: const Text('Chat', style: TextStyle(fontSize: 11)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VisitorsGrid extends ConsumerWidget {
  const _VisitorsGrid({required this.list, required this.search});

  final PaywalledList<VisitedProfileEntry> list;
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = filterVisitors(list.results, search);
    if (items.isEmpty) return DiscoverEmptyState(tab: DiscoverTab.visitors);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (list.premiumRequired && !list.isPremium)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DuoPremiumBanner(
              title: 'See who viewed your profile',
              subtitle: '${list.count} visits · Duo Premium',
              onTap: () => showPremiumUpgradeSheet(
                context,
                variant: PremiumSheetVariant.visitors,
                count: list.count,
              ),
            ),
          ),
        _AdaptiveGrid(
          itemCount: items.length,
          builder: (context, index) {
            final entry = items[index];
            final tag = profileHeroTag(entry.profile);
            return DiscoverProfileCard(
              profile: entry.profile,
              timeLabel: interactionTimeLabel(kind: 'visited', time: entry.visitedAt),
              locked: entry.locked,
              // Locked entries have no id and share the name 'Someone', so a
              // Hero tag would collide; they can't open the detail view anyway.
              heroTag: entry.locked ? null : tag,
              animationIndex: index,
              onLockedTap: () => showPremiumUpgradeSheet(
                context,
                variant: PremiumSheetVariant.visitors,
                count: list.count,
              ),
              onTap: entry.locked
                  ? null
                  : () => showProfileDetailSheet(
                        context,
                        profile: entry.profile,
                        timeLabel: interactionTimeLabel(
                          kind: 'visited',
                          time: entry.visitedAt,
                        ),
                      ),
              primaryAction: entry.locked
                  ? null
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => context.go(AppRoutes.match),
                      child: const Text('Like on Match', style: TextStyle(fontSize: 11)),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _SentGrid extends ConsumerWidget {
  const _SentGrid({
    required this.entries,
    required this.unliking,
  });

  final List<LikedProfileEntry> entries;
  final Set<int> unliking;

  Future<void> _unlike(BuildContext context, WidgetRef ref, LikedProfileEntry entry) async {
    final userId = entry.profile.userId;
    if (userId == null) return;

    discoverHaptic();
    ref.read(discoverUnlikingProvider.notifier).state = {...unliking, userId};

    try {
      await ref.read(matchingRepositoryProvider).unlike(toUserId: userId);
      if (!context.mounted) return;
      ref.read(discoverRemovedSentProvider.notifier).state = {
        ...ref.read(discoverRemovedSentProvider),
        userId,
      };
      ref.invalidate(discoverDataProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Like removed.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      // The grid may have been disposed (tab switch) while the request ran.
      if (context.mounted) {
        ref.read(discoverUnlikingProvider.notifier).state = {
          ...ref.read(discoverUnlikingProvider),
        }..remove(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) return const DiscoverEmptyState(tab: DiscoverTab.sent);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _AdaptiveGrid(
          itemCount: entries.length,
          builder: (context, index) {
            final entry = entries[index];
            final tag = profileHeroTag(entry.profile);
            final userId = entry.profile.userId;
            final isUnliking = userId != null && unliking.contains(userId);
            return DiscoverProfileCard(
              profile: entry.profile,
              timeLabel: interactionTimeLabel(
                action: entry.action,
                kind: 'sent',
                time: entry.likedAt,
              ),
              // Locked entries have no id and share the name 'Someone', so a
              // Hero tag would collide; they can't open the detail view anyway.
              heroTag: entry.locked ? null : tag,
              animationIndex: index,
              onTap: () => showProfileDetailSheet(
                context,
                profile: entry.profile,
                timeLabel: interactionTimeLabel(
                  action: entry.action,
                  kind: 'sent',
                  time: entry.likedAt,
                ),
              ),
              primaryAction: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: isUnliking ? null : () => _unlike(context, ref, entry),
                child: Text(
                  isUnliking ? 'Removing…' : 'Unlike',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReceivedGrid extends ConsumerWidget {
  const _ReceivedGrid({
    required this.list,
    required this.search,
    required this.likingBack,
    required this.removed,
  });

  final PaywalledList<LikedProfileEntry> list;
  final String search;
  final Set<int> likingBack;
  final Set<int> removed;

  Future<void> _likeBack(BuildContext context, WidgetRef ref, LikedProfileEntry entry) async {
    final userId = entry.profile.userId;
    if (userId == null) return;

    discoverHaptic();
    ref.read(discoverLikingBackProvider.notifier).state = {...likingBack, userId};

    try {
      final (result, _) = await ref.read(matchingRepositoryProvider).swipe(
            toUserId: userId,
            action: SwipeAction.like,
          );
      if (!context.mounted) return;

      ref.read(discoverRemovedLikesProvider.notifier).state = {...removed, userId};
      ref.invalidate(discoverDataProvider);

      if (context.mounted) {
        if (result.isMatch && result.match != null) {
          context.push(AppRoutes.matchCelebration, extra: result.match);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Like sent!')),
          );
        }
      }
    } on LikeLimitException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (context.mounted) {
        ref.read(discoverLikingBackProvider.notifier).state =
            {...ref.read(discoverLikingBackProvider)}..remove(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = filterLiked(list.results, search)
        .where((e) => !removed.contains(e.profile.userId))
        .toList();

    if (items.isEmpty) return const DiscoverEmptyState(tab: DiscoverTab.received);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (list.premiumRequired && !list.isPremium)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DuoPremiumBanner(
              title: 'See who liked you',
              subtitle: '${list.count} likes · Duo Premium',
              onTap: () => showPremiumUpgradeSheet(
                context,
                variant: PremiumSheetVariant.likes,
                count: list.count,
              ),
            ),
          ),
        _AdaptiveGrid(
          itemCount: items.length,
          builder: (context, index) {
            final entry = items[index];
            final userId = entry.profile.userId;
            final isLiking = userId != null && likingBack.contains(userId);
            final tag = profileHeroTag(entry.profile);

            return DiscoverProfileCard(
              profile: entry.profile,
              timeLabel: interactionTimeLabel(
                action: entry.action,
                kind: 'received',
                time: entry.likedAt,
              ),
              locked: entry.locked,
              // Locked entries have no id and share the name 'Someone', so a
              // Hero tag would collide; they can't open the detail view anyway.
              heroTag: entry.locked ? null : tag,
              animationIndex: index,
              onLockedTap: () => showPremiumUpgradeSheet(
                context,
                variant: PremiumSheetVariant.likes,
                count: list.count,
              ),
              onTap: entry.locked
                  ? null
                  : () => showProfileDetailSheet(
                        context,
                        profile: entry.profile,
                        timeLabel: interactionTimeLabel(
                          action: entry.action,
                          kind: 'received',
                          time: entry.likedAt,
                        ),
                      ),
              primaryAction: entry.locked || userId == null
                  ? null
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: isLiking ? null : () => _likeBack(context, ref, entry),
                      child: isLiking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Like back', style: TextStyle(fontSize: 11)),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationUnreadCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DuoIconCircleButton(
          icon: Icons.notifications_outlined,
          onTap: () => context.push(AppRoutes.notifications),
        ),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: DuoColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdaptiveGrid extends StatelessWidget {
  const _AdaptiveGrid({required this.itemCount, required this.builder});

  final int itemCount;
  final Widget Function(BuildContext context, int index) builder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : width >= 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: builder,
    );
  }
}
