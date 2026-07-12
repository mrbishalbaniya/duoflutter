import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/local_storage.dart';
import '../../chat/data/chat_cache_service.dart';
import '../../chat/providers/chat_providers.dart';

class SettingsStorageInfo {
  const SettingsStorageInfo({
    required this.totalBytes,
    required this.chatCacheBytes,
    required this.imageCacheBytes,
  });

  final int totalBytes;
  final int chatCacheBytes;
  final int imageCacheBytes;

  String get formattedTotal => _formatBytes(totalBytes);
  String get formattedChat => _formatBytes(chatCacheBytes);
  String get formattedImages => _formatBytes(imageCacheBytes);
}

class SettingsStorageService {
  const SettingsStorageService({
    required this.chatCache,
    this.imageCacheManager,
  });

  final ChatCacheService chatCache;
  final BaseCacheManager? imageCacheManager;

  Future<SettingsStorageInfo> loadInfo() async {
    final chatBytes = await _estimateHiveChatCacheBytes();
    final imageBytes = await _estimateImageCacheBytes();
    return SettingsStorageInfo(
      totalBytes: chatBytes + imageBytes,
      chatCacheBytes: chatBytes,
      imageCacheBytes: imageBytes,
    );
  }

  Future<void> clearCaches() async {
    await chatCache.clearAll();
    await (imageCacheManager ?? DefaultCacheManager()).emptyCache();
  }

  Future<int> _estimateHiveChatCacheBytes() async {
    try {
      final path = Hive.box<dynamic>(LocalStorage.chatCacheBoxName).path;
      if (path == null || path.isEmpty) return 0;
      final hiveFile = File(path);
      if (!await hiveFile.exists()) return 0;
      var total = await hiveFile.length();
      final lockFile = File('$path.lock');
      if (await lockFile.exists()) {
        total += await lockFile.length();
      }
      return total;
    } catch (_) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${LocalStorage.chatCacheBoxName}.hive');
        if (!await file.exists()) return 0;
        return await file.length();
      } catch (_) {
        return 0;
      }
    }
  }

  Future<int> _estimateImageCacheBytes() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      return _directorySize(cacheDir);
    } catch (_) {
      return 0;
    }
  }

  Future<int> _directorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

final settingsStorageServiceProvider = Provider<SettingsStorageService>((ref) {
  return SettingsStorageService(
    chatCache: ref.watch(chatCacheServiceProvider),
  );
});

final settingsStorageInfoProvider = FutureProvider.autoDispose<SettingsStorageInfo>((ref) {
  return ref.watch(settingsStorageServiceProvider).loadInfo();
});
