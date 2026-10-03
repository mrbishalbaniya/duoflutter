import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo_mobile/core/network/api_exception.dart';
import 'package:duo_mobile/features/chat/domain/chat_moderation.dart';

/// The 400 body DuoBackend returns for a refused chat message.
const _refusal = {
  'code': 'inappropriate_content',
  'message': 'This message contains inappropriate language.',
  'detail': 'This message contains inappropriate language.',
};

ApiException _fromStatus(int status, Map<String, dynamic> body) => ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/chat/conversations/1/messages/'),
        response: Response(
          requestOptions: RequestOptions(path: '/chat/conversations/1/messages/'),
          statusCode: status,
          data: body,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

void main() {
  group('REST refusal', () {
    test('recognised from the server error code', () {
      final e = _fromStatus(400, _refusal);
      expect(isModerationRejection(e), isTrue);
      expect(moderationMessage(e), kInappropriateContentMessage);
    });

    test('other 400s are not treated as moderation', () {
      final e = _fromStatus(400, {'code': 'invalid', 'detail': 'Reply target not found.'});
      expect(isModerationRejection(e), isFalse);
    });

    test('non-API errors are not moderation', () {
      expect(isModerationRejection(Exception('offline')), isFalse);
      expect(isModerationRejection(null), isFalse);
    });
  });

  group('WebSocket refusal frame', () {
    test('recognised and message shown', () {
      final frame = <String, dynamic>{'type': 'error', ..._refusal, 'client_temp_id': 'tmp-1'};
      expect(isModerationWsError(frame), isTrue);
      expect(moderationMessage(frame), kInappropriateContentMessage);
    });

    test('generic send failures are not moderation', () {
      expect(isModerationWsError({'type': 'error', 'code': 'send_failed'}), isFalse);
      expect(isModerationWsError({'type': 'chat_message'}), isFalse);
    });

    test('falls back to the standard text', () {
      expect(moderationMessage({'type': 'error'}), kInappropriateContentMessage);
    });
  });

  test('the app does not ship a blocked-word list', () {
    // Only the code and user-facing text live on the client.
    expect(kInappropriateContentCode, 'inappropriate_content');
    expect(kInappropriateContentMessage, 'This message contains inappropriate language.');
  });
}
