import 'package:hive_flutter/hive_flutter.dart';

/// Generic Hive-backed API response cache with TTL.
class ApiCacheStore {
  ApiCacheStore(this._box);

  final Box<dynamic> _box;

  static const _prefix = 'api_cache:';

  T? read<T>(String key, T Function(Map<String, dynamic> json) parser) {
    final raw = _box.get('$_prefix$key');
    if (raw is! Map) return null;
    final expiresAt = raw['expires_at'] as int? ?? 0;
    if (expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return null;
    }
    final payload = raw['payload'];
    if (payload is! Map) return null;
    try {
      return parser(Map<String, dynamic>.from(payload));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String key,
    Map<String, dynamic> payload, {
    required Duration ttl,
  }) async {
    await _box.put('$_prefix$key', {
      'payload': payload,
      'expires_at': DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds,
    });
  }

  Future<void> invalidate(String key) async {
    await _box.delete('$_prefix$key');
  }

  Future<void> invalidatePrefix(String prefix) async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith('$_prefix$prefix'))
        .toList();
    for (final key in keys) {
      await _box.delete(key);
    }
  }
}
