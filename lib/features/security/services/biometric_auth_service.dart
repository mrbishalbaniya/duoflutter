import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/security_models.dart';

class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'duo_biometric_token';
  static const _enabledKey = 'duo_biometric_enabled';

  Future<BiometricCapabilities> getCapabilities() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      final labels = <String>[];
      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        labels.add('fingerprint');
      }
      if (types.contains(BiometricType.face)) {
        labels.add('face');
      }
      if (supported) {
        labels.add('pin');
      }
      return BiometricCapabilities(
        supported: supported,
        canCheckBiometrics: canCheck,
        availableTypes: labels.toSet().toList(),
      );
    } on PlatformException {
      return const BiometricCapabilities(
        supported: false,
        canCheckBiometrics: false,
        availableTypes: [],
      );
    }
  }

  Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _enabledKey, value: 'true');
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<bool> isLocallyEnabled() async {
    final enabled = await _storage.read(key: _enabledKey);
    final token = await _storage.read(key: _tokenKey);
    return enabled == 'true' && token != null && token.isNotEmpty;
  }

  Future<void> clearLocal() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _enabledKey);
  }
}
