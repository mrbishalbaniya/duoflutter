import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

class GoogleSignInCredentials {
  const GoogleSignInCredentials.idToken(this.idToken)
      : code = null,
        redirectUri = null;

  const GoogleSignInCredentials.authorizationCode({
    required this.code,
    required this.redirectUri,
  }) : idToken = null;

  final String? idToken;
  final String? code;
  final String? redirectUri;
}

class GoogleAuthService {
  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? AppConfig.googleWebClientId : null,
          serverClientId: AppConfig.googleWebClientId,
          scopes: const ['email', 'profile'],
        );

  final GoogleSignIn _googleSignIn;

  Future<GoogleSignInCredentials?> signIn() async {
    if (!AppConfig.isGoogleAuthConfigured) {
      throw StateError('Google sign-in is not configured.');
    }

    if (kIsWeb) {
      final idToken = await _signInWithNativeIdToken();
      return idToken == null ? null : GoogleSignInCredentials.idToken(idToken);
    }

    return _signInWithBrowserOAuth();
  }

  Future<String?> signInAndGetIdToken() async {
    final credentials = await signIn();
    return credentials?.idToken;
  }

  Future<String?> _signInWithNativeIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }
    return idToken;
  }

  Future<GoogleSignInCredentials?> _signInWithBrowserOAuth() async {
    final redirectUri = AppConfig.googleOAuthRedirectUri;
    final authUrl = Uri.https(
      'accounts.google.com',
      '/o/oauth2/v2/auth',
      <String, String>{
        'client_id': AppConfig.googleWebClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'access_type': 'online',
        'prompt': 'select_account',
        'state': AppConfig.googleMobileOAuthState,
      },
    );

    try {
      final callback = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: AppConfig.googleOAuthCallbackScheme,
        options: const FlutterWebAuth2Options(
          intentFlags: 0,
        ),
      );

      final callbackUri = Uri.parse(callback);
      final error = callbackUri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        if (error == 'access_denied') {
          return null;
        }
        throw StateError('Google sign-in failed ($error).');
      }

      final code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw StateError('Google did not return an authorization code.');
      }

      return GoogleSignInCredentials.authorizationCode(
        code: code,
        redirectUri: redirectUri,
      );
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
