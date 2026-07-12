import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Preloads branding assets and fonts before leaving splash.
class SplashPreloader {
  SplashPreloader._();

  static const lottieAsset = 'assets/lottie/duo_glow.json';

  static Future<void> preload() async {
    await Future.wait([
      _preloadFonts(),
      _preloadLottie(),
    ]);
  }

  static Future<void> _preloadFonts() async {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
    ]);
  }

  static Future<void> _preloadLottie() async {
    try {
      final composition = await AssetLottie(lottieAsset).load();
      Lottie.cache.putIfAbsent(lottieAsset, () => Future.value(composition));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Splash Lottie preload skipped: $e');
      }
    }
  }
}
