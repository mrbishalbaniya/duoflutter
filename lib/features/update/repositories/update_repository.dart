import '../../../core/network/dio_client.dart';
import '../models/update_models.dart';

class UpdateRepository {
  UpdateRepository(this._client);

  final DioClient _client;

  Future<AppUpdateInfo> checkVersion({
    required String installedVersion,
    required int buildNumber,
    String platform = 'android',
    String channel = 'stable',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/app/version/',
      queryParameters: {
        'platform': platform,
        'channel': channel,
        'installed_version': installedVersion,
        'build_number': buildNumber,
      },
    );
    return AppUpdateInfo.fromJson(response.data ?? const {});
  }

  Future<List<AppUpdateInfo>> fetchHistory({
    String platform = 'android',
    String channel = 'stable',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/app/version/history/',
      queryParameters: {'platform': platform, 'channel': channel},
    );
    final results = response.data?['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AppUpdateInfo.fromJson({
            'latest_version': item['version'],
            'minimum_version': item['version'],
            'build_number': item['build_number'],
            'release_notes': item['release_notes'],
            'release_title': item['release_title'] ?? item['title'],
            'title': item['title'] ?? item['release_title'],
            'checksum_sha256': item['checksum_sha256'],
            'file_size': item['file_size'],
            'published_at': item['published_at'],
            'platform': item['platform'],
            'channel': item['channel'],
            'apk_url': '',
            'update_available': false,
          }),
        )
        .toList();
  }

  Future<void> trackDownload(int versionId) async {
    await _client.post<Map<String, dynamic>>(
      '/app/version/download/',
      data: {'version_id': versionId},
    );
  }
}
