import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/update_models.dart';
import '../repositories/update_repository.dart';
import '../data/update_local_store.dart';

typedef UpdateDownloadProgress = void Function({
  required int downloaded,
  required int total,
  required double progress,
  required int speedBps,
  required int etaSeconds,
});

class UpdateDownloadService {
  UpdateDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  CancelToken? _cancelToken;
  bool _paused = false;

  Future<String> downloadApk({
    required AppUpdateInfo update,
    required UpdateDownloadProgress onProgress,
    String? resumePath,
    int resumeBytes = 0,
  }) async {
    if (update.apkUrl.isEmpty) {
      throw const UpdateDownloadException('APK URL is missing.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'duo-${update.latestVersion}-b${update.buildNumber}.apk';
    final target = File(resumePath ?? '${dir.path}/updates/$fileName');
    await target.parent.create(recursive: true);

    _cancelToken = CancelToken();
    _paused = false;

    final headers = <String, dynamic>{};
    var downloaded = resumeBytes;
    RandomAccessFile? raf;

    if (resumeBytes > 0 && await target.exists()) {
      headers['Range'] = 'bytes=$resumeBytes-';
      raf = await target.open(mode: FileMode.append);
    } else {
      if (await target.exists()) await target.delete();
      raf = await target.open(mode: FileMode.write);
      downloaded = 0;
    }

    var total = update.fileSizeBytes > 0 ? update.fileSizeBytes : 0;
    var lastTick = DateTime.now();
    var lastDownloaded = downloaded;

    try {
      final response = await _dio.get<ResponseBody>(
        update.apkUrl,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: headers,
          receiveTimeout: const Duration(minutes: 30),
        ),
        cancelToken: _cancelToken,
      );

      final contentRange = response.headers.value('content-range');
      if (contentRange != null && contentRange.contains('/')) {
        final totalPart = contentRange.split('/').last;
        total = int.tryParse(totalPart) ?? total;
      } else {
        final length = response.headers.value('content-length');
        if (length != null) {
          final parsed = int.tryParse(length) ?? 0;
          total = resumeBytes > 0 ? resumeBytes + parsed : parsed;
        }
      }

      await for (final chunk in response.data!.stream) {
        while (_paused) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (_cancelToken?.isCancelled == true) {
            throw const UpdateDownloadException('Download cancelled.');
          }
        }
        await raf.writeFrom(chunk);
        downloaded += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastTick).inMilliseconds;
        if (elapsedMs >= 350) {
          final speed = ((downloaded - lastDownloaded) * 1000 / elapsedMs).round();
          final remaining = total > 0 ? ((total - downloaded) / (speed <= 0 ? 1 : speed)).round() : 0;
          onProgress(
            downloaded: downloaded,
            total: total,
            progress: total > 0 ? downloaded / total : 0,
            speedBps: speed,
            etaSeconds: remaining,
          );
          lastTick = now;
          lastDownloaded = downloaded;
        }
      }

      await raf.close();
      onProgress(
        downloaded: downloaded,
        total: total > 0 ? total : downloaded,
        progress: 1,
        speedBps: 0,
        etaSeconds: 0,
      );
      return target.path;
    } on DioException catch (e) {
      await raf.close();
      if (CancelToken.isCancel(e)) {
        throw const UpdateDownloadException('Download cancelled.');
      }
      throw UpdateDownloadException(e.message ?? 'Download failed.');
    } catch (e) {
      await raf.close();
      if (e is UpdateDownloadException) rethrow;
      throw UpdateDownloadException(e.toString());
    }
  }

  void pause() => _paused = true;
  void resume() => _paused = false;
  void cancel() => _cancelToken?.cancel('cancelled');

  Future<void> verifySha256({
    required String filePath,
    required String expectedChecksum,
  }) async {
    final expected = expectedChecksum.trim().toLowerCase();
    if (expected.isEmpty) return;

    final file = File(filePath);
    if (!await file.exists()) {
      throw const UpdateDownloadException('Downloaded APK not found.');
    }

    final digest = await sha256.bind(file.openRead()).first;
    final actual = digest.toString();
    if (actual != expected) {
      await file.delete();
      throw const UpdateDownloadException('Checksum verification failed. APK was discarded.');
    }
  }

  Future<int> folderSizeBytes() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/updates');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clearDownloads() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/updates');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

class UpdateInstallService {
  Future<void> installApk(String filePath) async {
    if (!Platform.isAndroid) {
      throw const UpdateInstallException('In-app APK install is only supported on Android.');
    }

    if (!await File(filePath).exists()) {
      throw const UpdateInstallException('APK file not found.');
    }

    final status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      final result = await Permission.requestInstallPackages.request();
      if (!result.isGranted) {
        throw const UpdateInstallException(
          'Allow installs from this app in Settings → Install unknown apps.',
        );
      }
    }

    final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      throw UpdateInstallException(result.message);
    }
  }
}

class UpdateCheckService {
  UpdateCheckService({
    required UpdateRepository repository,
    required UpdateLocalStore store,
  })  : _repository = repository,
        _store = store;

  final UpdateRepository _repository;
  final UpdateLocalStore _store;

  static const checkInterval = Duration(hours: 24);

  Future<InstalledAppInfo> installedInfo() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledAppInfo(
      version: info.version,
      buildNumber: int.tryParse(info.buildNumber) ?? 0,
      packageName: info.packageName,
    );
  }

  bool shouldAutoCheck() {
    final last = _store.lastCheckedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= checkInterval;
  }

  Future<AppUpdateInfo> checkForUpdates({bool force = false}) async {
    final installed = await installedInfo();
    final latest = await _repository.checkVersion(
      installedVersion: installed.version,
      buildNumber: installed.buildNumber,
    );

    await _store.setLastCheckedAt(DateTime.now());
    await _store.setCachedVersion({
      'latest_version': latest.latestVersion,
      'build_number': latest.buildNumber,
      'apk_url': latest.apkUrl,
      'release_notes': latest.releaseNotes,
      'checksum_sha256': latest.checksumSha256,
      'file_size_bytes': latest.fileSizeBytes,
      'update_available': latest.updateAvailable,
      'update_blocked': latest.updateBlocked,
      'id': latest.versionId,
    });

    return latest;
  }

  bool shouldPrompt(AppUpdateInfo latest, {String? ignoredVersion}) {
    if (!latest.updateAvailable || latest.apkUrl.isEmpty) return false;
    if (latest.updateBlocked || latest.forceUpdate || latest.emergencyUpdate) return true;
    if (ignoredVersion != null && ignoredVersion == latest.latestVersion) return false;
    return true;
  }

  AppUpdateInfo? cachedVersion() {
    final raw = _store.cachedVersion;
    if (raw == null) return null;
    return AppUpdateInfo.fromJson(raw);
  }
}

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UpdateInstallException implements Exception {
  const UpdateInstallException(this.message);
  final String message;

  @override
  String toString() => message;
}
