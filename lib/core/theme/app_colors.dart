import 'package:flutter/material.dart';

/// Design tokens translated from DuoFrontend `app/globals.css`.
abstract final class AppColors {
  // --- Brand ---
  static const primary = Color(0xFFE84A7A);
  static const primaryContainer = Color(0xFFC83C67);
  static const primaryFixed = Color(0xFFFFD6E1);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFFFFFFF);

  static const accent = Color(0xFFD4A574);
  static const accentContainer = Color(0xFFF4E4CF);
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentContainer = Color(0xFF3A2410);

  static const love = Color(0xFFFF4D6D);
  static const loveContainer = Color(0xFFFFCCD5);

  static const tertiary = Color(0xFF8B5CF6);
  static const tertiaryContainer = Color(0xFFEDE9FE);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF2E1065);

  static const premium = Color(0xFFD4A574);
  static const premiumContainer = Color(0xFFF4E4CF);

  static const error = Color(0xFFEF4444);
  static const errorContainerDark = Color(0xFFFEE2E2);
  static const onError = Color(0xFFFFFFFF);
  static const onErrorContainerDark = Color(0xFF7F1D1D);
  static const onErrorContainerLight = Color(0xFF7F1D1D);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // --- Dark surfaces (default) ---
  static const backgroundDark = Color(0xFF0F0F10);
  static const onBackgroundDark = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF17181A);
  static const surfaceBrightDark = Color(0xFF232428);
  static const surfaceDimDark = Color(0xFF101113);
  static const surfaceVariantDark = Color(0xFF202225);
  static const surfaceContainerDark = Color(0xFF1B1D20);
  static const surfaceContainerLowDark = Color(0xFF151618);
  static const surfaceContainerHighDark = Color(0xFF25272B);
  static const surfaceContainerHighestDark = Color(0xFF2D3035);
  static const onSurfaceDark = Color(0xFFFFFFFF);
  static const onSurfaceVariantDark = Color(0xFFB0B3BA);
  static const mutedDark = Color(0xFF202225);
  static const mutedForegroundDark = Color(0xFF9CA3AF);
  static const borderDark = Color(0xFF2F3136);
  static const outlineDark = Color(0xFF6B7280);
  static const outlineVariantDark = Color(0xFF374151);
  static const inputDark = Color(0xFF2F3136);
  static const secondaryDark = Color(0xFF17181A);
  static const secondaryContainerDark = Color(0xFF202225);
  static const onSecondaryDark = Color(0xFFFFFFFF);

  // --- Light surfaces (`html.light`) ---
  static const backgroundLight = Color(0xFFF7F7F8);
  static const onBackgroundLight = Color(0xFF111827);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceBrightLight = Color(0xFFFFFFFF);
  static const surfaceDimLight = Color(0xFFEEF0F2);
  static const surfaceVariantLight = Color(0xFFF3F4F6);
  static const surfaceContainerLight = Color(0xFFFFFFFF);
  static const surfaceContainerLowLight = Color(0xFFF9FAFB);
  static const surfaceContainerLowestLight = Color(0xFFF3F4F6);
  static const surfaceContainerHighLight = Color(0xFFEEF0F2);
  static const surfaceContainerHighestLight = Color(0xFFE5E7EB);
  static const onSurfaceLight = Color(0xFF111827);
  static const onSurfaceVariantLight = Color(0xFF4B5563);
  static const mutedLight = Color(0xFFF3F4F6);
  static const mutedForegroundLight = Color(0xFF6B7280);
  static const borderLight = Color(0xFFE5E7EB);
  static const outlineLight = Color(0xFF9CA3AF);
  static const outlineVariantLight = Color(0xFFD1D5DB);
  static const inputLight = Color(0xFFE5E7EB);
  static const secondaryLight = Color(0xFFF3F4F6);
  static const secondaryContainerLight = Color(0xFFE5E7EB);
  static const onSecondaryLight = Color(0xFF111827);

  static const inverseSurfaceDark = Color(0xFFFFFFFF);
  static const inverseOnSurfaceDark = Color(0xFF0F0F10);
  static const inverseSurfaceLight = Color(0xFF111827);
  static const inverseOnSurfaceLight = Color(0xFFF9FAFB);

  // --- Chat (Next.js voice-message-bubble) ---
  static const chatVoiceWaveIncoming = Color(0xFFB76E79);
  static const chatVoiceWaveOutgoing = Color(0xFFFFFFFF);
  static const chatReadReceipt = Color(0xFF90CAF9);

  // --- Product-specific ---
  static const esewaGreen = Color(0xFF60BB46);

  // --- Radius (globals.css) ---
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;
}

/// Backward-compatible alias used across the codebase.
typedef DuoColors = AppColors;
