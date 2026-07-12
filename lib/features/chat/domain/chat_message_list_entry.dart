import '../../../core/models/chat_models.dart';
import 'chat_message_selectors.dart';

/// Precomputed row metadata for the message list — avoids per-frame grouping work.
class ChatMessageListEntry {
  const ChatMessageListEntry({
    required this.message,
    this.showDateSeparator = false,
    this.dateLabel = '',
    this.showAvatar = true,
    this.isGrouped = false,
    this.isSystemMessage = false,
  });

  final ChatMessage message;
  final bool showDateSeparator;
  final String dateLabel;
  final bool showAvatar;
  final bool isGrouped;
  final bool isSystemMessage;

  String get stableKey =>
      chatMessageStableKey(message);
}
