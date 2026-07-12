int compareSemanticVersions(String left, String right) {
  List<int> parts(String value) {
    return value
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  final a = parts(left);
  final b = parts(right);
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x < y) return -1;
    if (x > y) return 1;
  }
  return 0;
}

bool isNewerVersion({
  required String installedVersion,
  required int installedBuild,
  required String latestVersion,
  required int latestBuild,
}) {
  if (latestBuild > installedBuild) return true;
  if (latestBuild < installedBuild) return false;
  return compareSemanticVersions(installedVersion, latestVersion) > 0;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatSpeed(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';

String formatEta(int seconds) {
  if (seconds <= 0) return 'Calculating…';
  if (seconds < 60) return '${seconds}s remaining';
  final minutes = seconds ~/ 60;
  final rem = seconds % 60;
  return '${minutes}m ${rem}s remaining';
}
