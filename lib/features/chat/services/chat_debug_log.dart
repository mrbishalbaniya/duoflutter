import 'package:flutter/foundation.dart';

/// Structured chat diagnostics (debug builds only).
abstract final class ChatDebugLog {
  static void sendStart({
    required String conversationId,
    required String tempId,
    required String channel,
  }) {
    _log('send_start', {
      'conversation': conversationId,
      'tempId': tempId,
      'channel': channel,
    });
  }

  static void sendSuccess({
    required String tempId,
    required int latencyMs,
    required String channel,
  }) {
    _log('send_success', {
      'tempId': tempId,
      'latencyMs': latencyMs,
      'channel': channel,
    });
  }

  static void sendFailure({
    required String tempId,
    required String error,
    required int latencyMs,
  }) {
    _log('send_failure', {
      'tempId': tempId,
      'error': error,
      'latencyMs': latencyMs,
    });
  }

  static void messageIn({
    required String type,
    required String conversationId,
    String? tempId,
    int? messageId,
  }) {
    _log('message_in', {
      'type': type,
      'conversation': conversationId,
      if (tempId != null) 'tempId': tempId,
      if (messageId != null) 'messageId': messageId,
    });
  }

  static void messageOut({
    required String type,
    required String conversationId,
    int? latencyMs,
  }) {
    _log('message_out', {
      'type': type,
      'conversation': conversationId,
      if (latencyMs != null) 'latencyMs': latencyMs,
    });
  }

  static void typing({
    required bool isTyping,
    required String conversationId,
    bool incoming = false,
  }) {
    _log(incoming ? 'typing_in' : 'typing_out', {
      'conversation': conversationId,
      'isTyping': isTyping,
    });
  }

  static void wsStatus({
    required String status,
    required String conversationId,
    int? latencyMs,
    int? attempt,
  }) {
    _log('ws_$status', {
      'conversation': conversationId,
      if (latencyMs != null) 'latencyMs': latencyMs,
      if (attempt != null) 'attempt': attempt,
    });
  }

  static void duplicateEvent({
    required String type,
    required String conversationId,
    String? tempId,
  }) {
    _log('duplicate_event', {
      'type': type,
      'conversation': conversationId,
      if (tempId != null) 'tempId': tempId,
    });
  }

  static void providerRebuild({
    required String provider,
    required String reason,
  }) {
    _log('provider_rebuild', {'provider': provider, 'reason': reason});
  }

  static void cacheHit({
    required String layer,
    required String kind,
    required String key,
  }) {
    _log('cache_hit', {'layer': layer, 'kind': kind, 'key': key});
  }

  static void cacheMiss({required String kind, required String key}) {
    _log('cache_miss', {'kind': kind, 'key': key});
  }

  static void messageCached({
    required String conversationKey,
    required int count,
  }) {
    _log('message_cached', {'conversation': conversationKey, 'count': count});
  }

  static void conversationCached({
    required String conversationId,
    int? count,
  }) {
    _log('conversation_cached', {
      'conversation': conversationId,
      if (count != null) 'count': count,
    });
  }

  static void apiRequest({
    required String endpoint,
    String? conversationId,
  }) {
    _log('api_request', {
      'endpoint': endpoint,
      if (conversationId != null) 'conversation': conversationId,
    });
  }

  static void apiResponse({
    required String endpoint,
    required int latencyMs,
    int? count,
  }) {
    _log('api_response', {
      'endpoint': endpoint,
      'latencyMs': latencyMs,
      if (count != null) 'count': count,
    });
  }

  static void imageCached({required String url}) {
    _log('image_cached', {'url': url});
  }

  static void cacheStats({
    required int memoryHits,
    required int diskHits,
    required int misses,
    required double hitRatio,
  }) {
    _log('cache_stats', {
      'memoryHits': memoryHits,
      'diskHits': diskHits,
      'misses': misses,
      'hitRatio': hitRatio.toStringAsFixed(2),
    });
  }

  static void screenshotDetected() {
    _log('screenshot_detected', {});
  }

  static void recordingStarted() {
    _log('recording_started', {});
  }

  static void recordingStopped() {
    _log('recording_stopped', {});
  }

  static void securityEventOut({
    required String eventCode,
    required String conversationId,
    required String channel,
  }) {
    _log('security_event_out', {
      'eventCode': eventCode,
      'conversation': conversationId,
      'channel': channel,
    });
  }

  static void securityEventAck({
    required String eventCode,
    required String conversationId,
    int? messageId,
    required String channel,
  }) {
    _log('security_event_ack', {
      'eventCode': eventCode,
      'conversation': conversationId,
      if (messageId != null) 'messageId': messageId,
      'channel': channel,
    });
  }

  static void systemMessageCreated({
    required int messageId,
    required String conversationId,
    required String eventCode,
  }) {
    _log('system_message_created', {
      'messageId': messageId,
      'conversation': conversationId,
      'eventCode': eventCode,
    });
  }

  static void conversationUpdated({
    required String conversationId,
    String? reason,
  }) {
    _log('conversation_updated', {
      'conversation': conversationId,
      if (reason != null) 'reason': reason,
    });
  }

  static void screenCaptureWatching({required bool enabled}) {
    _log('screen_capture_watch', {'enabled': enabled});
  }

  static void screenCaptureUnsupported() {
    _log('screen_capture_unsupported', {});
  }

  static void screenCaptureError(String stage, String error) {
    _log('screen_capture_error', {'stage': stage, 'error': error});
  }

  static void secureChatMode({required bool enabled}) {
    _log('secure_chat_mode', {'enabled': enabled});
  }

  static void emojiPickerOpened() {
    _log('emoji_picker_opened', {});
  }

  static void emojiPickerClosed() {
    _log('emoji_picker_closed', {});
  }

  static void emojiSelected({required String emoji}) {
    _log('emoji_selected', {'emoji': emoji});
  }

  static void emojiInserted({
    required String emoji,
    required int cursor,
    required int length,
  }) {
    _log('emoji_inserted', {
      'emoji': emoji,
      'cursor': cursor,
      'length': length,
    });
  }

  static void keyboardOpened() {
    _log('keyboard_opened', {});
  }

  static void keyboardClosed() {
    _log('keyboard_closed', {});
  }

  static void sendButtonState({required bool enabled, required int textLength}) {
    _log('send_button_state', {'enabled': enabled, 'textLength': textLength});
  }

  static void _log(String event, Map<String, Object?> data) {
    if (kDebugMode) {
      debugPrint('[ChatDebug] $event $data');
    }
  }
}
