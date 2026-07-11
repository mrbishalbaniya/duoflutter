/// Runtime configuration via `--dart-define`.
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://duobackend.onrender.com/api',
  );

  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://duobackend.onrender.com',
  );

  /// Web OAuth client ID — must match DuoBackend `GOOGLE_OAUTH_CLIENT_ID`.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '599462036385-39dkh9btr5cslp7faegprvmc3haca5ac.apps.googleusercontent.com',
  );

  static const appName = 'Duo';

  static bool get isGoogleAuthConfigured => googleWebClientId.isNotEmpty;
}
