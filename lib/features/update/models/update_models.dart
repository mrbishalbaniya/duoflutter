import 'package:equatable/equatable.dart';

class AppUpdateInfo extends Equatable {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.minimumVersion,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.softUpdate,
    required this.emergencyUpdate,
    required this.fileSize,
    required this.fileSizeBytes,
    required this.checksumSha256,
    this.publishedAt,
    this.channel = 'stable',
    this.platform = 'android',
    this.updateAvailable = false,
    this.updateBlocked = false,
    this.versionId,
    this.downloadCount = 0,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final notes = json['release_notes'];
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      minimumVersion: json['minimum_version'] as String? ?? '0.0.0',
      buildNumber: json['build_number'] as int? ?? 0,
      apkUrl: json['apk_url'] as String? ?? '',
      releaseNotes: notes is List ? notes.map((e) => e.toString()).toList() : const [],
      forceUpdate: json['force_update'] as bool? ?? false,
      softUpdate: json['soft_update'] as bool? ?? true,
      emergencyUpdate: json['emergency_update'] as bool? ?? false,
      fileSize: json['file_size'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      checksumSha256: (json['checksum_sha256'] as String? ?? '').toLowerCase(),
      publishedAt: json['published_at'] as String?,
      channel: json['channel'] as String? ?? 'stable',
      platform: json['platform'] as String? ?? 'android',
      updateAvailable: json['update_available'] as bool? ?? false,
      updateBlocked: json['update_blocked'] as bool? ?? false,
      versionId: json['id'] as int?,
      downloadCount: json['download_count'] as int? ?? 0,
    );
  }

  final String latestVersion;
  final String minimumVersion;
  final int buildNumber;
  final String apkUrl;
  final List<String> releaseNotes;
  final bool forceUpdate;
  final bool softUpdate;
  final bool emergencyUpdate;
  final String fileSize;
  final int fileSizeBytes;
  final String checksumSha256;
  final String? publishedAt;
  final String channel;
  final String platform;
  final bool updateAvailable;
  final bool updateBlocked;
  final int? versionId;
  final int downloadCount;

  bool get canSkip => softUpdate && !forceUpdate && !emergencyUpdate && !updateBlocked;

  @override
  List<Object?> get props => [
        latestVersion,
        buildNumber,
        apkUrl,
        updateAvailable,
        updateBlocked,
        checksumSha256,
      ];
}

class InstalledAppInfo extends Equatable {
  const InstalledAppInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });

  final String version;
  final int buildNumber;
  final String packageName;

  @override
  List<Object?> get props => [version, buildNumber, packageName];
}

enum UpdatePhase {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  paused,
  verifying,
  readyToInstall,
  installing,
  failed,
}

class UpdateUiState extends Equatable {
  const UpdateUiState({
    this.phase = UpdatePhase.idle,
    this.installed,
    this.latest,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.downloadSpeedBps = 0,
    this.etaSeconds = 0,
    this.localApkPath,
    this.message,
    this.error,
    this.lastCheckedAt,
    this.ignoredVersion,
    this.storageUsedBytes = 0,
    this.history = const [],
  });

  final UpdatePhase phase;
  final InstalledAppInfo? installed;
  final AppUpdateInfo? latest;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final int downloadSpeedBps;
  final int etaSeconds;
  final String? localApkPath;
  final String? message;
  final String? error;
  final DateTime? lastCheckedAt;
  final String? ignoredVersion;
  final int storageUsedBytes;
  final List<AppUpdateInfo> history;

  bool get hasBlockingUpdate =>
      latest != null &&
      (latest!.updateBlocked || latest!.forceUpdate || latest!.emergencyUpdate) &&
      (latest!.updateAvailable);

  UpdateUiState copyWith({
    UpdatePhase? phase,
    InstalledAppInfo? installed,
    AppUpdateInfo? latest,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    int? downloadSpeedBps,
    int? etaSeconds,
    String? localApkPath,
    String? message,
    String? error,
    DateTime? lastCheckedAt,
    String? ignoredVersion,
    int? storageUsedBytes,
    List<AppUpdateInfo>? history,
    bool clearError = false,
    bool clearMessage = false,
    bool clearLocalApk = false,
  }) {
    return UpdateUiState(
      phase: phase ?? this.phase,
      installed: installed ?? this.installed,
      latest: latest ?? this.latest,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadSpeedBps: downloadSpeedBps ?? this.downloadSpeedBps,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      localApkPath: clearLocalApk ? null : localApkPath ?? this.localApkPath,
      message: clearMessage ? null : message ?? this.message,
      error: clearError ? null : error ?? this.error,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      ignoredVersion: ignoredVersion ?? this.ignoredVersion,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        installed,
        latest,
        progress,
        downloadedBytes,
        totalBytes,
        error,
        localApkPath,
      ];
}
