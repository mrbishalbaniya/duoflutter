import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';
import 'chat_cache_serialization.dart';

/// In-memory hot cache for active conversations and lists.
class ChatMessageCache {
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, int> _cachedAtMs = {};
  final Map<String, CachedConversationList> _conversationLists = {};

  List<ChatMessage>? peek(String conversationKey) {
    final cached = _messages[conversationKey];
    if (cached == null || cached.isEmpty) return null;
    return List<ChatMessage>.from(cached);
  }

  bool? hasMore(String conversationKey) => _hasMore[conversationKey];

  int? cachedAtMs(String conversationKey) => _cachedAtMs[conversationKey];

  void put(
    String conversationKey,
    List<ChatMessage> messages, {
    bool? hasMore,
    int? cachedAtMs,
  }) {
    if (messages.isEmpty) return;
    _messages[conversationKey] = sortMessages(messages);
    if (hasMore != null) _hasMore[conversationKey] = hasMore;
    if (cachedAtMs != null) _cachedAtMs[conversationKey] = cachedAtMs;
  }

  void clear(String conversationKey) {
    _messages.remove(conversationKey);
    _hasMore.remove(conversationKey);
    _cachedAtMs.remove(conversationKey);
  }

  void clearAll() {
    _messages.clear();
    _hasMore.clear();
    _cachedAtMs.clear();
    _conversationLists.clear();
  }

  CachedConversationList? peekConversationList(String filterKey) {
    return _conversationLists[filterKey];
  }

  void putConversationList(String filterKey, CachedConversationList list) {
    _conversationLists[filterKey] = list;
  }
}
