import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/verification_models.dart';
import '../verification_controller.dart';
import '../services/verification_camera_service.dart';
import '../services/verification_image_service.dart';
final verificationImageServiceProvider = Provider<VerificationImageService>((ref) {
  return VerificationImageService();
});

final verificationCameraServiceProvider = Provider.autoDispose<VerificationCameraService>((ref) {
  final service = VerificationCameraService();
  ref.onDispose(service.dispose);
  return service;
});

final verificationControllerProvider =
    StateNotifierProvider.autoDispose<VerificationController, VerificationState>((ref) {
  return VerificationController(ref);
});

final verificationSessionPollProvider = StreamProvider.autoDispose.family<VerificationSessionDetail, String>(
  (ref, sessionToken) async* {
    final repo = ref.watch(verificationRepositoryProvider);
    while (true) {
      try {
        yield await repo.getVerificationSession(sessionToken);
      } catch (_) {
        // Keep polling; UI shows poll error from local state in cross-device widget.
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  },
);
