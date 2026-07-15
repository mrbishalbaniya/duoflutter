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
    final parsed = _parseTag(tag, name: data['name'] as String?);
    final version = parsed.$1;
    final buildNumber = parsed.$2;
    final body = (data['body'] as String? ?? '').trim();
    final releaseNotes = sanitizeReleaseNotes(body);
    final releaseTitle = resolveReleaseTitle(
      data['name'] as String?,
      version: version.isEmpty ? installed.version : version,
    );

    var fileSizeBytes = 0;
    var apkDownloadUrl = AppConfig.githubLatestApkUrl;
    final assets = data['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is! Map) continue;
        final name = asset['name'] as String? ?? '';
        if (name == 'app-release.apk') {
          fileSizeBytes = asset['size'] as int? ?? 0;
          final browserUrl = asset['browser_download_url'] as String?;
          if (browserUrl != null && browserUrl.isNotEmpty) {
            apkDownloadUrl = browserUrl;
          }
          break;
        }
      }
    }

    final effectiveVersion = version.isEmpty ? installed.version : version;
    final semverNewer = compareSemanticVersions(effectiveVersion, installed.version) > 0;
    final buildNewer = buildNumber > installed.buildNumber;
    final updateAvailable = allowRedownload || buildNewer || semverNewer;

    return AppUpdateInfo(
      latestVersion: effectiveVersion,
      minimumVersion: installed.version,
      buildNumber: buildNumber > 0 ? buildNumber : installed.buildNumber + (semverNewer ? 1 : 0),
      apkUrl: apkDownloadUrl,
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

  /// Parses tags like `v1.0.0-build.40` → (1.0.0, 40).
  (String, int) _parseTag(String tag, {String? name}) {
    final cleaned = tag.trim();
    final match = RegExp(
      r'^v?(?<version>\d+(?:\.\d+){1,3})(?:[-_+]?build[.\-_]?(?<build>\d+))?$',
      caseSensitive: false,
    ).firstMatch(cleaned);

    var version = match?.namedGroup('version') ?? '';
    var build = int.tryParse(match?.namedGroup('build') ?? '') ?? 0;

    if (version.isEmpty) {
      version = cleaned.replaceFirst(RegExp(r'^v'), '').split('-').first.trim();
      if (version.isEmpty) version = '0.0.0';
    }

    if (build <= 0 && name != null) {
      final nameMatch = RegExp(r'\bbuild\s*[#:]?\s*(\d+)\b', caseSensitive: false).firstMatch(name);
      build = int.tryParse(nameMatch?.group(1) ?? '') ?? 0;
    }
    if (build <= 0) build = 1;
    return (version, build);
  }
}
