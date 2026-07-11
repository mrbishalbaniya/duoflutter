import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh')) {
      handler.next(err);
      return;
    }

    if (_refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;
    try {
      final refresh = await _tokenStorage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        handler.next(err);
        return;
      }

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh/',
        data: {'refresh': refresh},
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final access = refreshResponse.data?['access'] as String?;
      if (access == null) {
        await _tokenStorage.clear();
        handler.next(err);
        return;
      }

      await _tokenStorage.saveAccessToken(access);

      final retry = err.requestOptions;
      retry.headers['Authorization'] = 'Bearer $access';
      final response = await _dio.fetch<dynamic>(retry);
      handler.resolve(response);
    } on DioException catch (refreshError) {
      if (refreshError.response?.statusCode == 401) {
        await _tokenStorage.clear();
      }
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
    }
    handler.next(err);
  }
}

class DioClient {
  DioClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, tokenStorage: tokenStorage),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  final TokenStorage _tokenStorage;
  final Dio dio;

  TokenStorage get tokenStorage => _tokenStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    try {
      return await dio.put<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    try {
      return await dio.patch<T>(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> upload<T>(String path, FormData formData) async {
    try {
      return await dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
