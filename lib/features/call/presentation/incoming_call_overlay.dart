import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_providers.dart';

/// Incoming ring screen (web `IncomingCall` card, full-screen on mobile).
class IncomingCallOverlay extends ConsumerWidget {
  const IncomingCallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    if (call.phase != CallPhase.incoming) return const SizedBox.shrink();
    final controller = ref.read(callControllerProvider.notifier);
    final photo = call.remotePhoto ?? '';
    final label = call.isVideo ? 'Incoming video call' : 'Incoming voice call';
    final initial = call.remoteName.isNotEmpty
        ? call.remoteName[0].toUpperCase()
        : '?';

    return Material(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Opacity(
                opacity: 0.5,
                child: CachedNetworkImage(
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  imageUrl: photo,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x99881337),
                    Color(0xFF171717),
                    Color(0x99701A75),
                  ],
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x33000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        call.isVideo ? Icons.videocam : Icons.call,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _PulsingAvatar(photo: photo, initial: initial),
                  const SizedBox(height: 28),
                  Text(
                    call.remoteName.isEmpty ? 'Someone' : call.remoteName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Duo',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundAction(
                        color: const Color(0xFFEF4444),
                        icon: Icons.call_end,
                        label: 'Decline',
                        onTap: controller.rejectIncoming,
                      ),
                      _RoundAction(
                        color: const Color(0xFF22C55E),
                        icon: call.isVideo ? Icons.videocam : Icons.call,
                        label: 'Accept',
                        onTap: controller.acceptIncoming,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  const _PulsingAvatar({required this.photo, required this.initial});

  final String photo;
  final String initial;

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 132.0;
    final avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 4,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFC026D3)],
        ),
      ),
      child: widget.photo.isNotEmpty
          ? CachedNetworkImage(
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
              imageUrl: widget.photo,
              fit: BoxFit.cover,
            )
          : Center(
              child: Text(
                widget.initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        Widget ring(double phase) {
          final t = (_c.value + phase) % 1.0;
          return Transform.scale(
            scale: 1 + t * 0.7,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16 * (1 - t)),
              ),
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [ring(0), ring(0.35), child!],
        );
      },
      child: avatar,
    );
  }
}
