import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic tokens beyond [ColorScheme] — chat, glass, nav, map, gradients.
@immutable
class DuoThemeTokens extends ThemeExtension<DuoThemeTokens> {
  const DuoThemeTokens({
    required this.accent,
    required this.love,
    required this.premium,
    required this.mutedForeground,
    required this.glassSurface,
    required this.glassBorder,
    required this.navBarSurface,
    required this.navBarBorder,
    required this.cardGradientTop,
    required this.cardGradientBottom,
    required this.cardBorder,
    required this.cardShadow,
    required this.brandGradient,
    required this.brandBrGradient,
    required this.chatIncomingBackground,
    required this.chatIncomingBorder,
    required this.chatOutgoingGradient,
    required this.chatOnOutgoing,
    required this.chatVoiceWaveIncoming,
    required this.chatVoiceWaveOutgoing,
    required this.chatReplyScrim,
    required this.mapControlBackground,
    required this.mapControlForeground,
    required this.mapControlBorder,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.success,
    required this.warning,
    required this.disabledForeground,
    required this.link,
    required this.ambientGlowPrimary,
    required this.ambientGlowAccent,
    required this.ambientGlowTertiary,
  });

  final Color accent;
  final Color love;
  final Color premium;
  final Color mutedForeground;
  final Color glassSurface;
  final Color glassBorder;
  final Color navBarSurface;
  final Color navBarBorder;
  final Color cardGradientTop;
  final Color cardGradientBottom;
  final Color cardBorder;
  final Color cardShadow;
  final Gradient brandGradient;
  final Gradient brandBrGradient;
  final Color chatIncomingBackground;
  final Color chatIncomingBorder;
  final Gradient chatOutgoingGradient;
  final Color chatOnOutgoing;
  final Color chatVoiceWaveIncoming;
  final Color chatVoiceWaveOutgoing;
  final Color chatReplyScrim;
  final Color mapControlBackground;
  final Color mapControlForeground;
  final Color mapControlBorder;
  final Color badgeBackground;
  final Color badgeForeground;
  final Color success;
  final Color warning;
  final Color disabledForeground;
  final Color link;
  final Color ambientGlowPrimary;
  final Color ambientGlowAccent;
  final Color ambientGlowTertiary;

  static DuoThemeTokens dark() {
    return const DuoThemeTokens(
      accent: AppColors.accent,
      love: AppColors.love,
      premium: AppColors.premium,
      mutedForeground: AppColors.mutedForegroundDark,
      glassSurface: Color(0xB817181A),
      glassBorder: Color(0x14FFFFFF),
      navBarSurface: Color(0xEB17181A),
      navBarBorder: Color(0x592F3136),
      cardGradientTop: Color(0xF525272B),
      cardGradientBottom: Color(0xEB17181A),
      cardBorder: Color(0x12FFFFFF),
      cardShadow: Color(0x52000000),
      brandGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.love, AppColors.accent],
      ),
      brandBrGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.accent],
      ),
      chatIncomingBackground: AppColors.surfaceContainerHighestDark,
      chatIncomingBorder: AppColors.outlineDark,
      chatOutgoingGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryContainer],
      ),
      chatOnOutgoing: AppColors.onPrimary,
      chatVoiceWaveIncoming: AppColors.chatVoiceWaveIncoming,
      chatVoiceWaveOutgoing: AppColors.chatVoiceWaveOutgoing,
      chatReplyScrim: Color(0x1F000000),
      mapControlBackground: Color(0x6B000000),
      mapControlForeground: AppColors.onPrimary,
      mapControlBorder: Color(0x2EFFFFFF),
      badgeBackground: AppColors.primary,
      badgeForeground: AppColors.onPrimary,
      success: AppColors.success,
      warning: AppColors.warning,
      disabledForeground: Color(0xFF6B7280),
      link: AppColors.primary,
      ambientGlowPrimary: Color(0x2EE84A7A),
      ambientGlowAccent: Color(0x1AD4A574),
      ambientGlowTertiary: Color(0x248B5CF6),
    );
  }

  static DuoThemeTokens light() {
    return const DuoThemeTokens(
      accent: AppColors.accent,
      love: AppColors.love,
      premium: AppColors.premium,
      mutedForeground: AppColors.mutedForegroundLight,
      glassSurface: Color(0xD1FFFFFF),
      glassBorder: Color(0x14000000),
      navBarSurface: Color(0xDBFFFFFF),
      navBarBorder: Color(0x1FE84A7A),
      cardGradientTop: Color(0xFAFFFFFF),
      cardGradientBottom: Color(0xF2F9FAFB),
      cardBorder: Color(0x0F000000),
      cardShadow: Color(0x140F172A),
      brandGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.love, AppColors.accent],
      ),
      brandBrGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.accent],
      ),
      chatIncomingBackground: AppColors.surfaceContainerHighLight,
      chatIncomingBorder: AppColors.borderLight,
      chatOutgoingGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.primaryContainer],
      ),
      chatOnOutgoing: AppColors.onPrimary,
      chatVoiceWaveIncoming: AppColors.chatVoiceWaveIncoming,
      chatVoiceWaveOutgoing: AppColors.chatVoiceWaveOutgoing,
      chatReplyScrim: Color(0x12000000),
      mapControlBackground: Color(0xE6111827),
      mapControlForeground: AppColors.onPrimary,
      mapControlBorder: Color(0x33FFFFFF),
      badgeBackground: AppColors.primary,
      badgeForeground: AppColors.onPrimary,
      success: AppColors.success,
      warning: AppColors.warning,
      disabledForeground: Color(0xFF9CA3AF),
      link: AppColors.primary,
      ambientGlowPrimary: Color(0x1AE84A7A),
      ambientGlowAccent: Color(0x14D4A574),
      ambientGlowTertiary: Color(0x148B5CF6),
    );
  }

  @override
  DuoThemeTokens copyWith({
    Color? accent,
    Color? love,
    Color? premium,
    Color? mutedForeground,
    Color? glassSurface,
    Color? glassBorder,
    Color? navBarSurface,
    Color? navBarBorder,
    Color? cardGradientTop,
    Color? cardGradientBottom,
    Color? cardBorder,
    Color? cardShadow,
    Gradient? brandGradient,
    Gradient? brandBrGradient,
    Color? chatIncomingBackground,
    Color? chatIncomingBorder,
    Gradient? chatOutgoingGradient,
    Color? chatOnOutgoing,
    Color? chatVoiceWaveIncoming,
    Color? chatVoiceWaveOutgoing,
    Color? chatReplyScrim,
    Color? mapControlBackground,
    Color? mapControlForeground,
    Color? mapControlBorder,
    Color? badgeBackground,
    Color? badgeForeground,
    Color? success,
    Color? warning,
    Color? disabledForeground,
    Color? link,
    Color? ambientGlowPrimary,
    Color? ambientGlowAccent,
    Color? ambientGlowTertiary,
  }) {
    return DuoThemeTokens(
      accent: accent ?? this.accent,
      love: love ?? this.love,
      premium: premium ?? this.premium,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      navBarSurface: navBarSurface ?? this.navBarSurface,
      navBarBorder: navBarBorder ?? this.navBarBorder,
      cardGradientTop: cardGradientTop ?? this.cardGradientTop,
      cardGradientBottom: cardGradientBottom ?? this.cardGradientBottom,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      brandGradient: brandGradient ?? this.brandGradient,
      brandBrGradient: brandBrGradient ?? this.brandBrGradient,
      chatIncomingBackground: chatIncomingBackground ?? this.chatIncomingBackground,
      chatIncomingBorder: chatIncomingBorder ?? this.chatIncomingBorder,
      chatOutgoingGradient: chatOutgoingGradient ?? this.chatOutgoingGradient,
      chatOnOutgoing: chatOnOutgoing ?? this.chatOnOutgoing,
      chatVoiceWaveIncoming: chatVoiceWaveIncoming ?? this.chatVoiceWaveIncoming,
      chatVoiceWaveOutgoing: chatVoiceWaveOutgoing ?? this.chatVoiceWaveOutgoing,
      chatReplyScrim: chatReplyScrim ?? this.chatReplyScrim,
      mapControlBackground: mapControlBackground ?? this.mapControlBackground,
      mapControlForeground: mapControlForeground ?? this.mapControlForeground,
      mapControlBorder: mapControlBorder ?? this.mapControlBorder,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeForeground: badgeForeground ?? this.badgeForeground,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      link: link ?? this.link,
      ambientGlowPrimary: ambientGlowPrimary ?? this.ambientGlowPrimary,
      ambientGlowAccent: ambientGlowAccent ?? this.ambientGlowAccent,
      ambientGlowTertiary: ambientGlowTertiary ?? this.ambientGlowTertiary,
    );
  }

  @override
  DuoThemeTokens lerp(ThemeExtension<DuoThemeTokens>? other, double t) {
    if (other is! DuoThemeTokens) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return DuoThemeTokens(
      accent: lerpColor(accent, other.accent),
      love: lerpColor(love, other.love),
      premium: lerpColor(premium, other.premium),
      mutedForeground: lerpColor(mutedForeground, other.mutedForeground),
      glassSurface: lerpColor(glassSurface, other.glassSurface),
      glassBorder: lerpColor(glassBorder, other.glassBorder),
      navBarSurface: lerpColor(navBarSurface, other.navBarSurface),
      navBarBorder: lerpColor(navBarBorder, other.navBarBorder),
      cardGradientTop: lerpColor(cardGradientTop, other.cardGradientTop),
      cardGradientBottom: lerpColor(cardGradientBottom, other.cardGradientBottom),
      cardBorder: lerpColor(cardBorder, other.cardBorder),
      cardShadow: lerpColor(cardShadow, other.cardShadow),
      brandGradient: t < 0.5 ? brandGradient : other.brandGradient,
      brandBrGradient: t < 0.5 ? brandBrGradient : other.brandBrGradient,
      chatIncomingBackground: lerpColor(chatIncomingBackground, other.chatIncomingBackground),
      chatIncomingBorder: lerpColor(chatIncomingBorder, other.chatIncomingBorder),
      chatOutgoingGradient: t < 0.5 ? chatOutgoingGradient : other.chatOutgoingGradient,
      chatOnOutgoing: lerpColor(chatOnOutgoing, other.chatOnOutgoing),
      chatVoiceWaveIncoming: lerpColor(chatVoiceWaveIncoming, other.chatVoiceWaveIncoming),
      chatVoiceWaveOutgoing: lerpColor(chatVoiceWaveOutgoing, other.chatVoiceWaveOutgoing),
      chatReplyScrim: lerpColor(chatReplyScrim, other.chatReplyScrim),
      mapControlBackground: lerpColor(mapControlBackground, other.mapControlBackground),
      mapControlForeground: lerpColor(mapControlForeground, other.mapControlForeground),
      mapControlBorder: lerpColor(mapControlBorder, other.mapControlBorder),
      badgeBackground: lerpColor(badgeBackground, other.badgeBackground),
      badgeForeground: lerpColor(badgeForeground, other.badgeForeground),
      success: lerpColor(success, other.success),
      warning: lerpColor(warning, other.warning),
      disabledForeground: lerpColor(disabledForeground, other.disabledForeground),
      link: lerpColor(link, other.link),
      ambientGlowPrimary: lerpColor(ambientGlowPrimary, other.ambientGlowPrimary),
      ambientGlowAccent: lerpColor(ambientGlowAccent, other.ambientGlowAccent),
      ambientGlowTertiary: lerpColor(ambientGlowTertiary, other.ambientGlowTertiary),
    );
  }
}

extension DuoThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  DuoThemeTokens get duo => Theme.of(this).extension<DuoThemeTokens>()!;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
