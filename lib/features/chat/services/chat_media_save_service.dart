import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/chat_media_utils.dart';

enum GallerySaveStatus {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  downloadFailed,
  saveFailed,
  invalidMedia,
  noInternet,
  cancelled,
}

class GallerySaveProgress {
  const GallerySaveProgress({
    required this.phase,
    this.progress,
  });

  final String phase;
  final double? progress;
}

class GallerySaveOutcome {
  const GallerySaveOutcome({
    required this.status,
    this.message,
    this.savedFromCache = false,
  });

  final GallerySaveStatus status;
  final String? message;
  final bool savedFromCache;

  bool get isSuccess => status == GallerySaveStatus.success;
}

/// Resolves cached/local media and saves to the device gallery.
class ChatMediaSaveService {
  ChatMediaSaveService({Dio? dio, BaseCacheManager? cacheManager})
      : _dio = dio ?? Dio(),
        _cache = cacheManager ?? DefaultCacheManager();

  final Dio _dio;
  final BaseCacheManager _cache;

  Future<GallerySaveOutcome> saveToGallery({
    required String? remoteUrl,
    String? localPath,
    void Function(GallerySaveProgress progress)? onProgress,
  }) async {
    try {
      onProgress?.call(const GallerySaveProgress(phase: 'Checking permissions'));
      final permission = await _ensureGalleryAccess(isVideo: isVideoMediaUrl(remoteUrl));
      if (permission == GallerySaveStatus.permissionDenied) {
        return const GallerySaveOutcome(
          status: GallerySaveStatus.permissionDenied,
          message: 'Gallery access is required to save media.',
        );
      }
      if (permission == GallerySaveStatus.permissionPermanentlyDenied) {
        return const GallerySaveOutcome(
          status: GallerySaveStatus.permissionPermanentlyDenied,
          message: 'Gallery access was denied. Open Settings to allow saving photos.',
        );
      }

      onProgress?.call(const GallerySaveProgress(phase: 'Preparing file'));
      final resolved = await _resolveMediaFile(
        remoteUrl: remoteUrl,
        localPath: localPath,
        onProgress: onProgress,
      );
      if (resolved == null) {
        return const GallerySaveOutcome(
          status: GallerySaveStatus.invalidMedia,
          message: 'This media could not be loaded.',
        );
      }

      onProgress?.call(const GallerySaveProgress(phase: 'Saving to gallery'));
      final isVideo = isVideoMediaUrl(remoteUrl) || isVideoMediaUrl(resolved.path);
      try {
        if (isVideo) {
          await Gal.putVideo(resolved.path);
        } else {
          await Gal.putImage(resolved.path);
        }
      } on GalException catch (error) {
        return GallerySaveOutcome(
          status: GallerySaveStatus.saveFailed,
          message: error.type.message,
        );
      }

      return GallerySaveOutcome(
        status: GallerySaveStatus.success,
        message: '${mediaTypeLabel(url: remoteUrl, localPath: localPath)} saved to gallery',
        savedFromCache: resolved.fromCache,
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return const GallerySaveOutcome(
          status: GallerySaveStatus.noInternet,
          message: 'No internet connection. Check your network and try again.',
        );
      }
      return GallerySaveOutcome(
        status: GallerySaveStatus.downloadFailed,
        message: 'Download failed. Please try again.',
      );
    } on FileSystemException {
      return const GallerySaveOutcome(
        status: GallerySaveStatus.saveFailed,
        message: 'Not enough storage space to save this file.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ChatMediaSave] unexpected error: $error');
      }
      return GallerySaveOutcome(
        status: GallerySaveStatus.saveFailed,
        message: 'Could not save media. Please try again.',
      );
    }
  }

  Future<GallerySaveStatus?> _ensureGalleryAccess({required bool isVideo}) async {
    if (kIsWeb) return GallerySaveStatus.saveFailed;

    if (Platform.isAndroid || Platform.isIOS) {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (hasAccess) return null;

      final granted = await Gal.requestAccess(toAlbum: true);
      if (granted) return null;

      if (Platform.isAndroid) {
        final photos = await Permission.photos.status;
        if (photos.isPermanentlyDenied) {
          return GallerySaveStatus.permissionPermanentlyDenied;
        }
        if (isVideo) {
          final videos = await Permission.videos.status;
          if (videos.isPermanentlyDenied) {
            return GallerySaveStatus.permissionPermanentlyDenied;
          }
        }
        final storage = await Permission.storage.status;
        if (storage.isPermanentlyDenied) {
          return GallerySaveStatus.permissionPermanentlyDenied;
        }
      }

      return GallerySaveStatus.permissionDenied;
    }

    return null;
  }

  Future<_ResolvedMedia?> _resolveMediaFile({
    required String? remoteUrl,
    String? localPath,
    void Function(GallerySaveProgress progress)? onProgress,
  }) async {
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        return _ResolvedMedia(file: file, fromCache: true);
      }
    }

    final url = remoteUrl?.trim();
    if (url == null || url.isEmpty) return null;

    final cached = await _cache.getFileFromCache(url);
    if (cached != null && await cached.file.exists()) {
      return _ResolvedMedia(file: cached.file, fromCache: true);
    }

    onProgress?.call(const GallerySaveProgress(phase: 'Downloading', progress: 0));
    try {
      final file = await _cache.getSingleFile(url);
      if (await file.exists()) {
        return _ResolvedMedia(file: file, fromCache: false);
      }
    } catch (_) {
      // Fall through to direct download for original quality.
    }

    final tempDir = await getTemporaryDirectory();
    final ext = mediaFileExtension(url: url, localPath: localPath);
    final target = File('${tempDir.path}/duo_save_${url.hashCode}$ext');

    if (await target.exists() && await target.length() > 0) {
      return _ResolvedMedia(file: target, fromCache: true);
    }

    await _dio.download(
      url,
      target.path,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(
            GallerySaveProgress(
              phase: 'Downloading',
              progress: received / total,
            ),
          );
        }
      },
    );

    if (!await target.exists() || await target.length() == 0) {
      return null;
    }

    return _ResolvedMedia(file: target, fromCache: false);
  }

  static Future<void> openSettings() => openAppSettings();

  /// Resolves a local file from cache, disk, or network without saving to gallery.
  Future<File?> resolveMediaFile({
    required String? remoteUrl,
    String? localPath,
  }) async {
    final resolved = await _resolveMediaFile(
      remoteUrl: remoteUrl,
      localPath: localPath,
    );
    return resolved?.file;
  }
}

class _ResolvedMedia {
  const _ResolvedMedia({required this.file, required this.fromCache});

  final File file;
  final bool fromCache;

  String get path => file.path;
}
