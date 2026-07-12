import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.raw});

  final String message;
  final int? statusCode;
  final dynamic raw;

  @override
  String toString() => message;

  static ApiException fromDio(DioException error) {
    final response = error.response;
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      final detail = data['detail'] ?? data['error'];
      if (detail is String && detail.isNotEmpty) {
        return ApiException(detail, statusCode: response.statusCode, raw: data);
      }
      if (detail is List && detail.isNotEmpty) {
        return ApiException(detail.first.toString(), statusCode: response.statusCode, raw: data);
      }
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          return ApiException(
            '${entry.key}: ${(entry.value as List).first}',
            statusCode: response.statusCode,
            raw: data,
          );
        }
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException('Request timed out. Please try again.');
    }
    if (error.type == DioExceptionType.connectionError) {
      return ApiException('Cannot reach the server. Check your connection.');
    }
    final status = response?.statusCode;
    if (status == 404) {
      final path = error.requestOptions.path;
      if (path.contains('wallet')) {
        return ApiException(
          'Wallet service not found on the server (404). The backend may need to be redeployed.',
          statusCode: 404,
        );
      }
      return ApiException('Not found (404)', statusCode: 404);
    }
    return ApiException(
      'Network error (${status ?? error.type.name})',
      statusCode: status,
    );
  }
}
