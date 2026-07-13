import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../models/update_models.dart';
import '../utils/update_utils.dart';

class GithubUpdateRepository {
  GithubUpdateRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                headers: const {
                  'Accept': 'application/vnd.github+json',
                  'User-Agent': 'DuoMobile',
                },
              ),
            );

  final Dio _dio;

  Future<AppUpdateInfo> fetchLatestRelease({
    required InstalledAppInfo installed,
    bool allowRedownload = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(AppConfig.githubReleasesApiUrl);
    final data = response.data ?? const <String, dynamic>{};

    final tag = (data['tag_name'] as String? ?? '0.0.0').trim();
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    final body = (data['body'] as String? ?? '').trim();
    final releaseNotes = body.isEmpty
        ? const <String>['Latest Duo mobile release from GitHub.']
        : body
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(8)
            .toList();

    var fileSizeBytes = 0;
    final assets = data['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = asset['name'] as String? ?? '';
        if (name == 'app-release.apk') {
          fileSizeBytes = asset['size'] as int? ?? 0;
          break;
        }
      }
    }

    final semverNewer = compareSemanticVersions(version, installed.version) > 0;
    final updateAvailable = allowRedownload || semverNewer;

    return AppUpdateInfo(
      latestVersion: version.isEmpty ? installed.version : version,
      minimumVersion: installed.version,
      buildNumber: installed.buildNumber + (semverNewer ? 1 : 0),
      apkUrl: AppConfig.githubLatestApkUrl,
      releaseNotes: releaseNotes,
      forceUpdate: false,
      softUpdate: true,
      emergencyUpdate: false,
      fileSize: fileSizeBytes > 0 ? formatBytes(fileSizeBytes) : 'APK',
      fileSizeBytes: fileSizeBytes,
      checksumSha256: '',
      publishedAt: data['published_at'] as String?,
      channel: 'github',
      platform: 'android',
      updateAvailable: updateAvailable,
      updateBlocked: false,
    );
  }
}
