import 'package:equatable/equatable.dart';

class SecurityOverview extends Equatable {
  const SecurityOverview({
    required this.twoFactorEnabled,
    this.twoFactorMethod,
    required this.biometricEnabled,
    required this.activeDevices,
    required this.activeSessions,
    required this.unreadAlerts,
    required this.rememberDeviceDays,
    required this.currentDeviceId,
    required this.hasBackupCodes,
  });

  final bool twoFactorEnabled;
  final String? twoFactorMethod;
  final bool biometricEnabled;
  final int activeDevices;
  final int activeSessions;
  final int unreadAlerts;
  final int rememberDeviceDays;
  final String currentDeviceId;
  final bool hasBackupCodes;

  factory SecurityOverview.fromJson(Map<String, dynamic> json) {
    return SecurityOverview(
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      twoFactorMethod: json['two_factor_method'] as String?,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      activeDevices: json['active_devices'] as int? ?? 0,
      activeSessions: json['active_sessions'] as int? ?? 0,
      unreadAlerts: json['unread_alerts'] as int? ?? 0,
      rememberDeviceDays: json['remember_device_days'] as int? ?? 30,
      currentDeviceId: json['current_device_id'] as String? ?? '',
      hasBackupCodes: json['has_backup_codes'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        twoFactorEnabled,
        twoFactorMethod,
        biometricEnabled,
        activeDevices,
        activeSessions,
        unreadAlerts,
        rememberDeviceDays,
        currentDeviceId,
        hasBackupCodes,
      ];
}

class UserDevice extends Equatable {
  const UserDevice({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.model,
    required this.platform,
    required this.platformLabel,
    required this.osVersion,
    required this.appVersion,
    required this.browser,
    required this.ipAddress,
    required this.location,
    required this.isTrusted,
    required this.isTrustedActive,
    required this.isCurrent,
    required this.lastActive,
    required this.loginTime,
  });

  final int id;
  final String deviceId;
  final String deviceName;
  final String model;
  final String platform;
  final String platformLabel;
  final String osVersion;
  final String appVersion;
  final String browser;
  final String? ipAddress;
  final String location;
  final bool isTrusted;
  final bool isTrustedActive;
  final bool isCurrent;
  final DateTime? lastActive;
  final DateTime? loginTime;

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] as int,
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? 'Unknown device',
      model: json['model'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
      platformLabel: json['platform_label'] as String? ?? '',
      osVersion: json['os_version'] as String? ?? '',
      appVersion: json['app_version'] as String? ?? '',
      browser: json['browser'] as String? ?? '',
      ipAddress: json['ip_address'] as String?,
      location: json['location'] as String? ?? '',
      isTrusted: json['is_trusted'] as bool? ?? false,
      isTrustedActive: json['is_trusted_active'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
      lastActive: _parseDate(json['last_active']),
      loginTime: _parseDate(json['login_time']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String get displayIcon {
    if (platform == 'web') return 'web';
    if (platform == 'ios') return 'ios';
    return 'android';
  }

  @override
  List<Object?> get props => [id, deviceId, deviceName, isCurrent, isTrustedActive];
}

class LoginHistoryEntry extends Equatable {
  const LoginHistoryEntry({
    required this.id,
    required this.success,
    required this.ipAddress,
    required this.location,
    required this.deviceName,
    required this.browser,
    required this.osName,
    required this.failureReason,
    required this.isCurrent,
    required this.createdAt,
  });

  final int id;
  final bool success;
  final String? ipAddress;
  final String location;
  final String deviceName;
  final String browser;
  final String osName;
  final String failureReason;
  final bool isCurrent;
  final DateTime? createdAt;

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      id: json['id'] as int,
      success: json['success'] as bool? ?? true,
      ipAddress: json['ip_address'] as String?,
      location: json['location'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      browser: json['browser'] as String? ?? '',
      osName: json['os_name'] as String? ?? '',
      failureReason: json['failure_reason'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      createdAt: UserDevice._parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, success, createdAt];
}

class SecurityEvent extends Equatable {
  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.title,
    required this.message,
    required this.ipAddress,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String eventType;
  final String title;
  final String message;
  final String? ipAddress;
  final bool isRead;
  final DateTime? createdAt;

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'] as int,
      eventType: json['event_type'] as String? ?? '',
      title: json['title'] as String? ?? 'Security alert',
      message: json['message'] as String? ?? '',
      ipAddress: json['ip_address'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: UserDevice._parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, eventType, isRead];
}

class TotpSetupData extends Equatable {
  const TotpSetupData({required this.secret, required this.otpauthUri});

  final String secret;
  final String otpauthUri;

  factory TotpSetupData.fromJson(Map<String, dynamic> json) {
    return TotpSetupData(
      secret: json['secret'] as String,
      otpauthUri: json['otpauth_uri'] as String,
    );
  }

  @override
  List<Object?> get props => [secret, otpauthUri];
}

class TwoFactorLoginChallenge extends Equatable {
  const TwoFactorLoginChallenge({
    required this.challengeToken,
    required this.methods,
  });

  final String challengeToken;
  final List<String> methods;

  factory TwoFactorLoginChallenge.fromJson(Map<String, dynamic> json) {
    return TwoFactorLoginChallenge(
      challengeToken: json['challenge_token'] as String,
      methods: (json['methods'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  @override
  List<Object?> get props => [challengeToken, methods];
}

class BiometricCapabilities extends Equatable {
  const BiometricCapabilities({
    required this.supported,
    required this.canCheckBiometrics,
    required this.availableTypes,
  });

  final bool supported;
  final bool canCheckBiometrics;
  final List<String> availableTypes;

  bool get hasFingerprint => availableTypes.contains('fingerprint');
  bool get hasFace => availableTypes.contains('face');
  bool get hasPin => availableTypes.contains('pin');

  @override
  List<Object?> get props => [supported, canCheckBiometrics, availableTypes];
}

class DeviceFingerprint extends Equatable {
  const DeviceFingerprint({
    required this.deviceId,
    required this.deviceName,
    required this.model,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
  });

  final String deviceId;
  final String deviceName;
  final String model;
  final String platform;
  final String osVersion;
  final String appVersion;

  Map<String, dynamic> toPayload() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'model': model,
        'platform': platform,
        'os_version': osVersion,
        'app_version': appVersion,
      };

  @override
  List<Object?> get props => [deviceId, platform];
}
