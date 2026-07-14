import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/security_models.dart';
import '../services/device_fingerprint_service.dart';

class SecurityRepository {
  SecurityRepository({
    required DioClient client,
    required DeviceFingerprintService deviceService,
    required TokenStorage tokenStorage,
  })  : _client = client,
        _deviceService = deviceService,
        _tokenStorage = tokenStorage;

  final DioClient _client;
  final DeviceFingerprintService _deviceService;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> _devicePayload([Map<String, dynamic>? extra]) async {
    final fp = await _deviceService.getFingerprint();
    return {...fp.toPayload(), ...?extra};
  }

  Future<SecurityOverview> getOverview() async {
    final payload = await _devicePayload();
    final refresh = await _tokenStorage.getRefreshToken();
    final response = await _client.get<Map<String, dynamic>>(
      '/security/overview/',
      queryParameters: {
        'device_id': payload['device_id'],
        if (refresh != null) 'refresh_token': refresh,
      },
    );
    return SecurityOverview.fromJson(response.data!);
  }

  Future<bool> verifyPassword(String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/password/verify/',
      data: {'password': password},
    );
    return response.data?['verified'] as bool? ?? false;
  }

  Future<TotpSetupData> setupTotp(String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/2fa/setup/totp/',
      data: {'password': password},
    );
    return TotpSetupData.fromJson(response.data!);
  }

  Future<void> setupEmail2fa(String password) async {
    await _client.post('/security/2fa/setup/email/', data: {'password': password});
  }

  Future<List<String>> enable2fa(String code) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/2fa/enable/',
      data: {'code': code},
    );
    return (response.data?['backup_codes'] as List<dynamic>? ?? []).cast<String>();
  }

  Future<void> disable2fa(String password) async {
    await _client.post('/security/2fa/disable/', data: {'password': password});
  }

  Future<List<String>> regenerateBackupCodes(String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/2fa/backup-codes/regenerate/',
      data: {'password': password},
    );
    return (response.data?['codes'] as List<dynamic>? ?? []).cast<String>();
  }

  Future<int> backupCodesRemaining() async {
    final response = await _client.get<Map<String, dynamic>>('/security/2fa/backup-codes/');
    return response.data?['remaining'] as int? ?? 0;
  }

  Future<List<UserDevice>> listDevices() async {
    final payload = await _devicePayload();
    final response = await _client.get<Map<String, dynamic>>(
      '/security/devices/',
      queryParameters: {'device_id': payload['device_id']},
    );
    return (response.data?['devices'] as List<dynamic>? ?? [])
        .map((e) => UserDevice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserDevice> renameDevice(int id, String name) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '/security/devices/$id/rename/',
      data: await _devicePayload({'device_name': name}),
    );
    return UserDevice.fromJson(response.data!);
  }

  Future<UserDevice> trustDevice(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/devices/$id/trust/',
      data: await _devicePayload(),
    );
    return UserDevice.fromJson(response.data!);
  }

  Future<UserDevice> untrustDevice(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/devices/$id/untrust/',
      data: await _devicePayload(),
    );
    return UserDevice.fromJson(response.data!);
  }

  Future<void> logoutDevice(int id) async {
    final refresh = await _tokenStorage.getRefreshToken();
    await _client.post(
      '/security/devices/$id/logout/',
      data: await _devicePayload({'refresh_token': refresh}),
    );
  }

  Future<int> logoutAllDevices({required bool keepCurrent}) async {
    final refresh = await _tokenStorage.getRefreshToken();
    final response = await _client.post<Map<String, dynamic>>(
      '/security/devices/logout-all/',
      data: await _devicePayload({
        'keep_current': keepCurrent,
        'refresh_token': refresh,
      }),
    );
    return response.data?['revoked'] as int? ?? 0;
  }

  Future<({List<LoginHistoryEntry> results, int total})> loginHistory({
    String search = '',
    bool? success,
    int page = 1,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/security/login-history/',
      queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (success != null) 'success': success.toString(),
        'page': page,
      },
    );
    final data = response.data!;
    final results = (data['results'] as List<dynamic>? ?? [])
        .map((e) => LoginHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return (results: results, total: data['total'] as int? ?? results.length);
  }

  Future<List<SecurityEvent>> listEvents({bool unreadOnly = false}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/security/events/',
      queryParameters: {if (unreadOnly) 'unread': 'true'},
    );
    return (response.data?['events'] as List<dynamic>? ?? [])
        .map((e) => SecurityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markEventRead(int id) async {
    await _client.post('/security/events/$id/read/');
  }

  Future<int> markAllEventsRead() async {
    final response = await _client.post<Map<String, dynamic>>('/security/events/read-all/');
    return response.data?['marked'] as int? ?? 0;
  }

  Future<void> deleteEvent(int id) async {
    await _client.delete('/security/events/$id/read/');
  }

  Future<String> enableBiometric(String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/biometric/enable/',
      data: await _devicePayload({'password': password}),
    );
    return response.data?['token'] as String;
  }

  Future<void> disableBiometric(String password) async {
    await _client.post('/security/biometric/disable/', data: {'password': password});
  }

  Future<bool> biometricStatus() async {
    final payload = await _devicePayload();
    final response = await _client.get<Map<String, dynamic>>(
      '/security/biometric/status/',
      queryParameters: {'device_id': payload['device_id']},
    );
    return response.data?['enabled'] as bool? ?? false;
  }

  Future<({String access, String refresh})> biometricLogin(String token) async {
    final payload = await _devicePayload();
    final response = await _client.post<Map<String, dynamic>>(
      '/security/biometric/login/',
      data: {'token': token, 'device_id': payload['device_id']},
    );
    final data = response.data!;
    return (access: data['access'] as String, refresh: data['refresh'] as String);
  }

  Future<({String access, String refresh})> complete2faLogin({
    required String challengeToken,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/2fa/login/',
      data: await _devicePayload({
        'challenge_token': challengeToken,
        'code': code,
      }),
    );
    final data = response.data!;
    return (access: data['access'] as String, refresh: data['refresh'] as String);
  }

  Future<void> send2faLoginOtp(String challengeToken) async {
    await _client.post('/security/2fa/login/send-otp/', data: {
      'challenge_token': challengeToken,
    });
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post<Map<String, dynamic>>('/auth/password/change/', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    return response.data?['message'] as String? ?? 'Password updated successfully.';
  }
}
