import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/notification_item.dart';
import '../domain/notification_tap_payload.dart';
import '../providers/notifications_providers.dart';
import '../services/notification_router.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_filter_bar.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(notificationsControllerProvider, (prev, next) {
      if (next.lastDeleted != null && next.lastDeleted != prev?.lastDeleted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: notifier.undoDelete,
            ),
          ),
        );
      }
    });

    final items = state.visibleItems;
    final selecting = state.selectionMode;
    final allSelected = items.isNotEmpty && items.every((i) => state.selectedIds.contains(i.id));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selecting
                    ? Row(
                        key: const ValueKey('select-header'),
                        children: [
                          IconButton(
                            tooltip: 'Cancel selection',
                            onPressed: notifier.toggleSelectionMode,
                            icon: const Icon(Icons.close_rounded),
                          ),
                          Expanded(
                            child: Text(
                              state.selectedIds.isEmpty
                                  ? 'Select notifications'
                                  : '${state.selectedIds.length} selected',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: () => notifier.toggleSelectAll(items.map((i) => i.id)),
                            child: Text(allSelected ? 'Clear' : 'Select all'),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('header'),
                        children: [
                          DuoIconCircleButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Notifications',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                if (state.unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                                      style: TextStyle(
                                        color: scheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (state.unreadCount > 0)
                            IconButton(
                              tooltip: 'Mark all as read',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                notifier.markAllRead();
                              },
                              icon: Icon(Icons.done_all_rounded, color: scheme.primary),
                            ),
                          PopupMenuButton<String>(
                            tooltip: 'More',
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (v) {
                              if (v == 'select') notifier.toggleSelectionMode();
                              if (v == 'settings') context.push(AppRoutes.settings);
                            },
                            itemBuilder: (_) => [
                              if (items.isNotEmpty)
                                const PopupMenuItem(
                                  value: 'select',
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.checklist_rounded),
                                    title: Text('Select'),
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.tune_rounded),
                                  title: Text('Notification settings'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            // ---- Search ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _searchController,
                onChanged: notifier.setSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: state.search.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearch('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
            NotificationFilterBar(
              active: state.filter,
              unreadCount: state.unreadCount,
              onChanged: notifier.setFilter,
            ),
            const SizedBox(height: 6),
            // ---- List ----
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async => notifier.refresh(),
                      child: items.isEmpty
                          ? _EmptyState(filter: state.filter, search: state.search)
                          : _GroupedList(
                              items: items,
                              itemBuilder: (item, index) => NotificationCard(
                                item: item,
                                animationIndex: index,
                                selectionMode: selecting,
                                selected: state.selectedIds.contains(item.id),
                                onTap: () => _openNotification(item),
                                onLongPress: () {
                                  HapticFeedback.selectionClick();
                                  if (!selecting) notifier.toggleSelectionMode();
                                  notifier.toggleSelected(item.id);
                                },
                                onSelectToggle: () => notifier.toggleSelected(item.id),
                                onMarkRead: () {
                                  if (item.isRead) {
                                    notifier.markUnread(item.id);
                                  } else {
                                    notifier.markRead(item.id);
                                  }
                                },
                                onDelete: () => notifier.delete(item.id),
                              ),
                            ),
                    ),
            ),
            // ---- Selection action bar ----
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: selecting && state.selectedIds.isNotEmpty
                  ? SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  for (final id in state.selectedIds) {
                                    notifier.markRead(id);
                                  }
                                  notifier.toggleSelectionMode();
                                },
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Mark read'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.error,
                                  foregroundColor: scheme.onError,
                                ),
                                onPressed: notifier.deleteSelected,
                                icon: const Icon(Icons.delete_rounded),
                                label: Text('Delete ${state.selectedIds.length}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotification(NotificationItem item) {
    HapticFeedback.lightImpact();
    ref.read(notificationsControllerProvider.notifier).markRead(item.id);
    final data = item.data.map((k, v) => MapEntry(k, '$v'));
    final conversationId = data['conversation_id'] ?? data['conversation'] ?? '';
    NotificationRouter.navigate(
      router: GoRouter.of(context),
      ref: ref,
      payload: NotificationTapPayload(
        deepLink: item.deepLink.isNotEmpty ? item.deepLink : AppRoutes.notifications,
        type: item.type,
        conversationId: conversationId,
        notificationId: item.id,
      ),
    );
  }
}

/// Section label for a notification's day.
String _groupLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'This week';
  return 'Earlier';
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items, required this.itemBuilder});

  final List<NotificationItem> items;
  final Widget Function(NotificationItem item, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Object>[];
    String? last;
    for (final item in items) {
      final g = _groupLabel(item.receivedAt.toLocal());
      if (g != last) {
        rows.add(g);
        last = g;
      }
      rows.add(item);
    }
    var itemIndex = 0;
    final indexOf = <NotificationItem, int>{for (final r in rows.whereType<NotificationItem>()) r: itemIndex++};

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              row.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final item = row as NotificationItem;
        return itemBuilder(item, indexOf[item] ?? 0);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.search});

  final NotificationFilter filter;
  final String search;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasQuery = search.trim().isNotEmpty || filter != NotificationFilter.all;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withValues(alpha: 0.18),
                          scheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      hasQuery ? Icons.search_off_rounded : Icons.notifications_none_rounded,
                      size: 44,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    hasQuery ? 'No matching notifications' : "You're all caught up",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasQuery
                        ? 'Try a different search or filter.'
                        : 'Likes, matches and messages will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  if (!hasQuery) ...[
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Notification settings'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
