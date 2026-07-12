import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/providers/core_providers.dart';
import '../chat_utils.dart';

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

final conversationsProvider =
    FutureProvider.autoDispose.family<List<Conversation>, ConversationListFilter>(
  (ref, filter) {
    return ref.read(chatRepositoryProvider).getConversations(
          archived: filter.archived,
          unread: filter.unreadOnly,
        );
  },
);

final chatUnreadTotalProvider = Provider<int>((ref) {
  final conversations = ref.watch(
    conversationsProvider(const ConversationListFilter()),
  );
  return conversations.maybeWhen(
    data: totalUnreadCount,
    orElse: () => 0,
  );
});
