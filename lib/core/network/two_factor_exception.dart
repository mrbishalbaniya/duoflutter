import '../../features/security/models/security_models.dart';

class TwoFactorRequiredException implements Exception {
  TwoFactorRequiredException(this.challenge);

  final TwoFactorLoginChallenge challenge;

  @override
  String toString() => 'Two-factor authentication required';
}
