import 'api_exception.dart';

/// HTTP 429 from an OTP endpoint: a code was sent recently (web `OtpCooldownError`).
class OtpCooldownException implements Exception {
  const OtpCooldownException(this.retryAfter, [this.message]);

  final int retryAfter;
  final String? message;

  @override
  String toString() => message ?? 'Please wait ${retryAfter}s before requesting another code.';
}

/// Seconds from an OTP response body, defaulting like web (60).
int otpRetryAfter(Object? data) {
  if (data is Map && data['retry_after'] is num) return (data['retry_after'] as num).toInt();
  return 60;
}

/// Rethrows a 429 as [OtpCooldownException]; other errors pass through.
Never rethrowOtpError(ApiException e) {
  if (e.statusCode == 429) {
    throw OtpCooldownException(otpRetryAfter(e.raw), e.message);
  }
  throw e;
}
