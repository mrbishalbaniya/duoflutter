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
    return ApiException(
      'Network error (${response?.statusCode ?? error.type.name})',
      statusCode: response?.statusCode,
    );
  }
}
