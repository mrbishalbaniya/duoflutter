import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/cloudinary_url.dart';
import '../../../core/media/media_url.dart';
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
    this.onSwipeUp,
  });

  /// Bottom → top order. Last item is the swipeable front card.
  final List<DuoProfile> profiles;
  final bool disabled;
  final SwipeCommitCallback onSwipe;
  final Widget Function(DuoProfile profile, bool isTop)? overlayBuilder;

  /// Swiping the top card upward (opens the full profile).
  final ValueChanged<DuoProfile>? onSwipeUp;

  @override
  SwipeableCardStackState createState() => SwipeableCardStackState();
}

class SwipeableCardStackState extends State<SwipeableCardStack>
    with SingleTickerProviderStateMixin {
  late List<DuoProfile> _cards;
  Offset _drag = Offset.zero;
  String? _photoCardId;
  int _photoIndex = 0;
  bool _flying = false;
  late AnimationController _flyController;
  Animation<Offset>? _flyAnimation;

  @override
  void initState() {
    super.initState();
    _cards = List<DuoProfile>.from(widget.profiles);
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _swipeAnimationMs),
    );
  }

  @override
  void didUpdateWidget(covariant SwipeableCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameDeck(_cards, widget.profiles)) return;
    // Mid-swipe: only ignore the update if it's just the parent catching up on
    // this same swipe (new deck == ours minus the flying top card). A genuinely
    // different deck (filters / refresh) replaces it and cancels the fling.
    if (_flying && _cards.isNotEmpty &&
        _sameDeck(_cards.sublist(0, _cards.length - 1), widget.profiles)) {
      return;
    }
    _flyController.stop();
    setState(() {
      _cards = List<DuoProfile>.from(widget.profiles);
      _drag = Offset.zero;
      _flying = false;
    });
  }

  bool _sameDeck(List<DuoProfile> a, List<DuoProfile> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].resolvedUserId != b[i].resolvedUserId) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  Future<void> swipeTop(SwipeDirection direction) async {
    if (widget.disabled || _flying || _cards.isEmpty) return;
    await _flyOff(direction);
  }

  Future<void> _flyOff(SwipeDirection direction) async {
    if (_flying || _cards.isEmpty) return;
    setState(() => _flying = true);

    final start = _drag;
    final end = Offset(direction == SwipeDirection.right ? _exitX : -_exitX, _drag.dy);

    _flyAnimation = Tween<Offset>(begin: start, end: end).animate(
      CurvedAnimation(parent: _flyController, curve: Curves.easeOutCubic),
    );

    _flyController.reset();
    await _flyController.forward();
    if (!mounted) return;
    _commit(direction);
  }

  void _commit(SwipeDirection direction) {
    if (_cards.isEmpty) {
      _resetDrag();
      return;
    }
    final profile = _cards.last;
    final accepted = widget.onSwipe(direction, profile);

    if (!mounted) return;

    if (accepted) {
      // Drop the card locally so the next person is visible immediately —
      // waiting for parent rebuild used to snap the same person back.
      setState(() {
        _cards = List<DuoProfile>.from(_cards)..removeLast();
        _drag = Offset.zero;
        _flying = false;
      });
      _flyController.reset();
    } else {
      _resetDrag();
    }
  }

  void _resetDrag() {
    if (!mounted) return;
    setState(() {
      _drag = Offset.zero;
      _flying = false;
    });
    _flyController.reset();
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
    } else if (widget.onSwipeUp != null &&
        _cards.isNotEmpty &&
        _drag.dx.abs() < _swipeThreshold &&
        (_drag.dy < -90 || details.velocity.pixelsPerSecond.dy < -650)) {
      // Upward swipe: snap back and open the profile.
      HapticFeedback.selectionClick();
      setState(() => _drag = Offset.zero);
      widget.onSwipeUp!(_cards.last);
    } else {
      setState(() => _drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _cards.length; i++)
              _buildCard(
                context: context,
                profile: _cards[i],
                index: i,
                total: _cards.length,
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
    final cardId = 'match-card-${profile.resolvedUserId ?? profile.displayName}';
    final cardKey = ValueKey(cardId);
    final photos = isTop
        ? resolveProfilePhotoUrls(profile)
        : [resolveProfilePhotoUrl(profile, preset: CloudinaryPreset.matchCard)];
    if (isTop && _photoCardId != cardId) {
      _photoCardId = cardId;
      _photoIndex = 0;
      for (final url in photos.skip(1)) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    }
    final current = isTop ? _photoIndex.clamp(0, photos.length - 1) : 0;

    final card = KeyedSubtree(
      key: cardKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CardPhoto(key: ValueKey(photos[current]), url: photos[current]),
              if (isTop && photos.length > 1) _PhotoProgress(count: photos.length, current: current),
              widget.overlayBuilder?.call(profile, isTop) ??
                  MatchCardOverlay(profile: profile, isTopCard: isTop),
            ],
          ),
        ),
      ),
    );

    if (!isTop) {
      return Positioned.fill(
        child: IgnorePointer(
          child: Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.scale(scale: scale, child: card),
          ),
        ),
      );
    }

    final rotation = (_drag.dx / 180).clamp(-_rotationRange, _rotationRange) * (3.14159 / 180);
    final likeOpacity = (_drag.dx / 120).clamp(0.0, 1.0);
    final skipOpacity = (-_drag.dx / 120).clamp(0.0, 1.0);

    // IMPORTANT: Positioned.fill must be the direct Stack child — never wrap it
    // in GestureDetector first (that breaks layout → blank grey cards).
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: widget.disabled || _flying
            ? null
            : (d) => setState(() => _drag += d.delta),
        onPanEnd: widget.disabled || _flying ? null : _onPanEnd,
        onTapUp: photos.length < 2 || _flying
            ? null
            : (d) {
                final goBack = d.localPosition.dx < constraints.maxWidth / 3;
                final next = goBack
                    ? (current - 1).clamp(0, photos.length - 1)
                    : (current + 1).clamp(0, photos.length - 1);
                if (next != current) setState(() => _photoIndex = next);
              },
        child: AnimatedBuilder(
          animation: _flying && _flyAnimation != null ? _flyAnimation! : const AlwaysStoppedAnimation(0),
          builder: (context, child) {
            final offset = _flying && _flyAnimation != null ? _flyAnimation!.value : _drag;
            final rot = _flying && _flyAnimation != null
                ? (offset.dx / 180).clamp(-_rotationRange, _rotationRange) * (3.14159 / 180)
                : rotation;
            final like = _flying ? (offset.dx / 120).clamp(0.0, 1.0) : likeOpacity;
            final skip = _flying ? (-offset.dx / 120).clamp(0.0, 1.0) : skipOpacity;
            return Transform.translate(
              offset: offset,
              child: Transform.rotate(
                angle: rot,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (offset.dx > 14)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.35 * like),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    if (offset.dx < -14)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.35 * skip),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    child!,
                    if (like > 0.08)
                      Positioned(
                        top: 36,
                        left: 24,
                        child: Opacity(
                          opacity: like,
                          child: _SwipeStamp(label: 'LIKE', color: Colors.green.shade400),
                        ),
                      ),
                    if (skip > 0.08)
                      Positioned(
                        top: 36,
                        right: 24,
                        child: Opacity(
                          opacity: skip,
                          child: const _SwipeStamp(label: 'NOPE', color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          child: card,
        ),
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delivery = cloudinaryDeliveryUrl(url, preset: CloudinaryPreset.matchCard);
    final imageUrl = delivery.isNotEmpty ? delivery : url;

    if (imageUrl.isEmpty) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white24)),
      );
    }

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 160),
        placeholder: (_, __) => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white38)),
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

/// Stories-style photo progress bars and counter (mirrors web match card).
class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 80,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x73000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          // Photo bars hug the card's top edge (inset just enough to clear
          // the rounded corners).
          Positioned(
            left: 24,
            right: 24,
            top: 2,
            child: Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 260),
                        widthFactor: i <= current ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: i < current ? 0.4 : 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${current + 1} / $count',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
