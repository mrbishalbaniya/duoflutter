import '../../../core/models/chat_models.dart';
import '../chat_utils.dart';

/// Whether a chat message contains savable image/video/gif media.
bool hasSavableChatMedia(ChatMessage msg) {
  if (msg.isDeletedForEveryone || msg.isSystemMessage) return false;
  if (isVoiceMessage(msg)) return false;
  if (msg.localMediaPath != null && msg.localMediaPath!.isNotEmpty) return true;
  final url = msg.imageUrl ?? '';
  return url.isNotEmpty;
}

/// Image is the primary content (not a small attachment under text).
bool isImageDominantMessage(ChatMessage msg) {
  if (!hasSavableChatMedia(msg)) return false;
  if (msg.messageType == 'image') return true;
  if (msg.localMediaPath != null && msg.localMediaPath!.isNotEmpty) {
    return msg.content.trim().isEmpty;
  }
  return msg.content.trim().isEmpty && (msg.imageUrl?.isNotEmpty ?? false);
}

bool isVideoMediaUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return RegExp(
    r'\.(mp4|mov|m4v|webm|mkv|avi|3gp)(\?|$)',
    caseSensitive: false,
  ).hasMatch(url);
}

bool isGifMediaUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return RegExp(r'\.gif(\?|$)', caseSensitive: false).hasMatch(url);
}

String mediaFileExtension({String? url, String? localPath}) {
  final source = (localPath?.isNotEmpty ?? false) ? localPath! : (url ?? '');
  if (source.isEmpty) return '.jpg';
  final uri = Uri.tryParse(source);
  final path = uri?.path ?? source;
  final dot = path.lastIndexOf('.');
  if (dot >= 0 && dot < path.length - 1) {
    final ext = path.substring(dot).toLowerCase();
    if (ext.length <= 6) return ext;
  }
  if (isVideoMediaUrl(url)) return '.mp4';
  if (isGifMediaUrl(url)) return '.gif';
  return '.jpg';
}

String mediaTypeLabel({String? url, String? localPath}) {
  if (isVideoMediaUrl(url) || isVideoMediaUrl(localPath)) return 'Video';
  if (isGifMediaUrl(url) || isGifMediaUrl(localPath)) return 'GIF';
  return 'Photo';
}
