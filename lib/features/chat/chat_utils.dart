import 'package:intl/intl.dart';

import '../../core/models/chat_models.dart';
import 'domain/chat_emoji_constants.dart';
import 'domain/chat_message_list_entry.dart';

const voiceMessageLabel = ChatEmojiConstants.voiceMessageLabel;

const quickReactionEmojis = ChatEmojiConstants.quickReactions;

const composerEmojis = ChatEmojiConstants.composerPicker;

List<ChatMessage> sortMessages(List<ChatMessage> messages) {
  final copy = List<ChatMessage>.from(messages);
  copy.sort((a, b) {
    final aTime = _parseDate(a.timestamp);
    final bTime = _parseDate(b.timestamp);
    if (aTime != bTime) return aTime.compareTo(bTime);
    return a.id.compareTo(b.id);
  });
  return copy;
}

bool isVoiceMessage(ChatMessage msg) {
  if (msg.content == voiceMessageLabel) return true;
  final url = msg.imageUrl ?? '';
  return RegExp(r'\.(webm|ogg|mp3|wav|m4a|aac)(\?|$)', caseSensitive: false).hasMatch(url);
}

bool isImageOnlyMessage(ChatMessage msg) {
  if (!msg.isMine || msg.isDeletedForEveryone) return false;
  if (isVoiceMessage(msg)) return false;
  if (msg.messageType == 'image') return true;
  if (msg.localMediaPath != null && msg.localMediaPath!.isNotEmpty) return true;
  return (msg.imageUrl?.isNotEmpty ?? false) && msg.content.trim().isEmpty;
}

bool isVoiceOnlyMessage(ChatMessage msg) {
  if (!isVoiceMessage(msg) || msg.isDeletedForEveryone) return false;
  if (msg.imageUrl?.isEmpty ?? true) return false;
  final text = msg.content.trim();
  return text.isEmpty || text == voiceMessageLabel;
}

String lastMessagePreview(Conversation convo) {
  final last = convo.lastMessage;
  if (last == null) return 'Start the conversation!';
  if (last.isSystemMessage) {
    return last.content.isNotEmpty ? last.content : 'Security event';
  }
  if (last.isDeletedForEveryone) return 'Message deleted';
  if (isVoiceMessage(last)) return voiceMessageLabel;
  if (last.imageUrl?.isNotEmpty ?? false) {
    return last.content.trim().isEmpty ? '📷 Photo' : last.content;
  }
  return last.content.isNotEmpty ? last.content : 'Start the conversation!';
}

String? conversationActivityIso(Conversation convo) {
  return convo.lastMessageAt ?? convo.lastMessage?.timestamp;
}

List<Conversation> sortConversations(List<Conversation> items) {
  final copy = List<Conversation>.from(items);
  copy.sort((a, b) {
    final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
    if (pin != 0) return pin;
    final aTime = _parseDate(conversationActivityIso(a));
    final bTime = _parseDate(conversationActivityIso(b));
    return bTime.compareTo(aTime);
  });
  return copy;
}

List<Conversation> filterConversations({
  required List<Conversation> items,
  required String query,
  required bool unreadOnly,
}) {
  var result = items;
  if (unreadOnly) {
    result = result.where((c) => c.unreadCount > 0).toList();
  }
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return result;
  return result.where((c) {
    final name = c.displayName.toLowerCase();
    final preview = lastMessagePreview(c).toLowerCase();
    return name.contains(q) || preview.contains(q);
  }).toList();
}

int totalUnreadCount(List<Conversation> items) {
  return items.fold(0, (sum, c) => sum + c.unreadCount);
}

String formatMessageTime(String? iso) {
  final date = _parseDate(iso);
  if (date.millisecondsSinceEpoch == 0) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (date.year == DateTime.now().year) {
    return DateFormat.MMMd().format(date);
  }
  return DateFormat.yMMMd().format(date);
}

String formatClockTime(String? iso) {
  final date = _parseDate(iso);
  if (date.millisecondsSinceEpoch == 0) return '';
  return DateFormat.jm().format(date);
}

String dateSeparatorLabel(String? iso) {
  final date = _parseDate(iso);
  if (date.millisecondsSinceEpoch == 0) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (now.difference(day).inDays < 7) return DateFormat.EEEE().format(date);
  return DateFormat.yMMMMd().format(date);
}

bool shouldShowDateSeparator(ChatMessage current, ChatMessage? previous) {
  if (previous == null) return true;
  final a = _parseDate(current.timestamp);
  final b = _parseDate(previous.timestamp);
  return DateTime(a.year, a.month, a.day) != DateTime(b.year, b.month, b.day);
}

bool isGroupedWithPrevious(ChatMessage current, ChatMessage? previous) {
  if (previous == null) return false;
  if (current.isSystemMessage || previous.isSystemMessage) return false;
  if (current.isMine != previous.isMine) return false;
  final a = _parseDate(current.timestamp);
  final b = _parseDate(previous.timestamp);
  return a.difference(b).inMinutes.abs() < 5;
}

List<ChatMessageListEntry> buildMessageListEntries(List<ChatMessage> messages) {
  if (messages.isEmpty) return const [];

  final entries = <ChatMessageListEntry>[];
  ChatMessage? previous;

  for (final message in messages) {
    if (!message.isVisible) continue;

    final grouped = message.isSystemMessage ? false : isGroupedWithPrevious(message, previous);
    final showDate = shouldShowDateSeparator(message, previous);

    entries.add(
      ChatMessageListEntry(
        message: message,
        showDateSeparator: showDate,
        dateLabel: showDate ? dateSeparatorLabel(message.timestamp) : '',
        showAvatar: !grouped && !message.isSystemMessage,
        isGrouped: grouped,
        isSystemMessage: message.isSystemMessage,
      ),
    );
    previous = message;
  }

  return entries;
}

bool isAnimatedImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return RegExp(r'\.gif(\?|$)', caseSensitive: false).hasMatch(url);
}

String replyPreview(ChatMessage msg, {String? fallbackName}) {
  if (msg.isDeletedForEveryone) return 'Message deleted';
  if (isVoiceMessage(msg)) return voiceMessageLabel;
  if (msg.imageUrl?.isNotEmpty ?? false) {
    return msg.content.trim().isEmpty ? '📷 Photo' : msg.content;
  }
  final text = msg.content.trim();
  if (text.isNotEmpty) {
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }
  return fallbackName != null ? 'Message from $fallbackName' : 'Message';
}

String matchSubtitle(String? matchCreatedAt) {
  final date = _parseDate(matchCreatedAt);
  if (date.millisecondsSinceEpoch == 0) return 'Your match';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'Matched ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Matched ${diff.inHours}h ago';
  return 'Matched ${diff.inDays}d ago';
}

DateTime _parseDate(String? iso) {
  if (iso == null || iso.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
