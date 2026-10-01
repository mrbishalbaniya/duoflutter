import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../providers/call_providers.dart';

/// Port of DuoFrontend `components/call/CallOverlay.tsx` for outgoing,
/// connecting, active and ended phases (incoming uses [IncomingCallOverlay]).
class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  final _remoteRenderer = RTCVideoRenderer();
  final _localRenderer = RTCVideoRenderer();
  bool _renderersReady = false;
  bool _swapped = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          ref.read(callControllerProvider).phase == CallPhase.active) {
        setState(() {});
      }
    });
  }

  Future<void> _initRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
    // Rebuild when the remote frame size is known/changes (portrait phone vs
    // landscape PC camera) so we can letterbox instead of cropping.
    _remoteRenderer.onResize = () {
      if (mounted) setState(() {});
    };
    if (!mounted) return;
    setState(() => _renderersReady = true);
    _bindStreams(ref.read(callControllerProvider));
  }

  void _bindStreams(CallState call) {
    if (!_renderersReady) return;
    final local = ref.read(webRtcCallServiceProvider).localStream;
    if (_localRenderer.srcObject != local) _localRenderer.srcObject = local;
    if (_remoteRenderer.srcObject != call.remoteStream) {
      _remoteRenderer.srcObject = call.remoteStream;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _remoteRenderer.srcObject = null;
    _localRenderer.srcObject = null;
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  /// True when the remote frame's orientation differs from the screen's.
  bool _letterboxRemote(BuildContext context) {
    final w = _remoteRenderer.videoWidth;
    final h = _remoteRenderer.videoHeight;
    if (w == 0 || h == 0) return false;
    final size = MediaQuery.sizeOf(context);
    return (h > w) != (size.height > size.width);
  }

  String _elapsed(DateTime? since) {
    if (since == null) return '0:00';
    final d = DateTime.now().difference(since);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _status(CallState call) {
    switch (call.phase) {
      case CallPhase.outgoing:
        return call.callId == null ? 'Calling…' : 'Ringing…';
      case CallPhase.connecting:
        return 'Connecting…';
      case CallPhase.active:
        return call.connectionState == 'disconnected'
            ? 'Reconnecting…'
            : _elapsed(call.connectedAt);
      case CallPhase.ended:
        return call.endMessage ?? 'Call ended';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    ref.listen(callControllerProvider, (_, next) => _bindStreams(next));
    _bindStreams(call);

    final remoteHasVideo =
        call.remoteStream?.getVideoTracks().isNotEmpty ?? false;
    final showRemoteVideo = call.phase == CallPhase.active && remoteHasVideo;
    final showLocalVideo =
        call.hasLocalVideo && call.videoOn && call.phase != CallPhase.ended;
    final localFull = showLocalVideo && (!showRemoteVideo || _swapped);
    final ended = call.phase == CallPhase.ended;
    final status = _status(call);
    final photo = call.remotePhoto ?? '';

    return Material(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred photo backdrop (web: blur-3xl + gradient scrim).
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

          // Full-screen video: remote by default, local when swapped / remote has none.
          if (_renderersReady && (showRemoteVideo || localFull)) ...[
            // Remote landscape video (e.g. a PC webcam) on a portrait phone:
            // show the whole frame over a blurred copy instead of cropping it.
            if (!localFull && _letterboxRemote(context))
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Opacity(
                  opacity: 0.6,
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            RTCVideoView(
              localFull ? _localRenderer : _remoteRenderer,
              mirror: localFull,
              objectFit: !localFull && _letterboxRemote(context)
                  ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
                  : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ],

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x80000000),
                  Color(0x33000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),

          // Picture-in-picture (tap to swap).
          if (_renderersReady && showRemoteVideo && showLocalVideo)
            Positioned(
              right: 16,
              top: MediaQuery.paddingOf(context).top + 64,
              width: 116,
              height: 164,
              child: GestureDetector(
                onTap: () => setState(() => _swapped = !_swapped),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                    ),
                    child: RTCVideoView(
                      _swapped ? _remoteRenderer : _localRenderer,
                      mirror: !_swapped,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            )
          else if (call.isVideo &&
              call.hasLocalVideo &&
              !call.videoOn &&
              !ended)
            Positioned(
              right: 16,
              top: MediaQuery.paddingOf(context).top + 64,
              width: 116,
              height: 164,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xE6262626),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white60, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Camera off',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top bar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 15,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'End-to-end encrypted',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      if (showRemoteVideo)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              call.remoteName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                // Centre identity (hidden once remote video is up).
                if (!showRemoteVideo) ...[
                  _Avatar(
                    name: call.remoteName,
                    photo: photo,
                    ringing: call.phase == CallPhase.outgoing,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    call.remoteName.isEmpty ? 'Unknown' : call.remoteName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: ended
                          ? const Color(0xFFFDA4AF)
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!call.micOn && !ended)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off, size: 14, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'You are muted',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: ended
                      ? Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white70,
                            size: 30,
                          ),
                        )
                      : _ControlBar(call: call, controller: controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.call, required this.controller});

  final CallState call;
  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _ControlButton(
                icon: call.micOn ? Icons.mic : Icons.mic_off,
                label: call.micOn ? 'Mute' : 'Unmute',
                active: !call.micOn,
                onTap: controller.toggleMic,
              ),
              if (call.hasLocalVideo)
                _ControlButton(
                  icon: call.videoOn ? Icons.videocam : Icons.videocam_off,
                  label: call.videoOn ? 'Stop video' : 'Start video',
                  active: !call.videoOn,
                  onTap: controller.toggleVideo,
                ),
              if (call.hasLocalVideo && call.videoOn)
                _ControlButton(
                  icon: Icons.cameraswitch,
                  label: 'Flip',
                  onTap: controller.switchCamera,
                ),
              _ControlButton(
                icon: call.speakerOn ? Icons.volume_up : Icons.hearing,
                label: call.speakerOn ? 'Speaker' : 'Earpiece',
                active: call.speakerOn,
                onTap: controller.toggleSpeaker,
              ),
              _ControlButton(
                icon: Icons.call_end,
                label: 'End',
                danger: true,
                onTap: controller.hangup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? const Color(0xFFEF4444)
        : active
        ? Colors.white
        : Colors.white.withValues(alpha: 0.15);
    final fg = !danger && active ? Colors.black87 : Colors.white;
    final size = danger ? 56.0 : 50.0;
    // Equal share of the bar; scales down instead of overflowing when five
    // buttons (video call) + large system font don't fit the screen width.
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: bg,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(icon, color: fg, size: 24),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar with pulsing rings while ringing (web `CallAvatar`).
class _Avatar extends StatefulWidget {
  const _Avatar({
    required this.name,
    required this.photo,
    required this.ringing,
  });

  final String name;
  final String photo;
  final bool ringing;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 128.0;
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 4,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFC026D3)],
        ),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.photo.isNotEmpty
          ? CachedNetworkImage(
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
              imageUrl: widget.photo,
              fit: BoxFit.cover,
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
    if (!widget.ringing) return avatar;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        Widget ring(double phase) {
          final t = (_pulse.value + phase) % 1.0;
          return Transform.scale(
            scale: 1 + t * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15 * (1 - t)),
              ),
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [ring(0), ring(0.3), child!],
        );
      },
      child: avatar,
    );
  }
}
