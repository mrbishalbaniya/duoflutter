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

  static const appName = 'Duo';

  static bool get isGoogleAuthConfigured => googleWebClientId.isNotEmpty;
}
