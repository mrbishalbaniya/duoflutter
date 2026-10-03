import '../../../core/network/api_exception.dart';

/// Server moderation contract (DuoBackend `duo_project/security/text_moderation.py`).
///
/// The backend is the only place that decides what is blocked; the word list
/// never ships with the app. These helpers just recognise the refusal so the
/// UI can react immediately.
const kInappropriateContentCode = 'inappropriate_content';
const kInappropriateContentMessage = 'This message contains inappropriate language.';

/// True when a REST send failed because the server refused the text.
bool isModerationRejection(Object? error) {
  if (error is! ApiException) return false;
  final raw = error.raw;
  return raw is Map && raw['code'] == kInappropriateContentCode;
}

/// True for the WebSocket `{"type":"error","code":"inappropriate_content"}` frame.
bool isModerationWsError(Map<String, dynamic> data) =>
    data['type'] == 'error' && data['code'] == kInappropriateContentCode;

/// Text to show; prefers the server's wording, falls back to the standard one.
String moderationMessage(Object? source) {
  if (source is Map && source['message'] is String && (source['message'] as String).isNotEmpty) {
    return source['message'] as String;
  }
  if (source is ApiException && source.message.isNotEmpty) return source.message;
  return kInappropriateContentMessage;
}
