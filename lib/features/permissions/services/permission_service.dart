import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/permission_models.dart';

class PermissionService {
  Future<Map<DuoPermissionType, DuoPermissionStatus>> checkAll() async {
    if (kIsWeb) return _unsupportedAll();

    final results = <DuoPermissionType, DuoPermissionStatus>{};
    for (final item in permissionSetupOrder) {
      results[item.type] = await check(item.type);
    }
    return results;
  }

  Future<DuoPermissionStatus> check(DuoPermissionType type) async {
    if (kIsWeb) return DuoPermissionStatus.unsupported;

    return switch (type) {
      DuoPermissionType.notifications => _checkNotifications(),
      DuoPermissionType.camera => _map(await Permission.camera.status),
      DuoPermissionType.microphone => _map(await Permission.microphone.status),
      DuoPermissionType.photos => _checkPhotos(),
      DuoPermissionType.location => _checkLocation(),
      DuoPermissionType.contacts => _map(await Permission.contacts.status),
    };
  }

  Future<DuoPermissionStatus> request(DuoPermissionType type) async {
    if (kIsWeb) return DuoPermissionStatus.unsupported;

    return switch (type) {
      DuoPermissionType.notifications => _requestNotifications(),
      DuoPermissionType.camera => _map(await Permission.camera.request()),
      DuoPermissionType.microphone => _map(await Permission.microphone.request()),
      DuoPermissionType.photos => _requestPhotos(),
      DuoPermissionType.location => _requestLocation(),
      DuoPermissionType.contacts => _map(await Permission.contacts.request()),
    };
  }

  Future<void> openSystemSettings() => openAppSettings();

  Future<DuoPermissionStatus> _checkNotifications() async {
    if (Platform.isAndroid) {
      return _map(await Permission.notification.status);
    }
    if (Platform.isIOS && Firebase.apps.isNotEmpty) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return _mapFirebase(settings.authorizationStatus);
    }
    return _map(await Permission.notification.status);
  }

  Future<DuoPermissionStatus> _requestNotifications() async {
    if (Platform.isAndroid) {
      return _map(await Permission.notification.request());
    }
    if (Firebase.apps.isNotEmpty) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return _mapFirebase(settings.authorizationStatus);
    }
    return _map(await Permission.notification.request());
  }

  Future<DuoPermissionStatus> _checkPhotos() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      return _mergeMedia(_map(photos), _map(videos));
    }
    return _map(await Permission.photos.status);
  }

  Future<DuoPermissionStatus> _requestPhotos() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      final videos = await Permission.videos.request();
      final merged = _mergeMedia(_map(photos), _map(videos));
      if (merged != DuoPermissionStatus.denied && merged != DuoPermissionStatus.notDetermined) {
        return merged;
      }
      return _map(await Permission.storage.request());
    }
    return _map(await Permission.photos.request());
  }

  Future<DuoPermissionStatus> _checkLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return DuoPermissionStatus.denied;

    final permission = await Geolocator.checkPermission();
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => DuoPermissionStatus.granted,
      LocationPermission.deniedForever => DuoPermissionStatus.permanentlyDenied,
      LocationPermission.denied => DuoPermissionStatus.denied,
      LocationPermission.unableToDetermine => DuoPermissionStatus.notDetermined,
    };
  }

  Future<DuoPermissionStatus> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return DuoPermissionStatus.denied;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => DuoPermissionStatus.granted,
      LocationPermission.deniedForever => DuoPermissionStatus.permanentlyDenied,
      LocationPermission.denied => DuoPermissionStatus.denied,
      LocationPermission.unableToDetermine => DuoPermissionStatus.notDetermined,
    };
  }

  DuoPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted) return DuoPermissionStatus.granted;
    if (status.isLimited) return DuoPermissionStatus.limited;
    if (status.isPermanentlyDenied) return DuoPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return DuoPermissionStatus.restricted;
    if (status.isDenied) return DuoPermissionStatus.denied;
    return DuoPermissionStatus.notDetermined;
  }

  DuoPermissionStatus _mapFirebase(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => DuoPermissionStatus.granted,
      AuthorizationStatus.provisional => DuoPermissionStatus.limited,
      AuthorizationStatus.denied => DuoPermissionStatus.denied,
      AuthorizationStatus.notDetermined => DuoPermissionStatus.notDetermined,
    };
  }

  DuoPermissionStatus _mergeMedia(DuoPermissionStatus photos, DuoPermissionStatus videos) {
    if (photos.isGranted && videos.isGranted) return DuoPermissionStatus.granted;
    if (photos == DuoPermissionStatus.limited || videos == DuoPermissionStatus.limited) {
      return DuoPermissionStatus.limited;
    }
    if (photos == DuoPermissionStatus.permanentlyDenied || videos == DuoPermissionStatus.permanentlyDenied) {
      return DuoPermissionStatus.permanentlyDenied;
    }
    if (photos == DuoPermissionStatus.granted || videos == DuoPermissionStatus.granted) {
      return DuoPermissionStatus.limited;
    }
    return photos == DuoPermissionStatus.notDetermined ? videos : photos;
  }

  Map<DuoPermissionType, DuoPermissionStatus> _unsupportedAll() {
    return {
      for (final item in permissionSetupOrder) item.type: DuoPermissionStatus.unsupported,
    };
  }
}
