import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/notification_item.dart';

class NotificationLocalStore {
  NotificationLocalStore(this._box) : _ephemeral = null;

  NotificationLocalStore.ephemeral() : _box = null, _ephemeral = [];

  static const boxName = 'notification_inbox';
  static const _listKey = 'items';
  static const maxItems = 200;

  final Box<dynamic>? _box;
  final List<Map<String, dynamic>>? _ephemeral;

  List<NotificationItem> loadAll() {
    final raw = _readRawList();
    return raw
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  List<Map<String, dynamic>> _readRawList() {
    if (_ephemeral != null) return List<Map<String, dynamic>>.from(_ephemeral!);
    final raw = _box?.get(_listKey);
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveAll(List<NotificationItem> items) async {
    final trimmed = items.take(maxItems).toList();
    final encoded = trimmed.map((e) => e.toJson()).toList();
    if (_ephemeral != null) {
      _ephemeral!
        ..clear()
        ..addAll(encoded);
      return;
    }
    await _box?.put(_listKey, encoded);
  }

  Future<NotificationItem> upsert(NotificationItem item) async {
    final items = loadAll();
    final existingIndex = items.indexWhere((e) => e.id == item.id);
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.insert(0, item);
    }
    await saveAll(items);
    return item;
  }

  Future<void> markRead(String id) async {
    final items = loadAll();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(isRead: true);
    await saveAll(items);
  }

  Future<void> markUnread(String id) async {
    final items = loadAll();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(isRead: false);
    await saveAll(items);
  }

  Future<void> markAllRead() async {
    final items = loadAll().map((e) => e.copyWith(isRead: true)).toList();
    await saveAll(items);
  }

  Future<NotificationItem?> delete(String id) async {
    final items = loadAll();
    final idx = items.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final removed = items.removeAt(idx);
    await saveAll(items);
    return removed;
  }

  Future<void> deleteMany(Set<String> ids) async {
    if (ids.isEmpty) return;
    final items = loadAll().where((e) => !ids.contains(e.id)).toList();
    await saveAll(items);
  }

  Future<void> clear() async {
    if (_ephemeral != null) {
      _ephemeral!.clear();
      return;
    }
    await _box?.delete(_listKey);
  }

  int unreadCount(List<NotificationItem> items) =>
      items.where((e) => !e.isRead).length;

  static String idFromPayload(Map<String, String> data) {
    final tag = data['tag']?.trim();
    final type = data['type']?.trim();
    if (tag != null && tag.isNotEmpty) return '$type-$tag';
    final encoded = jsonEncode(data);
    return 'push-${encoded.hashCode.abs()}';
  }
}
