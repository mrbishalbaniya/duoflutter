import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'retry_interceptor.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _refreshing = false;
  Future<void>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuthRefresh'] == true) {
      handler.next(options);
      return;
    }
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
      try {
        await _refreshFuture;
        await _retryRequest(err.requestOptions, handler, err);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    _refreshing = true;
    _refreshFuture = _refreshTokens();
    try {
      await _refreshFuture;
      await _retryRequest(err.requestOptions, handler, err);
    } catch (_) {
      handler.next(err);
    } finally {
      _refreshing = false;
      _refreshFuture = null;
    }
  }

  Future<void> _refreshTokens() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw StateError('no_refresh_token');
    }

    final refreshResponse = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh/',
      data: {'refresh': refresh},
      options: Options(extra: {'skipAuthRefresh': true}),
    );

    final access = refreshResponse.data?['access'] as String?;
    if (access == null) {
      await _tokenStorage.clear();
      throw StateError('refresh_failed');
    }
    await _tokenStorage.saveAccessToken(access);
  }

  Future<void> _retryRequest(
    RequestOptions options,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      handler.next(original);
      return;
    }
    options.headers['Authorization'] = 'Bearer $token';
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _tokenStorage.clear();
      }
      handler.next(original);
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

typedef NetworkStatusCallback = void Function();

class DioClient {
  DioClient({
    required TokenStorage tokenStorage,
    NetworkStatusCallback? onNetworkOnline,
    NetworkStatusCallback? onNetworkOffline,
  })  : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 25),
            sendTimeout: const Duration(seconds: 25),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.addAll([
      AuthInterceptor(dio: dio, tokenStorage: tokenStorage),
      RetryInterceptor(dio: dio),
      if (onNetworkOnline != null && onNetworkOffline != null)
        NetworkStatusInterceptor(onNetworkOnline, onNetworkOffline),
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

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    try {
      return await dio.delete<T>(path, data: data);
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

class NetworkStatusInterceptor extends Interceptor {
  NetworkStatusInterceptor(this._onOnline, this._onOffline);

  final NetworkStatusCallback _onOnline;
  final NetworkStatusCallback _onOffline;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _onOnline();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      _onOffline();
    }
    handler.next(err);
  }
}
