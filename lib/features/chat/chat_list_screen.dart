import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/chat_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_theme.dart';
import 'chat_utils.dart';
import 'providers/chat_providers.dart';
import 'widgets/chat_shimmer.dart';
import 'widgets/swipeable_conversation_tile.dart';
import '../../widgets/duo_profile_avatar_button.dart';

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
      await ref
          .read(chatRepositoryProvider)
          .updateConversationSettings(
            convo.publicId,
            pinned: pinned,
            muted: muted,
            archived: archived,
          );
      ref.read(conversationsListProvider(_filter).notifier).scheduleRefresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _precacheAvatars(List<Conversation> conversations) {
    if (!mounted) return;
    for (final convo in conversations.take(12)) {
      final photo = convo.otherUserProfile.displayPhoto;
      if (photo.isEmpty) continue;
      precacheImage(CachedNetworkImageProvider(photo), context);
    }
  }

  /// Web "Delete": clears your history, then archives it out of the inbox.
  Future<void> _deleteConversation(Conversation convo) async {
    final name = (convo.otherUserNickname ?? '').trim().isNotEmpty
        ? convo.otherUserNickname!.trim()
        : (convo.otherUserProfile.fullName.isNotEmpty
              ? convo.otherUserProfile.fullName
              : 'this match');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          'This clears your chat history with $name and removes it from your inbox. '
          'The other person can still see the messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(chatRepositoryProvider);
      await repo.clearConversationHistory(convo.publicId);
      if (!_filter.archived) {
        await repo.updateConversationSettings(convo.publicId, archived: true);
      }
      ref.read(conversationsListProvider(_filter).notifier).scheduleRefresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Conversation deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete conversation.')),
      );
    }
  }

  /// Long-press menu: Pin · Mute · Archive · Delete (web row "⋮" menu).
  void _showRowMenu(Conversation convo) {
    final archived = _filter.archived;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget action(
          IconData icon,
          String label,
          VoidCallback onTap, {
          bool danger = false,
        }) => ListTile(
          leading: Icon(icon, color: danger ? scheme.error : null),
          title: Text(
            label,
            style: TextStyle(color: danger ? scheme.error : null),
          ),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              action(
                convo.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                convo.isPinned ? 'Unpin' : 'Pin',
                () => _updateSettings(convo, pinned: !convo.isPinned),
              ),
              action(
                convo.isMuted
                    ? Icons.notifications_outlined
                    : Icons.notifications_off_outlined,
                convo.isMuted ? 'Unmute' : 'Mute',
                () => _updateSettings(convo, muted: !convo.isMuted),
              ),
              action(
                archived
                    ? Icons.unarchive_outlined
                    : Icons.inventory_2_outlined,
                archived ? 'Unarchive' : 'Archive',
                () => _updateSettings(convo, archived: !archived),
              ),
              action(
                Icons.delete_outline,
                'Delete',
                () => _deleteConversation(convo),
                danger: true,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(conversationsListProvider(_filter));
    final scheme = Theme.of(context).colorScheme;

    if (listState.hasData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheAvatars(listState.conversations);
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Profile · search · ⋮ (Unread / Archived filters).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        textInputAction: TextInputAction.search,
                        cursorColor: scheme.primary,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search conversations',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: _search.isEmpty
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                          suffixIcon: _search.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: Icon(
                                    Icons.cancel_rounded,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                ),
                          filled: true,
                          fillColor: scheme.surfaceContainerHigh,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.6),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: Badge(
                      isLabelVisible: _filter.unreadOnly || _filter.archived,
                      smallSize: 8,
                      backgroundColor: scheme.primary,
                      child: const Icon(Icons.more_vert_rounded),
                    ),
                    onSelected: (value) => setState(() {
                      switch (value) {
                        case 'unread':
                          _filter = _filter.copyWith(
                            unreadOnly: !_filter.unreadOnly,
                          );
                        case 'archived':
                          _filter = _filter.copyWith(
                            archived: !_filter.archived,
                          );
                      }
                    }),
                    itemBuilder: (context) {
                      final total = totalUnreadCount(listState.conversations);
                      PopupMenuItem<String> item(
                        String value,
                        IconData icon,
                        String label,
                        bool on,
                      ) => PopupMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color: on
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: on
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: on ? scheme.primary : null,
                                ),
                              ),
                            ),
                            if (on)
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                          ],
                        ),
                      );
                      return [
                        item(
                          'unread',
                          Icons.mark_chat_unread_outlined,
                          total > 0 ? 'Unread ($total)' : 'Unread',
                          _filter.unreadOnly,
                        ),
                        item(
                          'archived',
                          Icons.archive_outlined,
                          'Archived',
                          _filter.archived,
                        ),
                      ];
                    },
                  ),
                  const DuoProfileAvatarButton(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: _buildBody(listState, scheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ConversationsListState listState, ColorScheme scheme) {
    if (!listState.hasData && listState.isRefreshing) {
      return const ChatListShimmer();
    }

    if (listState.error != null && !listState.hasData) {
      return Center(
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
                listState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref
                    .read(conversationsListProvider(_filter).notifier)
                    .refresh(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = filterConversations(
      items: sortConversations(listState.conversations),
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
                    ? 'No archived conversations.'
                    : _search.isNotEmpty
                    ? 'No matches for your search.'
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
      onRefresh: () => ref
          .read(conversationsListProvider(_filter).notifier)
          .refresh(force: true),
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final convo = filtered[index];
          return GestureDetector(
            onLongPress: () => _showRowMenu(convo),
            child: SwipeableConversationTile(
              conversation: convo,
              onTap: () => context.push('/chat/${convo.publicId}'),
              onPin: () => _updateSettings(convo, pinned: !convo.isPinned),
              onMute: () => _updateSettings(convo, muted: !convo.isMuted),
            ),
          );
        },
      ),
    );
  }
}
