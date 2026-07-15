import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../about/about_quality.dart';

class AboutQualityMeter extends StatelessWidget {
  const AboutQualityMeter({super.key, required this.quality});

  final ProfileQuality quality;

  Color _color(ColorScheme scheme) {
    return switch (quality.level) {
      ProfileQualityLevel.excellent => const Color(0xFF22C55E),
      ProfileQualityLevel.good => scheme.primary,
      ProfileQualityLevel.needsMore => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                quality.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              '${quality.score}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: quality.score / 100,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class AboutCharCounter extends StatelessWidget {
  const AboutCharCounter({
    super.key,
    required this.length,
    required this.min,
    required this.max,
  });

  final int length;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ok = length >= min && length <= max;
    final color = length > max
        ? scheme.error
        : ok
            ? scheme.primary
            : scheme.onSurfaceVariant;
    return Text(
      '$length / $max${length < min ? '  ·  min $min' : ''}',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    );
  }
}

Future<bool> confirmReplaceAboutCopy(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('Replace existing text?'),
        content: Text(
          'AI will overwrite your current bio, looking-for, and future goals with new suggestions from your profile.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep mine'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text('Replace'),
          ),
        ],
      );
    },
  );
  return result == true;
}
