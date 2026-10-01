import 'package:flutter/material.dart';

import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';

class ChatSystemMessageBubble extends StatelessWidget {
  const ChatSystemMessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = systemEventText(message);
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatClockTime(message.timestamp),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen-capture notices: "You …" for your own, the sender's first name for
/// theirs, no icon. Returns null for events that aren't shown (recording stopped).
String? systemEventText(ChatMessage message) {
  final code = message.eventCode ?? _inferCode(message.content);
  final who = message.isMine ? 'You' : _firstName(message);
  switch (code) {
    case 'SCREENSHOT_TAKEN':
      return '$who took a screenshot';
    case 'SCREEN_RECORDING_STARTED':
      return '$who screen recorded the chat';
    case 'SCREEN_RECORDING_STOPPED':
      return null;
    default:
      return message.content;
  }
}

String? _inferCode(String content) {
  final text = content.toLowerCase();
  if (text.contains('screenshot')) return 'SCREENSHOT_TAKEN';
  if (text.contains('started screen recording') || text.contains('screen recorded')) {
    return 'SCREEN_RECORDING_STARTED';
  }
  if (text.contains('stopped screen recording')) return 'SCREEN_RECORDING_STOPPED';
  return null;
}

String _firstName(ChatMessage message) {
  final name = (message.senderName ?? '').trim();
  if (name.isNotEmpty) return name.split(RegExp(r'\s+')).first;
  // Older events only carry "<Full Name> took a screenshot."
  final content = message.content.trim();
  for (final marker in const [' took a screenshot', ' started screen recording', ' stopped screen recording', ' screen recorded']) {
    final i = content.indexOf(marker);
    if (i > 0) return content.substring(0, i).trim().split(RegExp(r'\s+')).first;
  }
  return 'Someone';
}
