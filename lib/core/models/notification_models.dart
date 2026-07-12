import 'package:equatable/equatable.dart';

class FirebasePublicConfig extends Equatable {
  const FirebasePublicConfig({
    required this.apiKey,
    required this.authDomain,
    required this.projectId,
    required this.messagingSenderId,
    required this.appId,
  });

  factory FirebasePublicConfig.fromJson(Map<String, dynamic> json) {
    return FirebasePublicConfig(
      apiKey: json['apiKey'] as String? ?? '',
      authDomain: json['authDomain'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      messagingSenderId: json['messagingSenderId'] as String? ?? '',
      appId: json['appId'] as String? ?? '',
    );
  }

  final String apiKey;
  final String authDomain;
  final String projectId;
  final String messagingSenderId;
  final String appId;

  bool get isComplete =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      appId.isNotEmpty;

  @override
  List<Object?> get props => [apiKey, projectId, appId];
}

class PushConfig extends Equatable {
  const PushConfig({
    this.enabled = false,
    this.firebase,
    this.vapidKey,
  });

  factory PushConfig.fromJson(Map<String, dynamic> json) {
    final firebaseJson = json['firebase'];
    return PushConfig(
      enabled: json['enabled'] as bool? ?? false,
      firebase: firebaseJson is Map<String, dynamic>
          ? FirebasePublicConfig.fromJson(firebaseJson)
          : null,
      vapidKey: json['vapidKey'] as String?,
    );
  }

  final bool enabled;
  final FirebasePublicConfig? firebase;
  final String? vapidKey;

  bool get isConfigured => enabled && (firebase?.isComplete ?? false);

  @override
  List<Object?> get props => [enabled, firebase, vapidKey];
}

enum PushPermissionState { granted, denied, notDetermined, unsupported }

class PushStatus extends Equatable {
  const PushStatus({
    required this.supported,
    required this.configured,
    required this.permission,
    required this.enabled,
  });

  const PushStatus.unsupported()
      : supported = false,
        configured = false,
        permission = PushPermissionState.unsupported,
        enabled = false;

  final bool supported;
  final bool configured;
  final PushPermissionState permission;
  final bool enabled;

  @override
  List<Object?> get props => [supported, configured, permission, enabled];
}
