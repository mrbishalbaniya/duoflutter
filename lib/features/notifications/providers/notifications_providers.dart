import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/providers/core_providers.dart';
import '../data/notification_local_store.dart';
import '../domain/notification_item.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../../settings/providers/settings_providers.dart';

final notificationLocalStoreProvider = Provider<NotificationLocalStore>((ref) {
  if (Hive.isBoxOpen(NotificationLocalStore.boxName)) {
    return NotificationLocalStore(
      Hive.box<dynamic>(NotificationLocalStore.boxName),
    );
  }
  return NotificationLocalStore.ephemeral();
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    pushService: ref.watch(pushNotificationServiceProvider),
    repository: ref.watch(notificationRepositoryProvider),
    storage: ref.watch(localStorageProvider),
    localStore: ref.watch(notificationLocalStoreProvider),
    localNotifications: ref.watch(localNotificationServiceProvider),
  );
});

/// Legacy alias — prefer [notificationServiceProvider].
final pushMessagingCoordinatorProvider = notificationServiceProvider;

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.filter = NotificationFilter.all,
    this.search = '',
    this.loading = true,
    this.selectionMode = false,
    this.selectedIds = const {},
    this.lastDeleted,
  });

  final List<NotificationItem> items;
  final NotificationFilter filter;
  final String search;
  final bool loading;
  final bool selectionMode;
  final Set<String> selectedIds;
  final NotificationItem? lastDeleted;

  int get unreadCount => items.where((e) => !e.isRead).length;

  List<NotificationItem> get visibleItems {
    return items
        .where((e) => e.matchesFilter(filter) && e.matchesSearch(search))
        .toList();
  }

  NotificationsState copyWith({
    List<NotificationItem>? items,
    NotificationFilter? filter,
    String? search,
    bool? loading,
    bool? selectionMode,
    Set<String>? selectedIds,
    NotificationItem? lastDeleted,
    bool clearLastDeleted = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      loading: loading ?? this.loading,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      lastDeleted: clearLastDeleted ? null : (lastDeleted ?? this.lastDeleted),
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._store) : super(const NotificationsState()) {
    refresh();
  }

  final NotificationLocalStore _store;

  void refresh() {
    final items = _store.loadAll();
    state = state.copyWith(items: items, loading: false);
  }

  Future<void> ingest(NotificationItem item) async {
    await _store.upsert(item);
    refresh();
  }

  void setFilter(NotificationFilter filter) {
    state = state.copyWith(filter: filter, selectionMode: false, selectedIds: {});
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
  }

  Future<void> markRead(String id) async {
    await _store.markRead(id);
    refresh();
  }

  Future<void> markUnread(String id) async {
    await _store.markUnread(id);
    refresh();
  }

  Future<void> markAllRead() async {
    await _store.markAllRead();
    refresh();
  }

  Future<void> delete(String id) async {
    final removed = await _store.delete(id);
    if (removed != null) {
      state = state.copyWith(lastDeleted: removed);
      refresh();
    }
  }

  Future<void> deleteSelected() async {
    await _store.deleteMany(state.selectedIds);
    state = state.copyWith(selectionMode: false, selectedIds: {});
    refresh();
  }

  Future<void> undoDelete() async {
    final item = state.lastDeleted;
    if (item == null) return;
    await _store.upsert(item);
    state = state.copyWith(clearLastDeleted: true);
    refresh();
  }

  void toggleSelectionMode() {
    state = state.copyWith(
      selectionMode: !state.selectionMode,
      selectedIds: {},
    );
  }

  void toggleSelected(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref.watch(notificationLocalStoreProvider));
});

final notificationUnreadCountProvider = Provider<int>((ref) {
  final store = ref.watch(notificationLocalStoreProvider);
  return store.unreadCount(store.loadAll());
});
