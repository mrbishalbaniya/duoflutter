import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';
import 'chat_cache_serialization.dart';

/// In-memory hot cache for active conversations and lists.
class ChatMessageCache {
  static const maxConversations = 24;
  static const maxMessagesPerConversation = 500;

  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, int> _cachedAtMs = {};
  final Map<String, CachedConversationList> _conversationLists = {};

  List<ChatMessage>? peek(String conversationKey) {
    final cached = _messages[conversationKey];
    if (cached == null || cached.isEmpty) return null;
    return List<ChatMessage>.unmodifiable(cached);
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
    var sorted = sortMessages(messages);
    if (sorted.length > maxMessagesPerConversation) {
      sorted = sorted.sublist(sorted.length - maxMessagesPerConversation);
    }
    _messages[conversationKey] = sorted;
    _touchConversation(conversationKey);
    _evictIfNeeded();
    if (hasMore != null) _hasMore[conversationKey] = hasMore;
    if (cachedAtMs != null) _cachedAtMs[conversationKey] = cachedAtMs;
  }

  void _touchConversation(String conversationKey) {
    final entry = _messages.remove(conversationKey);
    if (entry != null) _messages[conversationKey] = entry;
  }

  void _evictIfNeeded() {
    while (_messages.length > maxConversations) {
      final oldest = _messages.keys.first;
      _messages.remove(oldest);
      _hasMore.remove(oldest);
      _cachedAtMs.remove(oldest);
    }
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
