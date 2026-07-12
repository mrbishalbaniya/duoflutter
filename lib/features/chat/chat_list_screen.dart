import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/chat_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_theme.dart';
import '../../widgets/duo_ui.dart';
import 'chat_utils.dart';
import 'providers/chat_providers.dart';
import 'widgets/chat_shimmer.dart';
import 'widgets/swipeable_conversation_tile.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchController = TextEditingController();
  ConversationListFilter _filter = const ConversationListFilter();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings(
    Conversation convo, {
    bool? pinned,
    bool? muted,
    bool? archived,
  }) async {
    try {
      await ref.read(chatRepositoryProvider).updateConversationSettings(
            convo.publicId,
            pinned: pinned,
            muted: muted,
            archived: archived,
          );
      ref.invalidate(conversationsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider(_filter));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DuoPageHeader(
              title: 'Messages',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    icon: conversations.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Filter conversations',
                    onSelected: (value) {
                      setState(() {
                        switch (value) {
                          case 'unread':
                            _filter = _filter.copyWith(unreadOnly: !_filter.unreadOnly);
                          case 'archived':
                            _filter = _filter.copyWith(archived: !_filter.archived);
                        }
                      });
                    },
                    itemBuilder: (_) => [
                      CheckedPopupMenuItem<String>(
                        value: 'unread',
                        checked: _filter.unreadOnly,
                        child: const Text('Unread'),
                      ),
                      CheckedPopupMenuItem<String>(
                        value: 'archived',
                        checked: _filter.archived,
                        child: const Text('Archived'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: conversations.maybeWhen(
                data: (items) {
                  final total = totalUnreadCount(items);
                  if (total == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DuoColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$total unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search conversations…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: conversations.when(
                  loading: () => const ChatListShimmer(),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 48, color: scheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load messages',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$e',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(conversationsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (items) {
                    final filtered = filterConversations(
                      items: sortConversations(items),
                      query: _search,
                      unreadOnly: false,
                    );
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 56,
                                color: DuoColors.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filter.archived
                                    ? 'No archived chats'
                                    : _search.isNotEmpty
                                        ? 'No results'
                                        : 'No conversations yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (!_filter.archived && _search.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Match with someone to start chatting.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => context.go(AppRoutes.match),
                                  child: const Text('Find matches'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(conversationsProvider),
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final convo = filtered[index];
                          return SwipeableConversationTile(
                            conversation: convo,
                            onTap: () => context.push('/chat/${convo.publicId}'),
                            onPin: () => _updateSettings(convo, pinned: !convo.isPinned),
                            onMute: () => _updateSettings(convo, muted: !convo.isMuted),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
