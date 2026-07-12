import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette aligned with DuoFrontend `globals.css` (dark + `html.light` overrides).
abstract final class DuoColors {
  static const primary = Color(0xFFE84A7A);
  static const primaryContainer = Color(0xFFC83C67);
  static const accent = Color(0xFFD4A574);
  static const love = Color(0xFFFF4D6D);
  static const tertiary = Color(0xFF8B5CF6);
  static const error = Color(0xFFEF4444);

  static const backgroundDark = Color(0xFF0F0F10);
  static const surfaceDark = Color(0xFF17181A);
  static const surfaceVariantDark = Color(0xFF202225);
  static const surfaceContainerDark = Color(0xFF1B1D20);
  static const surfaceContainerHighDark = Color(0xFF25272B);
  static const surfaceContainerHighestDark = Color(0xFF2D3035);
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceVariantDark = Color(0xFFB0B3BA);
  static const outlineDark = Color(0xFF2F3136);
  static const outlineVariantDark = Color(0xFF374151);

  static const backgroundLight = Color(0xFFF7F7F8);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF3F4F6);
  static const surfaceContainerLight = Color(0xFFFFFFFF);
  static const surfaceContainerLowLight = Color(0xFFF9FAFB);
  static const surfaceContainerHighLight = Color(0xFFEEF0F2);
  static const surfaceContainerHighestLight = Color(0xFFE5E7EB);
  static const secondaryLight = Color(0xFFF3F4F6);
  static const onSurfaceLight = Color(0xFF111827);
  static const onSurfaceVariantLight = Color(0xFF4B5563);
  static const outlineLight = Color(0xFFE5E7EB);
  static const outlineVariantLight = Color(0xFFD1D5DB);

  static const esewaGreen = Color(0xFF60BB46);
}

abstract final class DuoTypography {
  static TextTheme textTheme(Brightness brightness) {
    final headline = GoogleFonts.plusJakartaSansTextTheme();
    final body = GoogleFonts.interTextTheme();
    return headline.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w800,
        fontSize: 32,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }
}

abstract final class DuoTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: DuoColors.primary,
      onPrimary: Colors.white,
      primaryContainer: DuoColors.primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: isDark ? DuoColors.surfaceVariantDark : DuoColors.secondaryLight,
      onSecondary: isDark ? DuoColors.onSurfaceDark : DuoColors.onSurfaceLight,
      tertiary: DuoColors.tertiary,
      onTertiary: Colors.white,
      error: DuoColors.error,
      onError: Colors.white,
      surface: isDark ? DuoColors.surfaceDark : DuoColors.surfaceLight,
      onSurface: isDark ? DuoColors.onSurfaceDark : DuoColors.onSurfaceLight,
      onSurfaceVariant:
          isDark ? DuoColors.onSurfaceVariantDark : DuoColors.onSurfaceVariantLight,
      outline: isDark ? DuoColors.outlineDark : DuoColors.outlineLight,
      outlineVariant:
          isDark ? DuoColors.outlineVariantDark : DuoColors.outlineVariantLight,
      surfaceContainerHighest: isDark
          ? DuoColors.surfaceContainerHighestDark
          : DuoColors.surfaceContainerHighestLight,
      surfaceContainerHigh: isDark
          ? DuoColors.surfaceContainerHighDark
          : DuoColors.surfaceContainerHighLight,
      surfaceContainer:
          isDark ? DuoColors.surfaceContainerDark : DuoColors.surfaceContainerLight,
      surfaceContainerLow:
          isDark ? DuoColors.surfaceDark : DuoColors.surfaceContainerLowLight,
      surfaceContainerLowest:
          isDark ? DuoColors.backgroundDark : DuoColors.surfaceVariantLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? DuoColors.backgroundDark : DuoColors.backgroundLight,
      textTheme: DuoTypography.textTheme(brightness),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: isDark ? 0.4 : 0.55),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 28,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? DuoColors.surfaceContainerDark : DuoColors.surfaceContainerLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? DuoColors.primary.withValues(alpha: 0.08)
                : colorScheme.outline.withValues(alpha: 0.55),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? DuoColors.surfaceVariantDark : DuoColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DuoColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DuoColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: DuoColors.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? DuoColors.surfaceDark : DuoColors.surfaceLight,
        indicatorColor: DuoColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? DuoColors.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? DuoColors.surfaceContainerHighDark : DuoColors.onSurfaceLight,
        contentTextStyle: TextStyle(
          color: isDark ? DuoColors.onSurfaceDark : DuoColors.backgroundLight,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
