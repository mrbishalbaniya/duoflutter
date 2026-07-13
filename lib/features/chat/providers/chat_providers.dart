import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../repositories/chat_repository.dart';
import '../chat_utils.dart';
import '../data/chat_cache_service.dart';
import '../data/chat_disk_store.dart';
import '../domain/chat_message_cache.dart';

final chatMessageCacheProvider = Provider<ChatMessageCache>((ref) {
  return ChatMessageCache();
});

final chatDiskStoreProvider = Provider<ChatDiskStore>((ref) {
  final box = ref.watch(localStorageProvider).chatCache;
  return ChatDiskStore(box);
});

final chatCacheServiceProvider = Provider<ChatCacheService>((ref) {
  return ChatCacheService(
    memoryCache: ref.watch(chatMessageCacheProvider),
    diskStore: ref.watch(chatDiskStoreProvider),
  );
});

class ConversationListFilter {
  const ConversationListFilter({this.archived = false, this.unreadOnly = false});

  final bool archived;
  final bool unreadOnly;

  ConversationListFilter copyWith({bool? archived, bool? unreadOnly}) =>
      ConversationListFilter(
        archived: archived ?? this.archived,
        unreadOnly: unreadOnly ?? this.unreadOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is ConversationListFilter &&
      other.archived == archived &&
      other.unreadOnly == unreadOnly;

  @override
  int get hashCode => Object.hash(archived, unreadOnly);
}

class ConversationsListState {
  const ConversationsListState({
    this.conversations = const [],
    this.isRefreshing = false,
    this.fromCache = false,
    this.error,
  });

  final List<Conversation> conversations;
  final bool isRefreshing;
  final bool fromCache;
  final String? error;

  bool get hasData => conversations.isNotEmpty;

  ConversationsListState copyWith({
    List<Conversation>? conversations,
    bool? isRefreshing,
    bool? fromCache,
    String? error,
    bool clearError = false,
  }) {
    return ConversationsListState(
      conversations: conversations ?? this.conversations,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      fromCache: fromCache ?? this.fromCache,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Cache-first conversation list — shows disk/memory instantly, syncs in background.
class ConversationsListNotifier
    extends StateNotifier<ConversationsListState> {
  ConversationsListNotifier({
    required this.filter,
    required this.cache,
    required this.repository,
  }) : super(const ConversationsListState()) {
    _hydrate();
  }

  final ConversationListFilter filter;
  final ChatCacheService cache;
  final ChatRepository repository;

  String get _filterKey =>
      cache.filterKey(archived: filter.archived, unreadOnly: filter.unreadOnly);

  void _hydrate() {
    final cached = cache.readConversationList(_filterKey);
    if (cached != null) {
      state = ConversationsListState(
        conversations: cached.conversations,
        fromCache: true,
        isRefreshing: true,
      );
      if (cache.isListStale(cached)) {
        unawaited(refresh(force: true));
      } else {
        unawaited(refresh(force: false));
      }
      return;
    }
    unawaited(refresh(force: true));
  }

  Future<void> refresh({bool force = false}) async {
    if (state.isRefreshing && !force && state.hasData) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final fresh = await repository.getConversations(
        archived: filter.archived,
        unread: filter.unreadOnly,
      );
      cache.writeConversationList(_filterKey, fresh);
      for (final convo in fresh) {
        cache.writeConversation(convo);
      }
      state = ConversationsListState(
        conversations: fresh,
        isRefreshing: false,
        fromCache: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: state.hasData ? null : '$e',
      );
    }
  }

  void scheduleRefresh() {
    if (state.isRefreshing) return;
    unawaited(refresh(force: false));
  }

  void patchConversation(Conversation conversation) {
    final next = state.conversations
        .map((c) => c.publicId == conversation.publicId ? conversation : c)
        .toList();
    state = state.copyWith(conversations: next);
    cache.writeConversation(conversation);
    cache.writeConversationList(_filterKey, next);
  }
}

final conversationsListProvider = StateNotifierProvider.autoDispose
    .family<ConversationsListNotifier, ConversationsListState, ConversationListFilter>(
  (ref, filter) {
    return ConversationsListNotifier(
      filter: filter,
      cache: ref.watch(chatCacheServiceProvider),
      repository: ref.watch(chatRepositoryProvider),
    );
  },
);

/// Backward-compatible alias used across the app.
final conversationsProvider = Provider.autoDispose
    .family<AsyncValue<List<Conversation>>, ConversationListFilter>((ref, filter) {
  final listState = ref.watch(conversationsListProvider(filter));
  if (listState.error != null && !listState.hasData) {
    return AsyncValue.error(listState.error!, StackTrace.current);
  }
  if (!listState.hasData && listState.isRefreshing) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(listState.conversations);
});

final chatUnreadTotalProvider = Provider<int>((ref) {
  final conversations = ref.watch(
    conversationsListProvider(const ConversationListFilter()).select((s) => s.conversations),
  );
  return totalUnreadCount(conversations);
});
