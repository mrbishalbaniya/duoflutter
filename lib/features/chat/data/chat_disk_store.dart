import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';
import '../domain/chat_cache_serialization.dart';

/// Persistent Hive store for chat messages and conversations.
class ChatDiskStore {
  ChatDiskStore(this._box);

  final Box<dynamic> _box;

  static const _messagesPrefix = 'messages:';
  static const _conversationPrefix = 'conversation:';
  static const _listPrefix = 'conversations:';

  CachedMessagePage? readMessages(String conversationKey) {
    final raw = _box.get('$_messagesPrefix$conversationKey');
    return ChatCacheSerialization.messagesPageFromJson(raw);
  }

  Future<void> writeMessages(
    String conversationKey,
    List<ChatMessage> messages, {
    required bool hasMore,
  }) async {
    if (messages.isEmpty) return;
    await _box.put(
      '$_messagesPrefix$conversationKey',
      ChatCacheSerialization.messagesPageToJson(
        messages: sortMessages(messages),
        hasMore: hasMore,
        cachedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> clearMessages(String conversationKey) async {
    await _box.delete('$_messagesPrefix$conversationKey');
  }

  Conversation? readConversation(String conversationKey) {
    final raw = _box.get('$_conversationPrefix$conversationKey');
    if (raw is! Map) return null;
    try {
      return ChatCacheSerialization.conversationFromJson(
        Map<String, dynamic>.from(raw),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeConversation(Conversation conversation) async {
    await _box.put(
      '$_conversationPrefix${conversation.publicId}',
      ChatCacheSerialization.conversationToJson(conversation),
    );
    await _box.put(
      '$_conversationPrefix${conversation.id}',
      ChatCacheSerialization.conversationToJson(conversation),
    );
  }

  CachedConversationList? readConversationList(String filterKey) {
    final raw = _box.get('$_listPrefix$filterKey');
    if (raw is! Map) return null;
    final list = raw['conversations'] as List<dynamic>? ?? const [];
    final conversations = <Conversation>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        conversations.add(
          ChatCacheSerialization.conversationFromJson(
            Map<String, dynamic>.from(item),
          ),
        );
      } catch (_) {}
    }
    if (conversations.isEmpty) return null;
    return CachedConversationList(
      conversations: conversations,
      cachedAtMs: raw['cached_at_ms'] as int? ?? 0,
    );
  }

  Future<void> writeConversationList(
    String filterKey,
    List<Conversation> conversations,
  ) async {
    if (conversations.isEmpty) return;
    await _box.put(
      '$_listPrefix$filterKey',
      {
        'conversations': conversations.map(ChatCacheSerialization.conversationToJson).toList(),
        'cached_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> clearAll() async {
    final keys = _box.keys.toList(growable: false);
    for (final key in keys) {
      if (key is! String) continue;
      if (key.startsWith(_messagesPrefix) ||
          key.startsWith(_conversationPrefix) ||
          key.startsWith(_listPrefix)) {
        await _box.delete(key);
      }
    }
  }
}
