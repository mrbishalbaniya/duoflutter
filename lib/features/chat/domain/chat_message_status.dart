import '../../../core/models/chat_models.dart';

/// Mirrors Next.js `messageStatus.ts`.
MessageSendStatus resolveSendStatus(ChatMessage msg) {
  if (msg.sendStatus == MessageSendStatus.pending ||
      msg.sendStatus == MessageSendStatus.failed) {
    return msg.sendStatus;
  }
  if (msg.id <= 0) return MessageSendStatus.pending;
  return MessageSendStatus.sent;
}

bool isMessageDelivered(ChatMessage msg) {
  return msg.deliveredAt != null || msg.isRead || msg.readAt != null;
}

bool isMessageRead(ChatMessage msg) {
  return msg.isRead || msg.readAt != null;
}

enum MessageStatusIcon { pending, sent, delivered, read, failed }

MessageStatusIcon messageStatusIcon(ChatMessage msg) {
  final status = resolveSendStatus(msg);
  if (status == MessageSendStatus.pending) return MessageStatusIcon.pending;
  if (status == MessageSendStatus.failed) return MessageStatusIcon.failed;
  if (isMessageRead(msg)) return MessageStatusIcon.read;
  if (isMessageDelivered(msg)) return MessageStatusIcon.delivered;
  return MessageStatusIcon.sent;
}
