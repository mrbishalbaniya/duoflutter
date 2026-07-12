import '../core/models/notification_models.dart';
import '../core/network/dio_client.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final DioClient _client;

  Future<PushConfig> getConfig({String platform = 'android'}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/notifications/config/',
      queryParameters: {'platform': platform},
    );
    return PushConfig.fromJson(response.data ?? const {});
  }

  Future<String> registerDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/notifications/devices/',
      data: {'token': token, 'platform': platform},
    );
    return response.data?['detail'] as String? ?? 'Device token registered.';
  }

  Future<String> unregisterDeviceToken(String token) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/notifications/devices/unregister/',
      data: {'token': token},
    );
    return response.data?['detail'] as String? ?? 'Device token removed.';
  }
}
