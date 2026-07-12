import 'dart:async';

import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';
import '../domain/chat_cache_serialization.dart';
import '../domain/chat_message_cache.dart';
import '../services/chat_debug_log.dart';
import 'chat_disk_store.dart';

/// Multi-layer chat cache: memory → disk → network.
class ChatCacheService {
  ChatCacheService({
    required ChatMessageCache memoryCache,
    required ChatDiskStore diskStore,
  })  : _memory = memoryCache,
        _disk = diskStore;

  static const messagePageSize = 30;
  static const maxStaleMs = 1000 * 60 * 30; // 30 min before background refresh

  final ChatMessageCache _memory;
  final ChatDiskStore _disk;

  final _typingByConversation = <String, bool>{};
  final _conversationMeta = <String, Conversation>{};

  int memoryHits = 0;
  int diskHits = 0;
  int misses = 0;

  double get hitRatio {
    final total = memoryHits + diskHits + misses;
    if (total == 0) return 0;
    return (memoryHits + diskHits) / total;
  }

  String filterKey({required bool archived, required bool unreadOnly}) {
    return 'archived=$archived&unread=$unreadOnly';
  }

  CachedMessagePage? readMessages(String conversationKey) {
    final normalized = conversationKey.trim();
    if (normalized.isEmpty) return null;

    final mem = _memory.peek(normalized);
    if (mem != null && mem.isNotEmpty) {
      memoryHits++;
      ChatDebugLog.cacheHit(layer: 'memory', kind: 'messages', key: normalized);
      return CachedMessagePage(
        messages: mem,
        hasMore: _memory.hasMore(normalized) ?? true,
        cachedAtMs: _memory.cachedAtMs(normalized) ?? 0,
      );
    }

    final disk = _disk.readMessages(normalized);
    if (disk != null) {
      diskHits++;
      _memory.put(normalized, disk.messages, hasMore: disk.hasMore, cachedAtMs: disk.cachedAtMs);
      ChatDebugLog.cacheHit(layer: 'disk', kind: 'messages', key: normalized);
      return disk;
    }

    misses++;
    ChatDebugLog.cacheMiss(kind: 'messages', key: normalized);
    return null;
  }

  void writeMessages(
    String conversationKey,
    List<ChatMessage> messages, {
    required bool hasMore,
    bool persist = true,
  }) {
    final normalized = conversationKey.trim();
    if (normalized.isEmpty || messages.isEmpty) return;
    final sorted = sortMessages(messages);
    final now = DateTime.now().millisecondsSinceEpoch;
    _memory.put(normalized, sorted, hasMore: hasMore, cachedAtMs: now);
    ChatDebugLog.messageCached(conversationKey: normalized, count: sorted.length);
    if (persist) {
      unawaited(_disk.writeMessages(normalized, sorted, hasMore: hasMore));
    }
  }

  Future<void> clearMessages(String conversationKey) async {
    final normalized = conversationKey.trim();
    _memory.clear(normalized);
    await _disk.clearMessages(normalized);
  }

  Conversation? readConversation(String conversationKey) {
    final normalized = conversationKey.trim();
    if (normalized.isEmpty) return null;

    final meta = _conversationMeta[normalized];
    if (meta != null) {
      memoryHits++;
      ChatDebugLog.cacheHit(layer: 'memory', kind: 'conversation', key: normalized);
      return meta;
    }

    final disk = _disk.readConversation(normalized);
    if (disk != null) {
      diskHits++;
      _conversationMeta[normalized] = disk;
      _conversationMeta[disk.publicId] = disk;
      ChatDebugLog.cacheHit(layer: 'disk', kind: 'conversation', key: normalized);
      return disk;
    }

    misses++;
    ChatDebugLog.cacheMiss(kind: 'conversation', key: normalized);
    return null;
  }

  void writeConversation(Conversation conversation, {bool persist = true}) {
    _conversationMeta[conversation.publicId] = conversation;
    _conversationMeta[conversation.id.toString()] = conversation;
    ChatDebugLog.conversationCached(conversationId: conversation.publicId);
    if (persist) {
      unawaited(_disk.writeConversation(conversation));
    }
  }

  void patchConversationPreview({
    required String conversationKey,
    required ChatMessage lastMessage,
    required String lastMessageAt,
    int unreadCount = 0,
    bool? isOtherUserTyping,
  }) {
    final existing = readConversation(conversationKey);
    if (existing == null) return;
    final patched = existing.copyWith(
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      isOtherUserTyping: isOtherUserTyping ?? existing.isOtherUserTyping,
    );
    writeConversation(patched);
  }

  CachedConversationList? readConversationList(String filterKey) {
    final mem = _memory.peekConversationList(filterKey);
    if (mem != null) {
      memoryHits++;
      ChatDebugLog.cacheHit(layer: 'memory', kind: 'conversation_list', key: filterKey);
      return mem;
    }

    final disk = _disk.readConversationList(filterKey);
    if (disk != null) {
      diskHits++;
      _memory.putConversationList(filterKey, disk);
      ChatDebugLog.cacheHit(layer: 'disk', kind: 'conversation_list', key: filterKey);
      return disk;
    }

    misses++;
    ChatDebugLog.cacheMiss(kind: 'conversation_list', key: filterKey);
    return null;
  }

  void writeConversationList(String filterKey, List<Conversation> conversations) {
    if (conversations.isEmpty) return;
    final payload = CachedConversationList(
      conversations: conversations,
      cachedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _memory.putConversationList(filterKey, payload);
    ChatDebugLog.conversationCached(conversationId: filterKey, count: conversations.length);
    unawaited(_disk.writeConversationList(filterKey, conversations));
  }

  bool isListStale(CachedConversationList cached) {
    if (cached.cachedAtMs == 0) return true;
    return DateTime.now().millisecondsSinceEpoch - cached.cachedAtMs > maxStaleMs;
  }

  bool isMessagesStale(CachedMessagePage cached) {
    if (cached.cachedAtMs == 0) return true;
    return DateTime.now().millisecondsSinceEpoch - cached.cachedAtMs > maxStaleMs;
  }

  void setTyping(String conversationKey, bool isTyping) {
    _typingByConversation[conversationKey.trim()] = isTyping;
  }

  bool? typingStatus(String conversationKey) {
    return _typingByConversation[conversationKey.trim()];
  }

  Future<void> clearAll() async {
    _memory.clearAll();
    _typingByConversation.clear();
    _conversationMeta.clear();
    await _disk.clearAll();
  }
}
