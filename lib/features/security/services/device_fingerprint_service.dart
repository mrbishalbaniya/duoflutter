import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/security_models.dart';

class DeviceFingerprintService {
  DeviceFingerprintService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _deviceIdKey = 'duo_device_id';

  DeviceFingerprint? _cached;

  Future<DeviceFingerprint> getFingerprint() async {
    if (_cached != null) return _cached!;

    var deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = await _generateDeviceId();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }

    final info = DeviceInfoPlugin();
    final package = await PackageInfo.fromPlatform();

    String deviceName = 'Duo Device';
    String model = '';
    String platform = 'unknown';
    String osVersion = '';

    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      platform = 'android';
      model = android.model;
      deviceName = android.brand.isNotEmpty ? '${android.brand} ${android.model}' : android.model;
      osVersion = 'Android ${android.version.release}';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      platform = 'ios';
      model = ios.utsname.machine;
      deviceName = ios.name;
      osVersion = 'iOS ${ios.systemVersion}';
    } else {
      platform = defaultTargetPlatform.name;
    }

    _cached = DeviceFingerprint(
      deviceId: deviceId,
      deviceName: deviceName,
      model: model,
      platform: platform,
      osVersion: osVersion,
      appVersion: package.version,
    );
    return _cached!;
  }

  Future<String> _generateDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return 'and-${android.id}';
    }
    if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return 'ios-${ios.identifierForVendor ?? DateTime.now().millisecondsSinceEpoch}';
    }
    return 'dev-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, String> headerOverrides() {
    final fp = _cached;
    if (fp == null) return {};
    return {
      'X-Device-Id': fp.deviceId,
      'X-Platform': fp.platform,
      'X-App-Version': fp.appVersion,
    };
  }
}
