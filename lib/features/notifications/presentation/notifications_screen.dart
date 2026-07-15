import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  DuoIconCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (state.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.markAllRead();
                      },
                      child: const Text('Mark all read'),
                    ),
                  IconButton(
                    onPressed: notifier.toggleSelectionMode,
                    icon: Icon(
                      state.selectionMode ? Icons.close : Icons.checklist,
                      color: DuoColors.primary,
                    ),
                    tooltip: state.selectionMode ? 'Cancel selection' : 'Select notifications',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: notifier.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search notifications',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: state.search.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearch('');
                          },
                          icon: const Icon(Icons.close, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
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
            const SizedBox(height: 8),
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? _EmptyState(filter: state.filter, search: state.search)
                      : RefreshIndicator(
                          onRefresh: () async => notifier.refresh(),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (_, index) {
                              final item = items[index];
                              return NotificationCard(
                                item: item,
                                animationIndex: index,
                                selectionMode: state.selectionMode,
                                selected: state.selectedIds.contains(item.id),
                                onTap: () => _openNotification(item),
                                onLongPress: () {
                                  if (!state.selectionMode) {
                                    notifier.toggleSelectionMode();
                                    notifier.toggleSelected(item.id);
                                  }
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
                              );
                            },
                          ),
                        ),
            ),
            if (state.selectionMode && state.selectedIds.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: notifier.deleteSelected,
                    icon: const Icon(Icons.delete_outline),
                    label: Text('Delete ${state.selectedIds.length} selected'),
                  ),
                ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.search});

  final NotificationFilter filter;
  final String search;

  @override
  Widget build(BuildContext context) {
    final hasQuery = search.trim().isNotEmpty || filter != NotificationFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off_outlined : Icons.notifications_none_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching notifications' : 'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different search or filter.'
                  : 'Likes, matches, and messages will appear here when you receive push alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.settings),
              child: const Text('Notification settings'),
            ),
          ],
        ),
      ),
    );
  }
}
