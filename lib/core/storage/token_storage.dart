import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const duoSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? duoSecureStorage;

  static const _accessKey = 'duo_access_token';
  static const _refreshKey = 'duo_refresh_token';

  final FlutterSecureStorage _storage;
  String? _cachedAccess;
  String? _cachedRefresh;

  Future<String?> getAccessToken() async {
    if (_cachedAccess != null && _cachedAccess!.isNotEmpty) {
      return _cachedAccess;
    }
    _cachedAccess = await _storage.read(key: _accessKey);
    return _cachedAccess;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefresh != null && _cachedRefresh!.isNotEmpty) {
      return _cachedRefresh;
    }
    _cachedRefresh = await _storage.read(key: _refreshKey);
    return _cachedRefresh;
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccessToken(String access) async {
    _cachedAccess = access;
    await _storage.write(key: _accessKey, value: access);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
