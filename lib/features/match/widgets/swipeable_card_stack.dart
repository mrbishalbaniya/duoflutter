import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/user_models.dart';
import '../domain/match_domain.dart';
import 'match_card_overlay.dart';

const _swipeAnimationMs = 380;
const _swipeThreshold = 88.0;
const _exitX = 320.0;
const _rotationRange = 22.0;

typedef SwipeCommitCallback = bool Function(SwipeDirection direction, DuoProfile profile);

class SwipeableCardStack extends StatefulWidget {
  const SwipeableCardStack({
    super.key,
    required this.profiles,
    required this.disabled,
    required this.onSwipe,
    this.overlayBuilder,
    this.heroTagBuilder,
  });

  final List<DuoProfile> profiles;
  final bool disabled;
  final SwipeCommitCallback onSwipe;
  final Widget Function(DuoProfile profile, bool isTop)? overlayBuilder;
  final String Function(DuoProfile profile)? heroTagBuilder;

  @override
  SwipeableCardStackState createState() => SwipeableCardStackState();
}

class SwipeableCardStackState extends State<SwipeableCardStack>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  bool _flying = false;
  late AnimationController _flyController;
  Animation<Offset>? _flyAnimation;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _swipeAnimationMs),
    );
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  Future<void> swipeTop(SwipeDirection direction) async {
    if (widget.disabled || _flying || widget.profiles.isEmpty) return;
    await _flyOff(direction);
  }

  Future<void> _flyOff(SwipeDirection direction) async {
    if (_flying || widget.profiles.isEmpty) return;
    setState(() => _flying = true);

    final start = _drag;
    final end = Offset(direction == SwipeDirection.right ? _exitX : -_exitX, _drag.dy);

    _flyAnimation = Tween<Offset>(begin: start, end: end).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic),
    );

    _flyController.reset();
    await _flyController.forward();
    _commit(direction);
  }

  void _commit(SwipeDirection direction) {
    final profile = widget.profiles.last;
    final accepted = widget.onSwipe(direction, profile);
    if (!accepted && mounted) {
      setState(() {
        _drag = Offset.zero;
        _flying = false;
      });
      _flyController.reset();
      return;
    }

    if (mounted) {
      setState(() {
        _drag = Offset.zero;
        _flying = false;
      });
      _flyController.reset();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.disabled || _flying) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldRight = _drag.dx > _swipeThreshold || velocity > 420;
    final shouldLeft = _drag.dx < -_swipeThreshold || velocity < -420;

    if (shouldRight) {
      HapticFeedback.mediumImpact();
      _flyOff(SwipeDirection.right);
    } else if (shouldLeft) {
      HapticFeedback.lightImpact();
      _flyOff(SwipeDirection.left);
    } else {
      setState(() => _drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < widget.profiles.length; i++)
              _buildCard(
                context: context,
                profile: widget.profiles[i],
                index: i,
                total: widget.profiles.length,
                constraints: constraints,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required DuoProfile profile,
    required int index,
    required int total,
    required BoxConstraints constraints,
  }) {
    final isTop = index == total - 1;
    final depth = (total - 1) - index;
    final scale = 1 - depth * 0.05;
    final yOffset = -depth * 14.0;
    final photo = profile.profilePhotos.isNotEmpty
        ? profile.optimizedProfilePhotos.first
        : profile.optimizedDisplayPhoto;
    final heroTag = widget.heroTagBuilder?.call(profile);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.isNotEmpty)
            heroTag != null && isTop
                ? Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover),
                  )
                : CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
          else
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.person, size: 80, color: Colors.white24),
            ),
          widget.overlayBuilder?.call(profile, isTop) ??
              MatchCardOverlay(profile: profile, isTopCard: isTop),
        ],
      ),
    );

    if (!isTop) {
      return Positioned.fill(
        child: Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale,
            child: card,
          ),
        ),
      );
    }

    final rotation = (_drag.dx / 180).clamp(-_rotationRange, _rotationRange) *
        (3.14159 / 180);
    final likeOpacity = (_drag.dx / 120).clamp(0.0, 1.0);
    final skipOpacity = (-_drag.dx / 120).clamp(0.0, 1.0);

    if (_flying && _flyAnimation != null) {
      return AnimatedBuilder(
        animation: _flyAnimation!,
        builder: (context, child) {
          final offset = _flyAnimation!.value;
          final rot = (offset.dx / 180).clamp(-_rotationRange, _rotationRange) *
              (3.14159 / 180);
          return _positionedTopCard(
            offset: offset,
            rotation: rot,
            likeOpacity: likeOpacity,
            skipOpacity: skipOpacity,
            child: child!,
          );
        },
        child: card,
      );
    }

    return GestureDetector(
      onPanUpdate: widget.disabled
          ? null
          : (d) => setState(() => _drag += d.delta),
      onPanEnd: widget.disabled ? null : _onPanEnd,
      child: _positionedTopCard(
        offset: _drag,
        rotation: rotation,
        likeOpacity: likeOpacity,
        skipOpacity: skipOpacity,
        child: card,
      ),
    );
  }

  Widget _positionedTopCard({
    required Offset offset,
    required double rotation,
    required double likeOpacity,
    required double skipOpacity,
    required Widget child,
  }) {
    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            children: [
              if (offset.dx > 14)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.35 * likeOpacity),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              if (offset.dx < -14)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.35 * skipOpacity),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              child,
              if (likeOpacity > 0.08)
                Positioned(
                  top: 36,
                  left: 24,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: _SwipeStamp(label: 'LIKE', color: Colors.green.shade400),
                  ),
                ),
              if (skipOpacity > 0.08)
                Positioned(
                  top: 36,
                  right: 24,
                  child: Opacity(
                    opacity: skipOpacity,
                    child: const _SwipeStamp(label: 'NOPE', color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: label == 'LIKE' ? -0.2 : 0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
