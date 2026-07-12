import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';

/// In-memory per-conversation message cache (mirrors Next.js `messagesCacheRef`).
class ChatMessageCache {
  final Map<String, List<ChatMessage>> _store = {};

  List<ChatMessage>? peek(String conversationKey) {
    final cached = _store[conversationKey];
    if (cached == null || cached.isEmpty) return null;
    return List<ChatMessage>.from(cached);
  }

  void put(String conversationKey, List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    _store[conversationKey] = sortMessages(messages);
  }

  void clear(String conversationKey) {
    _store.remove(conversationKey);
  }
}
