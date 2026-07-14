import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../models/update_models.dart';
import '../utils/release_notes.dart';
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
    final releaseNotes = sanitizeReleaseNotes(body);
    final releaseTitle = resolveReleaseTitle(
      data['name'] as String?,
      version: version.isEmpty ? installed.version : version,
    );

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
      releaseTitle: releaseTitle,
      releaseNotes: releaseNotes,
      forceUpdate: false,
      softUpdate: true,
      emergencyUpdate: false,
      fileSize: fileSizeBytes > 0 ? formatBytes(fileSizeBytes) : '',
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
