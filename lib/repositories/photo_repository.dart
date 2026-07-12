import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';

class PhotoUploadResult {
  const PhotoUploadResult({
    required this.success,
    this.imageUrl,
    this.detail,
    this.faceDetected = false,
  });

  final bool success;
  final String? imageUrl;
  final String? detail;
  final bool faceDetected;
}

class PhotoRepository {
  PhotoRepository(this._client);

  final DioClient _client;

  Future<PhotoUploadResult> uploadAndAnalyzePhoto(
    File file, {
    bool isPrimary = false,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
      if (isPrimary) 'is_primary': 'true',
    });

    final response = await _client.upload<Map<String, dynamic>>('/photos/upload/', formData);
    final data = response.data ?? {};
    final analysis = data['analysis'] as Map<String, dynamic>?;
    final faceDetected = analysis?['face_detected'] as bool? ?? false;
    final success = data['success'] as bool? ?? false;
    final imageUrl = data['image_url'] as String?;
    final detail = data['detail'] as String?;

    if (!faceDetected) {
      return const PhotoUploadResult(
        success: false,
        detail: 'No human face detected. Please upload a clear photo showing your face.',
      );
    }

    if (!success || analysis?['status'] == 'REJECTED') {
      final reasons = (analysis?['rejection_reasons'] as List<dynamic>?)?.join('; ');
      return PhotoUploadResult(
        success: false,
        detail: detail ?? reasons ?? 'Photo did not pass verification.',
        faceDetected: faceDetected,
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return const PhotoUploadResult(success: false, detail: 'Photo upload failed.');
    }

    return PhotoUploadResult(success: true, imageUrl: imageUrl, faceDetected: faceDetected);
  }
}

String? getPhotoUploadError(PhotoUploadResult result, {String? fileName}) {
  if (!result.faceDetected) {
    return 'No human face detected. Please upload a clear photo showing your face.';
  }
  if (!result.success) {
    final prefix = fileName != null ? '$fileName: ' : '';
    return '$prefix${result.detail ?? 'Photo verification failed.'}';
  }
  if (result.imageUrl == null || result.imageUrl!.isEmpty) {
    return fileName != null ? 'Failed to upload $fileName.' : 'Photo upload failed.';
  }
  return null;
}
