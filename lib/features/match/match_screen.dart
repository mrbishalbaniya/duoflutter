import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_models.dart';
import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../widgets/profile_swipe_card.dart';

final discoverDeckProvider = FutureProvider.autoDispose<List<DuoProfile>>((ref) async {
  return ref.read(profileRepositoryProvider).discoverProfiles();
});

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(discoverDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(discoverDeckProvider),
          ),
        ],
      ),
      body: deck.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profiles) {
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64),
                  const SizedBox(height: 16),
                  Text('No more profiles right now', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref.invalidate(discoverDeckProvider),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          return _SwipeDeck(profiles: profiles);
        },
      ),
    );
  }
}

class _SwipeDeck extends ConsumerStatefulWidget {
  const _SwipeDeck({required this.profiles});

  final List<DuoProfile> profiles;

  @override
  ConsumerState<_SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends ConsumerState<_SwipeDeck> {
  late List<DuoProfile> _profiles;
  Offset _drag = Offset.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _profiles = List.of(widget.profiles);
  }

  Future<void> _swipe(SwipeAction action) async {
    if (_profiles.isEmpty || _busy) return;
    final profile = _profiles.first;
    final userId = profile.userId;
    if (userId == null) {
      setState(() => _profiles.removeAt(0));
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await ref.read(matchingRepositoryProvider).swipe(
            toUserId: userId,
            action: action,
          );
      setState(() {
        _profiles.removeAt(0);
        _drag = Offset.zero;
      });
      if (result.isMatch && result.match != null && mounted) {
        context.push(AppRoutes.matchCelebration, extra: result.match);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profiles.isEmpty) {
      return const Center(child: Text('You reached the end of the deck'));
    }

    final profile = _profiles.first;
    final rotation = (_drag.dx / 300).clamp(-0.15, 0.15);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanUpdate: (d) => setState(() => _drag += d.delta),
              onPanEnd: (d) {
                if (_drag.dx > 120) {
                  _swipe(SwipeAction.like);
                } else if (_drag.dx < -120) {
                  _swipe(SwipeAction.skip);
                } else {
                  setState(() => _drag = Offset.zero);
                }
              },
              child: Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  angle: rotation,
                  child: ProfileSwipeCard(profile: profile),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: Colors.grey.shade700,
                onTap: _busy ? null : () => _swipe(SwipeAction.skip),
              ),
              _ActionButton(
                icon: Icons.favorite,
                color: const Color(0xFFE84A7A),
                size: 64,
                onTap: _busy ? null : () => _swipe(SwipeAction.like),
              ),
              _ActionButton(
                icon: Icons.star,
                color: const Color(0xFF8B5CF6),
                onTap: _busy ? null : () => _swipe(SwipeAction.superlike),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}
