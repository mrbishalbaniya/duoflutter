import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/duo_theme.dart';
import '../services/voice_message_player.dart';

const _barCount = 30;

List<double> seedWaveHeights(String seed) {
  var hash = 0;
  for (var i = 0; i < seed.length; i++) {
    hash = ((hash << 5) - hash + seed.codeUnitAt(i)) | 0;
  }
  return List.generate(_barCount, (idx) {
    final value = (math.sin(hash + idx * 12.9898).abs() * 10000) % 1;
    return 4 + value * 12;
  });
}

String formatVoiceDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '$mins:${secs.toString().padLeft(2, '0')}';
}

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.audioUrl,
    this.durationSeconds = 0,
    this.waveColor,
    this.onGradientBubble = false,
    this.compact = true,
  });

  final String messageId;
  final String audioUrl;
  final int durationSeconds;
  final Color? waveColor;
  final bool onGradientBubble;
  final bool compact;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = VoiceMessagePlayer.instance;
  late final List<double> _barHeights;
  bool _isPlaying = false;
  double _progress = 0;
  int _duration = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<void>? _resetSub;
  VoidCallback? _activeIdListener;

  bool get _isActive => _player.activeMessageId == widget.messageId;

  @override
  void initState() {
    super.initState();
    _barHeights = seedWaveHeights(widget.audioUrl);
    _duration = widget.durationSeconds;
    _activeIdListener = () {
      if (!mounted) return;
      final active = _player.activeMessageIdNotifier.value == widget.messageId;
      if (!active && _isPlaying) {
        setState(() {
          _isPlaying = false;
          _progress = 0;
        });
        _detachStreams();
      }
    };
    _player.activeMessageIdNotifier.addListener(_activeIdListener!);
  }

  void _attachStreams() {
    _positionSub ??= _player.positionStream.listen((position) {
      if (!_isActive || !mounted) return;
      final totalMs = _duration > 0 ? _duration * 1000 : 1;
      setState(() => _progress = position.inMilliseconds / totalMs);
    });
    _playingSub ??= _player.playingStream.listen((playing) {
      if (!_isActive || !mounted) return;
      setState(() => _isPlaying = playing);
    });
    _resetSub ??= _player.progressResetStream.listen((_) {
      if (!_isActive || !mounted) return;
      setState(() {
        _isPlaying = false;
        _progress = 0;
      });
    });
  }

  void _detachStreams() {
    _positionSub?.cancel();
    _playingSub?.cancel();
    _resetSub?.cancel();
    _positionSub = null;
    _playingSub = null;
    _resetSub = null;
  }

  @override
  void didUpdateWidget(covariant VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _player.stopIfActive(widget.messageId);
      setState(() {
        _isPlaying = false;
        _progress = 0;
      });
      _detachStreams();
    }
    if (widget.durationSeconds > 0) {
      _duration = widget.durationSeconds;
    }
  }

  @override
  void dispose() {
    if (_activeIdListener != null) {
      _player.activeMessageIdNotifier.removeListener(_activeIdListener!);
    }
    _detachStreams();
    unawaited(_player.stopIfActive(widget.messageId));
    super.dispose();
  }

  Future<void> _togglePlay() async {
    HapticFeedback.selectionClick();
    _attachStreams();
    await _player.toggle(widget.messageId, widget.audioUrl);
    if (mounted) {
      setState(() => _isPlaying = _player.activeMessageId == widget.messageId);
    }
  }

  void _seekFromTap(TapDownDetails details, BoxConstraints constraints) {
    if (!_isActive) return;
    final fraction = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    setState(() => _progress = fraction);
    unawaited(_player.seek(widget.messageId, fraction));
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.waveColor ??
        (widget.onGradientBubble ? Colors.white : const Color(0xFFB76E79));
    final durationLabel = formatVoiceDuration(_duration);
    final buttonSize = widget.compact ? 28.0 : 32.0;
    final iconSize = widget.compact ? 14.0 : 16.0;

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.compact ? 200 : 220,
          maxWidth: widget.compact ? 260 : 320,
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlay,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.onGradientBubble
                          ? Colors.white.withValues(alpha: 0.3)
                          : DuoColors.primary.withValues(alpha: 0.25),
                    ),
                    color: widget.onGradientBubble
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: iconSize,
                    color: widget.onGradientBubble ? Colors.white : DuoColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (d) => _seekFromTap(d, constraints),
                    child: SizedBox(
                      height: widget.compact ? 20 : 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _barHeights
                                .map(
                                  (h) => Container(
                                    width: 2,
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: waveColor.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progress.clamp(0, 1),
                              child: Container(
                                height: widget.compact ? 20 : 24,
                                decoration: BoxDecoration(
                                  color: waveColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: widget.compact ? 36 : 40,
              child: Text(
                durationLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: widget.compact ? 10 : 12,
                  color: widget.onGradientBubble
                      ? Colors.white.withValues(alpha: 0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
