import '../core/models/user_models.dart';
import '../core/network/dio_client.dart';
import '../core/network/two_factor_exception.dart';
import '../core/storage/token_storage.dart';
import '../features/security/models/security_models.dart';
import '../features/security/services/device_fingerprint_service.dart';

class AuthRepository {
  AuthRepository({
    required DioClient client,
    required TokenStorage tokenStorage,
    DeviceFingerprintService? deviceService,
  })  : _client = client,
        _tokenStorage = tokenStorage,
        _deviceService = deviceService ?? DeviceFingerprintService();

  final DioClient _client;
  final TokenStorage _tokenStorage;
  final DeviceFingerprintService _deviceService;

  Future<Map<String, dynamic>> _devicePayload() async {
    final fp = await _deviceService.getFingerprint();
    return fp.toPayload();
  }

  Future<DuoUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login/',
      data: {
        'username': email.trim(),
        'password': password,
        ...(await _devicePayload()),
      },
    );
    final data = response.data!;
    if (data['requires_2fa'] == true) {
      throw TwoFactorRequiredException(TwoFactorLoginChallenge.fromJson(data));
    }
    await _tokenStorage.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return getMe();
  }

  Future<DuoUser> completeTwoFactorLogin({
    required String challengeToken,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/security/2fa/login/',
      data: {
        'challenge_token': challengeToken,
        'code': code,
        ...(await _devicePayload()),
      },
    );
    final data = response.data!;
    await _tokenStorage.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return getMe();
  }

  Future<void> sendTwoFactorLoginOtp(String challengeToken) async {
    await _client.post('/security/2fa/login/send-otp/', data: {
      'challenge_token': challengeToken,
    });
  }

  Future<DuoUser> loginWithBiometric(String token) async {
    final fp = await _deviceService.getFingerprint();
    final response = await _client.post<Map<String, dynamic>>(
      '/security/biometric/login/',
      data: {'token': token, 'device_id': fp.deviceId},
    );
    final data = response.data!;
    await _tokenStorage.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return getMe();
  }

  Future<DuoUser> loginWithGoogle(String idToken) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/google/',
      data: {'id_token': idToken},
    );
    final data = response.data!;
    await _tokenStorage.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return DuoUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<DuoUser> loginWithGoogleCode({
    required String code,
    required String redirectUri,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/google/',
      data: {
        'code': code,
        'redirect_uri': redirectUri,
      },
    );
    final data = response.data!;
    await _tokenStorage.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return DuoUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<DuoUser> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register/',
      data: {
        'email': email.trim().toLowerCase(),
        'username': email.trim().toLowerCase(),
        'password': password,
        'full_name': fullName,
      },
    );
    final data = response.data!;
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _tokenStorage.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    return DuoUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> sendEmailOtp(String email) async {
    await _client.post('/auth/email/send-otp/', data: {'email': email.trim().toLowerCase()});
  }

  Future<void> verifyEmailOtp({required String email, required String otp}) async {
    await _client.post('/auth/email/verify-otp/', data: {
      'email': email.trim().toLowerCase(),
      'otp': otp,
    });
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/password/forgot/', data: {'email': email.trim().toLowerCase()});
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    await _client.post('/auth/password/reset/', data: {
      'email': email.trim().toLowerCase(),
      'otp': otp,
      'password': password,
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

  Future<DuoUser> getMe() async {
    final response = await _client.get<Map<String, dynamic>>('/auth/me/');
    return DuoUser.fromJson(response.data!);
  }

  Future<bool> hasSession() async {
    final access = await _tokenStorage.getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      final refresh = await _tokenStorage.getRefreshToken();
      final payload = await _devicePayload();
      await _client.post('/auth/logout/', data: {
        if (refresh != null) 'refresh': refresh,
        ...payload,
      });
    } finally {
      await _tokenStorage.clear();
    }
  }
}
