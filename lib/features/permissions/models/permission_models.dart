import 'package:flutter/material.dart';

enum DuoPermissionType {
  notifications,
  camera,
  microphone,
  photos,
  location,
  contacts,
}

enum DuoPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  limited,
  restricted,
  unsupported,
}

extension DuoPermissionStatusX on DuoPermissionStatus {
  bool get isGranted => this == DuoPermissionStatus.granted || this == DuoPermissionStatus.limited;

  String get label => switch (this) {
        DuoPermissionStatus.granted => 'Allowed',
        DuoPermissionStatus.limited => 'Limited',
        DuoPermissionStatus.denied => 'Denied',
        DuoPermissionStatus.permanentlyDenied => 'Blocked',
        DuoPermissionStatus.restricted => 'Restricted',
        DuoPermissionStatus.unsupported => 'Unavailable',
        DuoPermissionStatus.notDetermined => 'Not set',
      };

  Color statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      DuoPermissionStatus.granted => scheme.primary,
      DuoPermissionStatus.limited => scheme.tertiary,
      DuoPermissionStatus.denied || DuoPermissionStatus.permanentlyDenied => scheme.error,
      DuoPermissionStatus.restricted || DuoPermissionStatus.unsupported => scheme.outline,
      DuoPermissionStatus.notDetermined => scheme.onSurfaceVariant,
    };
  }
}

class DuoPermissionDefinition {
  const DuoPermissionDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.benefits,
    required this.icon,
    required this.accent,
    this.optional = false,
    this.allowLabel,
  });

  final DuoPermissionType type;
  final String title;
  final String description;
  final List<String> benefits;
  final IconData icon;
  final Color accent;
  final bool optional;
  final String? allowLabel;
}

const permissionSetupOrder = <DuoPermissionDefinition>[
  DuoPermissionDefinition(
    type: DuoPermissionType.notifications,
    title: 'Push notifications',
    description:
        'Allow Duo to send push notifications on this device for messages, matches, likes, and important alerts.',
    benefits: ['Messages', 'Matches', 'Likes', 'Calls', 'Important alerts'],
    icon: Icons.notifications_active_rounded,
    accent: Color(0xFFE84A7A),
    allowLabel: 'Allow push notifications',
  ),
  DuoPermissionDefinition(
    type: DuoPermissionType.camera,
    title: 'Camera',
    description: 'Take photos and verify your profile so matches know you are real.',
    benefits: ['Profile verification', 'Video calls', 'Photo upload', 'QR scanning'],
    icon: Icons.photo_camera_rounded,
    accent: Color(0xFF8B5CF6),
  ),
  DuoPermissionDefinition(
    type: DuoPermissionType.microphone,
    title: 'Microphone',
    description: 'Record voice messages and join audio or video calls in chat.',
    benefits: ['Voice messages', 'Audio calls', 'Video calls'],
    icon: Icons.mic_rounded,
    accent: Color(0xFF3B82F6),
  ),
  DuoPermissionDefinition(
    type: DuoPermissionType.photos,
    title: 'Photos & Media',
    description: 'Pick photos for your profile and save images you receive in chat.',
    benefits: ['Upload profile photos', 'Send images', 'Save downloaded media'],
    icon: Icons.photo_library_rounded,
    accent: Color(0xFFD4A574),
  ),
  DuoPermissionDefinition(
    type: DuoPermissionType.location,
    title: 'Location',
    description: 'Allow location access to discover nearby people and improve match recommendations.',
    benefits: ['Nearby matches', 'Friends Map', 'Distance calculation'],
    icon: Icons.location_on_rounded,
    accent: Color(0xFF22C55E),
  ),
  DuoPermissionDefinition(
    type: DuoPermissionType.contacts,
    title: 'Contacts',
    description: 'Optionally find friends already on Duo and invite people you know.',
    benefits: ['Find friends', 'Invite contacts'],
    icon: Icons.contacts_rounded,
    accent: Color(0xFFF59E0B),
    optional: true,
  ),
];

class PermissionSetupState {
  const PermissionSetupState({
    this.currentStep = 0,
    this.statuses = const {},
    this.isRequesting = false,
    this.showSuccess = false,
    this.requestingType,
  });

  final int currentStep;
  final Map<DuoPermissionType, DuoPermissionStatus> statuses;
  final bool isRequesting;
  final bool showSuccess;
  final DuoPermissionType? requestingType;

  int get totalSteps => permissionSetupOrder.length;

  DuoPermissionDefinition get currentDefinition => permissionSetupOrder[currentStep.clamp(0, totalSteps - 1)];

  bool get isLastStep => currentStep >= totalSteps - 1;

  int get enabledCount =>
      statuses.values.where((s) => s.isGranted).length;

  PermissionSetupState copyWith({
    int? currentStep,
    Map<DuoPermissionType, DuoPermissionStatus>? statuses,
    bool? isRequesting,
    bool? showSuccess,
    DuoPermissionType? requestingType,
    bool clearRequestingType = false,
  }) {
    return PermissionSetupState(
      currentStep: currentStep ?? this.currentStep,
      statuses: statuses ?? this.statuses,
      isRequesting: isRequesting ?? this.isRequesting,
      showSuccess: showSuccess ?? this.showSuccess,
      requestingType: clearRequestingType ? null : (requestingType ?? this.requestingType),
    );
  }
}

class PermissionManagementState {
  const PermissionManagementState({
    this.statuses = const {},
    this.isRefreshing = false,
  });

  final Map<DuoPermissionType, DuoPermissionStatus> statuses;
  final bool isRefreshing;

  PermissionManagementState copyWith({
    Map<DuoPermissionType, DuoPermissionStatus>? statuses,
    bool? isRefreshing,
  }) {
    return PermissionManagementState(
      statuses: statuses ?? this.statuses,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}
