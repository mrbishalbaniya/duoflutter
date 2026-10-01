import '../core/network/dio_client.dart';
import '../core/media/media_url.dart' show localizeMediaUrl;

/// Matches DuoBackend `chat.serializers.BlockedUserSerializer`.
class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.photoUrl,
    this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        photoUrl: localizeMediaUrl(json['photo_url'] as String? ?? ''),
        blockedAt: DateTime.tryParse(json['blocked_at'] as String? ?? '')?.toLocal(),
      );

  final int id;
  final String username;
  final String fullName;
  final String photoUrl;
  final DateTime? blockedAt;

  String get displayName => fullName.isNotEmpty ? fullName : username;
}

/// Support request categories accepted by `/support/requests/`.
enum SupportRequestCategory {
  contact('contact'),
  bug('bug');

  const SupportRequestCategory(this.apiValue);
  final String apiValue;
}

/// Account-level endpoints that mirror the web app's settings pages:
/// blocked users, account deletion, and support requests.
class SupportRepository {
  SupportRepository(this._client);

  final DioClient _client;

  Future<List<BlockedUser>> getBlockedUsers() async {
    final response = await _client.get<Map<String, dynamic>>('/chat/blocked/');
    final list = response.data?['blocked_users'] as List<dynamic>? ?? const [];
    return list.whereType<Map<String, dynamic>>().map(BlockedUser.fromJson).toList();
  }

  Future<void> unblockUser(int userId) async {
    await _client.post('/chat/blocked/$userId/unblock/');
  }

  Future<void> deleteAccount({required String password, String reason = ''}) async {
    await _client.post('/auth/delete-account/', data: {
      'password': password,
      'reason': reason,
    });
  }

  Future<void> submitSupportRequest({
    required SupportRequestCategory category,
    required String message,
    String subject = '',
    String contactEmail = '',
    String deviceInfo = '',
  }) async {
    await _client.post('/support/requests/', data: {
      'category': category.apiValue,
      'message': message,
      if (subject.isNotEmpty) 'subject': subject,
      if (contactEmail.isNotEmpty) 'contact_email': contactEmail,
      if (deviceInfo.isNotEmpty) 'device_info': deviceInfo,
    });
  }
}
