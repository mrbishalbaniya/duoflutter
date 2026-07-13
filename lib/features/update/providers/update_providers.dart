import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../data/update_local_store.dart';
import '../models/update_models.dart';
import '../repositories/update_repository.dart';
import '../repositories/github_update_repository.dart';
import '../services/update_services.dart';

final updateLocalStoreProvider = Provider<UpdateLocalStore>((ref) {
  return UpdateLocalStore(ref.watch(localStorageProvider).settings);
});

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  return UpdateRepository(ref.watch(dioClientProvider));
});

final githubUpdateRepositoryProvider = Provider<GithubUpdateRepository>((ref) {
  return GithubUpdateRepository();
});

final updateCheckServiceProvider = Provider<UpdateCheckService>((ref) {
  return UpdateCheckService(
    repository: ref.watch(updateRepositoryProvider),
    githubRepository: ref.watch(githubUpdateRepositoryProvider),
    store: ref.watch(updateLocalStoreProvider),
  );
});

final updateDownloadServiceProvider = Provider<UpdateDownloadService>((ref) {
  return UpdateDownloadService();
});

final updateInstallServiceProvider = Provider<UpdateInstallService>((ref) {
  return UpdateInstallService();
});

class UpdateController extends StateNotifier<UpdateUiState> {
  UpdateController(this._ref) : super(const UpdateUiState()) {
    _bootstrap();
  }

  final Ref _ref;

  UpdateCheckService get _check => _ref.read(updateCheckServiceProvider);
  UpdateRepository get _repo => _ref.read(updateRepositoryProvider);
  UpdateDownloadService get _download => _ref.read(updateDownloadServiceProvider);
  UpdateInstallService get _install => _ref.read(updateInstallServiceProvider);
  UpdateLocalStore get _store => _ref.read(updateLocalStoreProvider);

  Future<void> _bootstrap() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final installed = await _check.installedInfo();
      final storage = await _download.folderSizeBytes();
      state = state.copyWith(
        installed: installed,
        storageUsedBytes: storage,
        ignoredVersion: _store.ignoredVersion,
        lastCheckedAt: _store.lastCheckedAt,
      );
    } catch (_) {}
  }

  Future<AppUpdateInfo?> checkForUpdates({bool force = false, bool manual = false}) async {
    if (kIsWeb || !Platform.isAndroid) {
      state = state.copyWith(
        phase: UpdatePhase.upToDate,
        message: 'Updates are only available on Android.',
      );
      return null;
    }

    if (!force && !manual && !_check.shouldAutoCheck()) {
      final cached = _check.cachedVersion();
      if (cached != null) {
        state = state.copyWith(latest: cached, phase: UpdatePhase.upToDate);
      }
      return cached;
    }

    state = state.copyWith(phase: UpdatePhase.checking, clearError: true, clearMessage: true);
    try {
      final installed = await _check.installedInfo();
      final latest = await _check.checkForUpdates(force: force);
      var history = const <AppUpdateInfo>[];
      try {
        history = await _repo.fetchHistory();
      } catch (_) {}
      final storage = await _download.folderSizeBytes();

      final shouldPrompt = _check.shouldPrompt(
        latest,
        ignoredVersion: _store.ignoredVersion,
      );

      state = state.copyWith(
        installed: installed,
        latest: latest,
        history: history,
        storageUsedBytes: storage,
        lastCheckedAt: DateTime.now(),
        phase: latest.updateAvailable && shouldPrompt ? UpdatePhase.available : UpdatePhase.upToDate,
        message: latest.updateAvailable
            ? 'Duo ${latest.latestVersion} is available.'
            : 'You are on the latest version.',
      );
      return latest;
    } catch (e) {
      state = state.copyWith(
        phase: UpdatePhase.failed,
        error: _formatCheckError(e),
      );
      return null;
    }
  }

  String _formatCheckError(Object error) {
    if (error is ApiException) {
      if (kDebugMode) {
        debugPrint(
          '[UpdateCheck] HTTP ${error.statusCode ?? '?'}: ${error.message}',
        );
      }
      final status = error.statusCode;
      if (status == 503 || status == 500) {
        return 'Unable to check for updates at the moment. Please try again later.';
      }
      if (status == 404) {
        return 'Update service is not available on the server yet. Please try again later.';
      }
      return error.message;
    }

    final message = error.toString();
    if (kDebugMode) {
      debugPrint('[UpdateCheck] $message');
    }
    if (message.contains('404')) {
      return 'Update service is not available on the server yet. Please try again later.';
    }
    if (message.contains('500') || message.contains('503')) {
      return 'Unable to check for updates at the moment. Please try again later.';
    }
    return 'Unable to check for updates at the moment. Please try again later.';
  }

  Future<void> ignoreCurrentVersion() async {
    final latest = state.latest;
    if (latest == null) return;
    await _store.setIgnoredVersion(latest.latestVersion);
    state = state.copyWith(
      ignoredVersion: latest.latestVersion,
      phase: UpdatePhase.upToDate,
      message: 'Update postponed.',
    );
  }

  Future<void> startDownload() async {
    final latest = state.latest;
    if (latest == null || latest.apkUrl.isEmpty) {
      state = state.copyWith(error: 'No update package available.');
      return;
    }

    state = state.copyWith(
      phase: UpdatePhase.downloading,
      progress: 0,
      downloadedBytes: 0,
      totalBytes: latest.fileSizeBytes,
      clearError: true,
      message: 'Downloading update…',
    );

    try {
      if (latest.versionId != null) {
        await _repo.trackDownload(latest.versionId!);
      }

      final path = await _download.downloadApk(
        update: latest,
        onProgress: ({
          required downloaded,
          required total,
          required progress,
          required speedBps,
          required etaSeconds,
        }) {
          state = state.copyWith(
            downloadedBytes: downloaded,
            totalBytes: total,
            progress: progress.clamp(0, 1),
            downloadSpeedBps: speedBps,
            etaSeconds: etaSeconds,
          );
        },
      );

      state = state.copyWith(phase: UpdatePhase.verifying, message: 'Verifying download…');
      await _download.verifySha256(filePath: path, expectedChecksum: latest.checksumSha256);

      final storage = await _download.folderSizeBytes();
      state = state.copyWith(
        phase: UpdatePhase.readyToInstall,
        localApkPath: path,
        progress: 1,
        storageUsedBytes: storage,
        message: 'Download complete. Ready to install.',
      );
    } on UpdateDownloadException catch (e) {
      state = state.copyWith(phase: UpdatePhase.failed, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: UpdatePhase.failed, error: e.toString());
    }
  }

  void pauseDownload() {
    _download.pause();
    state = state.copyWith(phase: UpdatePhase.paused, message: 'Download paused.');
  }

  void resumeDownload() {
    _download.resume();
    state = state.copyWith(phase: UpdatePhase.downloading, message: 'Resuming download…');
  }

  void cancelDownload() {
    _download.cancel();
    state = state.copyWith(
      phase: UpdatePhase.available,
      progress: 0,
      message: 'Download cancelled.',
    );
  }

  Future<void> installDownloadedApk() async {
    final path = state.localApkPath;
    if (path == null) {
      state = state.copyWith(error: 'No downloaded APK found.');
      return;
    }

    state = state.copyWith(phase: UpdatePhase.installing, message: 'Opening installer…');
    try {
      await _install.installApk(path);
      state = state.copyWith(message: 'Follow the system prompts to finish installation.');
    } on UpdateInstallException catch (e) {
      state = state.copyWith(phase: UpdatePhase.failed, error: e.message);
    } catch (e) {
      state = state.copyWith(phase: UpdatePhase.failed, error: e.toString());
    }
  }

  Future<void> clearUpdateCache() async {
    await _download.clearDownloads();
    final storage = await _download.folderSizeBytes();
    state = state.copyWith(
      storageUsedBytes: storage,
      clearLocalApk: true,
      message: 'Update cache cleared.',
    );
  }

  Future<AppUpdateInfo?> prepareGithubDownload() async {
    if (kIsWeb || !Platform.isAndroid) {
      state = state.copyWith(
        phase: UpdatePhase.failed,
        error: 'APK download is only available on Android.',
      );
      return null;
    }

    state = state.copyWith(
      phase: UpdatePhase.checking,
      clearError: true,
      clearMessage: true,
      message: 'Fetching latest release from GitHub…',
    );

    try {
      final installed = await _check.installedInfo();
      final latest = await _check.checkGithubRelease(allowRedownload: true);
      await _store.setLastCheckedAt(DateTime.now());

      state = state.copyWith(
        installed: installed,
        latest: latest,
        lastCheckedAt: DateTime.now(),
        phase: UpdatePhase.available,
        message: 'Duo ${latest.latestVersion} is ready to download.',
      );
      return latest;
    } catch (e) {
      state = state.copyWith(
        phase: UpdatePhase.failed,
        error: 'Could not reach GitHub releases. Check your connection and try again.',
      );
      return null;
    }
  }

  Future<void> downloadLatestGithubRelease() async {
    final latest = await prepareGithubDownload();
    if (latest == null) return;
    await startDownload();
  }
}

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateUiState>((ref) {
  return UpdateController(ref);
});
