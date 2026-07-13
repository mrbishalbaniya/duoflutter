import 'package:dio/dio.dart';

/// Retries transient network failures with exponential backoff (GET/HEAD only).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _retryable = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retry_attempt'] as int?) ?? 0;

    if (attempt >= maxRetries || !_retryable.contains(err.type)) {
      handler.next(err);
      return;
    }

    final method = options.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') {
      handler.next(err);
      return;
    }

    final delay = baseDelay * (1 << attempt);
    await Future<void>.delayed(delay);

    try {
      final next = options.copyWith(
        extra: {...options.extra, 'retry_attempt': attempt + 1},
      );
      final response = await _dio.fetch<dynamic>(next);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
