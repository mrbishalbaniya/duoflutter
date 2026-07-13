import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Downloads remote avatar bytes for Android large-icon notifications.
class NotificationImageLoader {
  NotificationImageLoader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, Uint8List> _cache = {};

  Future<ByteArrayAndroidBitmap?> largeIcon(String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    try {
      final cached = _cache[trimmed];
      if (cached != null) {
        return ByteArrayAndroidBitmap(cached);
      }
      final response = await _dio.get<List<int>>(
        trimmed,
        options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 8)),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      final data = Uint8List.fromList(bytes);
      _cache[trimmed] = data;
      return ByteArrayAndroidBitmap(data);
    } catch (_) {
      return null;
    }
  }
}
