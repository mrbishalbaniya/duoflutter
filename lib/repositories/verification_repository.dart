import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../features/verify/models/verification_models.dart';

class VerificationRepository {
  VerificationRepository(this._client);

  final DioClient _client;

  Future<VerificationStartResponse> startVerification() async {
    final response = await _client.post<Map<String, dynamic>>('/verification/start/');
    return VerificationStartResponse.fromJson(response.data ?? {});
  }

  Future<LivenessStepResponse> submitLivenessStep({
    required String sessionToken,
    required LivenessStep step,
    required File image,
  }) async {
    final formData = FormData.fromMap({
      'session_token': sessionToken,
      'step': livenessStepToApi(step),
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _client.upload<Map<String, dynamic>>('/verification/liveness/', formData);
    return LivenessStepResponse.fromJson(response.data ?? {});
  }

  /// Selfie upload may return 200, 202, or 422 with a status payload in the body.
  Future<VerificationStatusResponse> uploadVerificationSelfie({
    required String sessionToken,
    required File image,
  }) async {
    final formData = FormData.fromMap({
      'session_token': sessionToken,
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split(Platform.pathSeparator).last,
      ),
    });

    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/verification/selfie/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          validateStatus: (status) =>
              status != null && (status < 300 || status == 422 || status == 202),
        ),
      );
      final data = response.data ?? {};
      if (data['status'] == null) {
        throw ApiException(
          data['detail'] as String? ?? 'Selfie verification failed',
          statusCode: response.statusCode,
          raw: data,
        );
      }
      return VerificationStatusResponse.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<VerificationSessionDetail> getVerificationSession(String sessionToken) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/verification/session/',
      queryParameters: {'session_token': sessionToken},
    );
    return VerificationSessionDetail.fromJson(response.data ?? {});
  }

  Future<VerificationHandoffEmailResponse> sendVerificationHandoffEmail({
    String? sessionToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/verification/handoff/email/',
      data: sessionToken != null ? {'session_token': sessionToken} : <String, dynamic>{},
    );
    return VerificationHandoffEmailResponse.fromJson(response.data ?? {});
  }

  Future<VerificationStatusResponse> getVerificationStatus() async {
    final response = await _client.get<Map<String, dynamic>>('/verification/status/');
    return VerificationStatusResponse.fromJson(response.data ?? {});
  }

  Future<List<UserVerificationSession>> getVerificationHistory() async {
    final response = await _client.get<List<dynamic>>('/verification/history/');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(UserVerificationSession.fromJson)
        .toList();
  }
}
