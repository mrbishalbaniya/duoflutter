import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import 'push_debug_log.dart';

/// Sends a chat reply from a notification action (including background isolate).
class NotificationReplyHandler {
  NotificationReplyHandler({
    TokenStorage? tokenStorage,
    Dio? dio,
  })  : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl.endsWith('/')
                    ? AppConfig.apiBaseUrl
                    : '${AppConfig.apiBaseUrl}/',
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
              ),
            );

  final TokenStorage _tokenStorage;
  final Dio _dio;

  /// Returns true when the message was accepted by the API.
  Future<bool> sendReply({
    required String conversationId,
    required String text,
  }) async {
    final content = text.trim();
    if (conversationId.isEmpty || content.isEmpty) {
      PushDebugLog.warn('Reply aborted — missing conversation or empty text');
      return false;
    }

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      PushDebugLog.warn('Reply aborted — no access token');
      return false;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'chat/conversations/$conversationId/messages/',
        data: {
          'content': content,
          'image_url': '',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final ok = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      PushDebugLog.info(
        ok
            ? 'Notification reply sent to $conversationId'
            : 'Notification reply failed status=${response.statusCode}',
      );
      return ok;
    } catch (e) {
      PushDebugLog.error('Notification reply failed', e);
      return false;
    }
  }
}
