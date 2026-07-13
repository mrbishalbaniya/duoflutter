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

  /// Builds a WebSocket [Uri] with a valid ws/wss scheme and default ports.
  static Uri webSocketUri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = _normalizedWsBase();
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: normalizedPath,
      queryParameters: queryParameters,
    );
  }

  static Uri _normalizedWsBase() {
    var raw = wsBaseUrl.trim();
    if (raw.isEmpty) {
      raw = _deriveWsBaseFromApi(apiBaseUrl);
    }

    var uri = Uri.parse(raw);
    var scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') {
      scheme = 'wss';
    } else if (scheme == 'http') {
      scheme = 'ws';
    } else if (scheme.isEmpty) {
      scheme = 'wss';
      uri = Uri.parse('wss://$raw');
    }

    final port = uri.hasPort && uri.port > 0 ? uri.port : null;
    return Uri(scheme: scheme, host: uri.host, port: port);
  }

  static String _deriveWsBaseFromApi(String apiUrl) {
    final uri = Uri.parse(apiUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort && uri.port > 0 ? uri.port : null;
    return Uri(scheme: scheme, host: uri.host, port: port).toString();
  }

  /// Web OAuth client ID — must match DuoBackend `GOOGLE_OAUTH_CLIENT_ID`.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '599462036385-39dkh9btr5cslp7faegprvmc3haca5ac.apps.googleusercontent.com',
  );

  /// Custom URL scheme used by [flutter_web_auth_2] on Android/iOS.
  static const googleOAuthCallbackScheme = 'com.duo.duo_mobile';

  /// OAuth `state` value that tells DuoBackend to return to the mobile app.
  static const googleMobileOAuthState = 'duo_mobile';

  /// Google OAuth redirect URI — must match DuoBackend `/api/auth/google/callback/`
  /// and be listed under the Web client in Google Cloud Console.
  static String get googleOAuthRedirectUri {
    final api = Uri.parse(apiBaseUrl);
    final origin = Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
    );
    return '${origin.toString()}/api/auth/google/callback'.replaceAll(RegExp(r'/$'), '');
  }

  static const appName = 'Duo';

  /// eSewa native SDK credentials — configure via `--dart-define` (never fetch from API).
  static const esewaMobileClientId = String.fromEnvironment('ESEWA_MOBILE_CLIENT_ID');
  static const esewaMobileSecretId = String.fromEnvironment('ESEWA_MOBILE_SECRET_ID');
  static const esewaMobileEnvironment = String.fromEnvironment(
    'ESEWA_MOBILE_ENVIRONMENT',
    defaultValue: 'test',
  );

  static bool get isEsewaNativeSdkConfigured =>
      esewaMobileClientId.isNotEmpty && esewaMobileSecretId.isNotEmpty;

  static bool get isGoogleAuthConfigured => googleWebClientId.isNotEmpty;
}
