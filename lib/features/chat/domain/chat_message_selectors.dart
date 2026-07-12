import '../../../core/models/chat_models.dart';
import 'chat_message_list_entry.dart';

/// Stable list identity for a message row.
String chatMessageStableKey(ChatMessage message) {
  if (message.clientTempId?.isNotEmpty == true) {
    return message.clientTempId!;
  }
  return 'id-${message.id}';
}

ChatMessage? chatMessageForKey(List<ChatMessage> messages, String messageKey) {
  for (final message in messages) {
    if (chatMessageStableKey(message) == messageKey) {
      return message;
    }
  }
  return null;
}

Map<String, ChatMessage> buildMessagesByKey(List<ChatMessage> messages) {
  final map = <String, ChatMessage>{};
  for (final message in messages) {
    map[chatMessageStableKey(message)] = message;
  }
  return map;
}

/// Lightweight structural fingerprint — list rebuilds only when layout changes.
int chatListStructureRevision(List<ChatMessageListEntry> entries) {
  var hash = entries.length;
  for (final entry in entries) {
    hash = Object.hash(
      hash,
      entry.stableKey,
      entry.showDateSeparator,
      entry.showAvatar,
      entry.isGrouped,
    );
  }
  return hash;
}
