import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

class GoogleAuthService {
  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? AppConfig.googleWebClientId : null,
          serverClientId: AppConfig.googleWebClientId,
          scopes: const ['email', 'profile'],
        );

  final GoogleSignIn _googleSignIn;

  Future<String?> signInAndGetIdToken() async {
    if (!AppConfig.isGoogleAuthConfigured) {
      throw StateError('Google sign-in is not configured.');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }
    return idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
