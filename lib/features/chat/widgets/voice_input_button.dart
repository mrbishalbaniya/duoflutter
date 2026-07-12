import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';

class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({
    super.key,
    required this.listening,
    required this.paused,
    required this.onListeningChange,
    this.disabled = false,
    this.iconOnly = true,
  });

  final bool listening;
  final bool paused;
  final ValueChanged<bool> onListeningChange;
  final bool disabled;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = listening || paused;

    void handleTap() {
      if (disabled) return;
      HapticFeedback.lightImpact();
      if (paused) {
        onListeningChange(true);
        return;
      }
      onListeningChange(!listening);
    }

    final label = listening
        ? 'Pause voice recording'
        : paused
            ? 'Resume voice recording'
            : 'Start voice recording';

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: handleTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? DuoColors.primary.withValues(alpha: 0.3)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              color: active ? DuoColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(child: _MicIcon(listening: listening, paused: paused)),
                ),
                if (listening && !iconOnly) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 80,
                    child: _InlineRecordingWaveform(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  const _MicIcon({required this.listening, required this.paused});

  final bool listening;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    if (listening) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: DuoColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 2000.ms, curve: Curves.easeInOut);
    }
    if (paused) {
      return const Icon(Icons.play_arrow_rounded, color: DuoColors.primary, size: 22);
    }
    return const Icon(Icons.mic_rounded, color: DuoColors.primary, size: 22);
  }
}

class _InlineRecordingWaveform extends StatelessWidget {
  const _InlineRecordingWaveform();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        8,
        (i) => Container(
          width: 2,
          height: 3 + ((i * 5) % 10),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: DuoColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
