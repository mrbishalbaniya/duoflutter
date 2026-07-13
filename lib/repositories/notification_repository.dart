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
    String deviceLabel = '',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/notifications/devices/',
      data: {
        'token': token,
        'platform': platform,
        if (deviceLabel.isNotEmpty) 'device_label': deviceLabel,
      },
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

  Future<int> unregisterAllDeviceTokens() async {
    final response = await _client.post<Map<String, dynamic>>(
      '/notifications/devices/unregister-all/',
    );
    return response.data?['count'] as int? ?? 0;
  }

  Future<NotificationPreferences> getPreferences() async {
    final response = await _client.get<Map<String, dynamic>>('/notifications/preferences/');
    return NotificationPreferences.fromJson(response.data ?? const {});
  }

  Future<NotificationPreferences> updatePreferences(
    Map<String, bool> changes,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '/notifications/preferences/',
      data: changes,
    );
    return NotificationPreferences.fromJson(response.data ?? const {});
  }

  Future<String> getInboxWsTicket() async {
    final response = await _client.post<Map<String, dynamic>>('/notifications/ws-ticket/');
    final ticket = response.data?['ticket'] as String? ?? '';
    if (ticket.isEmpty) {
      throw StateError('Inbox WebSocket ticket was not returned.');
    }
    return ticket;
  }
}
