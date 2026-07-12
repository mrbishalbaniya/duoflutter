import '../core/models/user_models.dart';
import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository({
    required DioClient client,
    required TokenStorage tokenStorage,
  })  : _client = client,
        _tokenStorage = tokenStorage;

  final DioClient _client;
  final TokenStorage _tokenStorage;

  Future<DuoUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login/',
      data: {'username': email.trim(), 'password': password},
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
      await _client.post('/auth/logout/');
    } finally {
      await _tokenStorage.clear();
    }
  }
}
