import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duo_mobile/core/network/api_exception.dart';

void main() {
  test('ApiException maps detail field from Dio error', () {
    final exception = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'detail': 'Invalid credentials.'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(exception.message, 'Invalid credentials.');
    expect(exception.statusCode, 400);
  });
}
