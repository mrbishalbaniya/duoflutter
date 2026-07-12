import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextTheme {
  static TextTheme build(ColorScheme scheme) {
    final headline = GoogleFonts.plusJakartaSansTextTheme();
    final body = GoogleFonts.interTextTheme();

    TextStyle withColor(TextStyle? style, Color color) {
      if (style == null) return TextStyle(color: color);
      return style.copyWith(color: color);
    }

    final onSurface = scheme.onSurface;
    final onVariant = scheme.onSurfaceVariant;

    return headline.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 32,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 28,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 28,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: onSurface,
      ),
      bodyLarge: withColor(body.bodyLarge, onSurface).copyWith(fontSize: 16, height: 1.45),
      bodyMedium: withColor(body.bodyMedium, onSurface).copyWith(fontSize: 14, height: 1.4),
      bodySmall: withColor(body.bodySmall, onVariant).copyWith(fontSize: 12, height: 1.35),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: onVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: onVariant,
      ),
    );
  }
}
