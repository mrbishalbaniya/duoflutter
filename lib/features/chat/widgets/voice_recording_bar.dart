import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';

String formatRecordingTime(int seconds) {
  final mins = seconds ~/ 60;
  final secs = seconds % 60;
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

class VoiceRecordingBar extends StatelessWidget {
  const VoiceRecordingBar({
    super.key,
    required this.active,
    required this.seconds,
    this.visible = true,
  });

  final bool active;
  final int seconds;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _RecordingDot(active: active),
        const SizedBox(width: 12),
        Expanded(child: _RecordingWaveform(active: active)),
        const SizedBox(width: 12),
        Text(
          formatRecordingTime(seconds),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RecordingDot extends StatelessWidget {
  const _RecordingDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
      );
    }

    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(2.2, 2.2),
                duration: 900.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 900.ms),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingWaveform extends StatelessWidget {
  const _RecordingWaveform({required this.active});

  final bool active;

  static const _barCount = 24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          final peak = 4.0 + ((i * 7) % 14);
          final mid = 4.0 + ((i * 5) % 8);
          return _WaveBar(
            index: i,
            active: active,
            heights: [3, peak, mid, 3],
          );
        }),
      ),
    );
  }
}

class _WaveBar extends StatefulWidget {
  const _WaveBar({
    required this.index,
    required this.active,
    required this.heights,
  });

  final int index;
  final bool active;
  final List<double> heights;

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _WaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      Future.delayed(Duration(milliseconds: widget.index * 40), () {
        if (mounted && widget.active) {
          _controller.repeat();
        }
      });
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final values = widget.heights;
        final t = _controller.value * values.length;
        final idx = t.floor() % values.length;
        final next = (idx + 1) % values.length;
        final frac = t - t.floor();
        final height = widget.active
            ? values[idx] + (values[next] - values[idx]) * frac
            : 3.0;

        return Container(
          width: 2,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: DuoColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}
