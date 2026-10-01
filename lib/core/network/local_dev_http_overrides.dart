import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Local development only: seeded/dev data stores media as absolute
/// `http://localhost:8000/media/...` URLs. On a physical phone "localhost" is the
/// phone itself, so every such image fails. When a debug build points at a plain
/// HTTP LAN backend (e.g. `http://192.168.1.5:8000/api` from env/local.json), send
/// any connection for a loopback host on that port to the LAN backend instead.
///
/// URLs themselves are never rewritten, so nothing wrong can be saved back to the
/// server, and release/HTTPS builds never install this override.
void installLocalDevHttpOverrides() {
  if (!kDebugMode) return;
  final api = Uri.tryParse(AppConfig.apiBaseUrl);
  if (api == null || api.scheme != 'http' || api.host.isEmpty) return;
  if (_loopback.contains(api.host)) return; // emulator/desktop: loopback already works
  HttpOverrides.global = _LocalDevHttpOverrides(api.host, api.port);
}

const _loopback = {'localhost', '127.0.0.1', '0.0.0.0', '::1'};

class _LocalDevHttpOverrides extends HttpOverrides {
  _LocalDevHttpOverrides(this.lanHost, this.port);

  final String lanHost;
  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // Mirrors HttpClient's default connect logic, except loopback on the API port.
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      if (proxyHost != null && proxyPort != null) {
        return Socket.startConnect(proxyHost, proxyPort); // plain socket to proxy, as default
      }
      if (_loopback.contains(uri.host) && uri.port == port) {
        return Socket.startConnect(lanHost, port);
      }
      return uri.scheme == 'https'
          ? SecureSocket.startConnect(uri.host, uri.port, context: context)
          : Socket.startConnect(uri.host, uri.port);
    };
    return client;
  }
}
