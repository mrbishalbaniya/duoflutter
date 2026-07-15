// Offline quality scoring + helpers for registration About step (mirrors web).

class AboutFieldLimits {
  const AboutFieldLimits({required this.min, required this.max});

  final int min;
  final int max;
}

abstract final class AboutLimits {
  static const bio = AboutFieldLimits(min: 40, max: 500);
  static const lookingFor = AboutFieldLimits(min: 20, max: 400);
  static const futureGoals = AboutFieldLimits(min: 20, max: 400);
}

abstract final class AboutPlaceholders {
  static const bio =
      'Example: "I\'m a software engineer who enjoys hiking, coffee, and exploring new places. I value honesty, kindness, and meaningful conversations."';
  static const lookingFor =
      'Example: "I\'m looking for someone genuine, respectful, and interested in building a long-term relationship."';
  static const futureGoals =
      'Example: "I hope to grow professionally, travel more, and eventually build a happy family."';
}

enum ProfileQualityLevel { excellent, good, needsMore }

class ProfileQuality {
  const ProfileQuality({
    required this.level,
    required this.label,
    required this.score,
  });

  final ProfileQualityLevel level;
  final String label;
  final int score;
}

String truncateAtSentence(String text, int maxChars) {
  final value = text.trim();
  if (value.length <= maxChars) return value;

  final parts = value
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  final kept = <String>[];
  for (final part in parts) {
    final trial = [...kept, part].join(' ').trim();
    if (kept.isNotEmpty && trial.length > maxChars) break;
    if (kept.isEmpty && part.length > maxChars) {
      final clipped = part
          .substring(0, maxChars - 1)
          .replaceAll(RegExp(r'\s+\S*$'), '')
          .replaceAll(RegExp(r'[,;.]+$'), '');
      return clipped.isNotEmpty ? '$clipped.' : part.substring(0, maxChars);
    }
    kept.add(part);
  }
  return kept.join(' ').trim();
}

int _uniqueWordCount(String text) {
  final words = text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1);
  return words.toSet().length;
}

int _sentenceCount(String text) {
  return text
      .split(RegExp(r'[.!?]+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .length;
}

ProfileQuality assessWritingQuality(String text, AboutFieldLimits opts) {
  final value = text.trim();
  final length = value.length;
  if (length == 0) {
    return const ProfileQuality(
      level: ProfileQualityLevel.needsMore,
      label: 'Needs More Detail',
      score: 0,
    );
  }

  final unique = _uniqueWordCount(value);
  final sentences = _sentenceCount(value);
  var score = 0.0;

  final lengthTarget = (opts.max * 0.55)
      .clamp(0, double.infinity)
      .toDouble();
  final solidTarget = (opts.min * 2.2) > (opts.min + 60) ? opts.min * 2.2 : (opts.min + 60).toDouble();
  final target = lengthTarget < solidTarget ? lengthTarget : solidTarget;
  score += (length / target * 45).clamp(0, 45);
  score += (unique / 28 * 30).clamp(0, 30);

  if (sentences >= 3) {
    score += 20;
  } else if (sentences == 2) {
    score += 12;
  } else if (sentences == 1 && length >= opts.min) {
    score += 6;
  }

  if (length < opts.min) score = score.clamp(0, 38);
  if (length > opts.max) score = score.clamp(0, 55);

  final rounded = score.round().clamp(0, 100);
  if (rounded >= 75) {
    return ProfileQuality(level: ProfileQualityLevel.excellent, label: 'Excellent', score: rounded);
  }
  if (rounded >= 50) {
    return ProfileQuality(level: ProfileQualityLevel.good, label: 'Good', score: rounded);
  }
  return ProfileQuality(
    level: ProfileQualityLevel.needsMore,
    label: 'Needs More Detail',
    score: rounded,
  );
}
