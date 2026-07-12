import 'package:hive_flutter/hive_flutter.dart';

class UpdateLocalStore {
  UpdateLocalStore(this._box);

  final Box<dynamic> _box;

  static const _lastCheckKey = 'ota_last_check_ms';
  static const _ignoredVersionKey = 'ota_ignored_version';
  static const _cachedVersionKey = 'ota_cached_version_json';
  static const _partialDownloadKey = 'ota_partial_download';

  DateTime? get lastCheckedAt {
    final raw = _box.get(_lastCheckKey);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  Future<void> setLastCheckedAt(DateTime value) async {
    await _box.put(_lastCheckKey, value.millisecondsSinceEpoch);
  }

  String? get ignoredVersion => _box.get(_ignoredVersionKey) as String?;

  Future<void> setIgnoredVersion(String? value) async {
    if (value == null || value.isEmpty) {
      await _box.delete(_ignoredVersionKey);
    } else {
      await _box.put(_ignoredVersionKey, value);
    }
  }

  Map<String, dynamic>? get cachedVersion {
    final raw = _box.get(_cachedVersionKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> setCachedVersion(Map<String, dynamic>? value) async {
    if (value == null) {
      await _box.delete(_cachedVersionKey);
    } else {
      await _box.put(_cachedVersionKey, value);
    }
  }

  Map<String, dynamic>? get partialDownload {
    final raw = _box.get(_partialDownloadKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> setPartialDownload({
    required String path,
    required String url,
    required int downloadedBytes,
  }) async {
    await _box.put(_partialDownloadKey, {
      'path': path,
      'url': url,
      'downloaded_bytes': downloadedBytes,
    });
  }

  Future<void> clearPartialDownload() async {
    await _box.delete(_partialDownloadKey);
  }
}
