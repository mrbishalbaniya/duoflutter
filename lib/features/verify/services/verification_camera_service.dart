import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VerificationCameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<String?> initialize() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return 'Camera permission is required for verification.';
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        return 'No camera found on this device.';
      }

      final front = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _controller?.dispose();
      _controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Camera init failed: $e');
      await dispose();
      return 'Could not start the camera. Try again or use another device.';
    }
  }

  Future<XFile?> capturePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.isTakingPicture) {
      return null;
    }
    try {
      return await ctrl.takePicture();
    } catch (e) {
      if (kDebugMode) debugPrint('Capture failed: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    final ctrl = _controller;
    _controller = null;
    if (ctrl != null) {
      await ctrl.dispose();
    }
  }
}
