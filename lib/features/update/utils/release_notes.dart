import 'dart:math' as math;

/// Filters technical / GitHub release noise into customer-facing bullets.
const defaultReleaseNotes = <String>[
  'General performance improvements.',
  'Bug fixes.',
  'Improved stability.',
];

final _blockedPattern = RegExp(
  r'(commit|hash|sha(?:-?256)?|certificate|digest|\bapk\b|\baab\b|workflow|'
  r'artifact|github|release from|signing|install help|package conflicts|'
  r'play store|download url|checksum|\bmain\b\s*@|[0-9a-f]{7,40})',
  caseSensitive: false,
);

final _urlPattern = RegExp(r'https?://\S+|www\.\S+', caseSensitive: false);
final _markdownFence = RegExp(r'```.*?```', dotAll: true);
final _inlineCode = RegExp(r'`([^`]*)`');
final _heading = RegExp(r'^#{1,6}\s*');
final _bullet = RegExp(r'^[-*+•]\s+');
final _numbered = RegExp(r'^\d+[.)]\s+');
final _emphasis = RegExp(r'[*_~]+');
final _whitespace = RegExp(r'\s+');

String stripReleaseMarkdown(String line) {
  var text = line;
  text = text.replaceAll(_markdownFence, ' ');
  text = text.replaceAllMapped(_inlineCode, (m) => m.group(1) ?? '');
  text = text.replaceFirst(_heading, '');
  text = text.replaceFirst(_bullet, '');
  text = text.replaceFirst(_numbered, '');
  text = text.replaceAll(_emphasis, '');
  text = text.replaceAll(_urlPattern, '');
  text = text.replaceAll('|', ' ');
  return text.replaceAll(_whitespace, ' ').trim().replaceAll(RegExp(r'^[- ]+|[- ]+$'), '');
}

bool _isBlocked(String line) {
  if (line.isEmpty) return true;
  if (_blockedPattern.hasMatch(line)) return true;
  if (line.contains('```') || line.contains('~~') || line.contains('<') || line.contains('{')) {
    return true;
  }
  return line.length < 8;
}

List<String> sanitizeReleaseNotes(
  dynamic raw, {
  int maxItems = 12,
  bool withFallback = true,
}) {
  final lines = <String>[];
  if (raw is List) {
    for (final item in raw) {
      final text = item.toString().trim();
      if (text.isNotEmpty) lines.add(text);
    }
  } else if (raw is String && raw.trim().isNotEmpty) {
    final withoutFences = raw.replaceAll(_markdownFence, '\n');
    for (final line in withoutFences.split('\n')) {
      final text = line.trim();
      if (text.isNotEmpty) lines.add(text);
    }
  }

  final seen = <String>{};
  final notes = <String>[];
  for (final rawLine in lines) {
    var line = stripReleaseMarkdown(rawLine);
    if (_isBlocked(line)) continue;
    if (line.isNotEmpty && !'.!?'.contains(line[line.length - 1])) {
      line = '$line.';
    }
    final key = line.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    notes.add(line);
    if (notes.length >= maxItems) break;
  }

  if (notes.isNotEmpty) return notes;
  return withFallback ? List<String>.from(defaultReleaseNotes) : const [];
}

String resolveReleaseTitle(String? title, {String version = ''}) {
  final cleaned = stripReleaseMarkdown((title ?? '').trim());
  if (cleaned.isNotEmpty && !_isBlocked(cleaned) && cleaned.length >= 4) {
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }
  if (version.isNotEmpty) return 'Performance & Stability Update';
  return 'App Update';
}

List<String> visibleReleaseNotes(List<String> notes, {int limit = 6}) {
  final sanitized = sanitizeReleaseNotes(notes);
  return sanitized.take(limit).toList(growable: false);
}

int hiddenReleaseNoteCount(List<String> notes, {int limit = 6}) {
  final sanitized = sanitizeReleaseNotes(notes);
  return math.max(0, sanitized.length - limit);
}
