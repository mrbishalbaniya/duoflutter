import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'theme_extensions.dart';

ThemeData buildDarkTheme() {
  const tokens = DuoThemeTokens(
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

  final scheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryDark,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    shadow: Colors.black,
    scrim: Color(0x99000000),
    inverseSurface: AppColors.inverseSurfaceDark,
    onInverseSurface: AppColors.inverseOnSurfaceDark,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
    surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
    surfaceContainer: AppColors.surfaceContainerDark,
    surfaceContainerLow: AppColors.surfaceContainerLowDark,
    surfaceContainerLowest: AppColors.backgroundDark,
    surfaceBright: AppColors.surfaceBrightDark,
    surfaceDim: AppColors.surfaceDimDark,
  );

  return buildDuoTheme(scheme, tokens, AppColors.backgroundDark);
}

ThemeData buildDuoTheme(ColorScheme scheme, DuoThemeTokens tokens, Color scaffoldBg) {
  final textTheme = AppTextTheme.build(scheme);
  final radius = BorderRadius.circular(AppColors.radiusMd);

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: [tokens],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    splashColor: scheme.primary.withValues(alpha: 0.12),
    highlightColor: scheme.primary.withValues(alpha: 0.08),
    hoverColor: scheme.primary.withValues(alpha: 0.06),
    focusColor: scheme.primary.withValues(alpha: 0.14),
    dividerColor: scheme.outline.withValues(alpha: 0.45),
    disabledColor: tokens.disabledForeground,
    iconTheme: IconThemeData(color: scheme.onSurface),
    primaryIconTheme: IconThemeData(color: scheme.primary),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: scheme.onSurface,
      iconTheme: IconThemeData(color: scheme.onSurface),
      systemOverlayStyle: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: tokens.cardBorder),
      ),
      shadowColor: tokens.cardShadow,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      modalBackgroundColor: scheme.surfaceContainerHigh,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      ),
      dragHandleColor: scheme.outline,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.brightness == Brightness.dark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariantLight,
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.mutedForeground),
      labelStyle: textTheme.labelLarge,
      errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: tokens.disabledForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: tokens.accent.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        disabledForegroundColor: tokens.disabledForeground,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        highlightColor: scheme.primary.withValues(alpha: 0.12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 4,
      shape: const CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primary,
      disabledColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: scheme.onSurface),
      secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          size: 22,
        );
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.surfaceContainerHighest;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.outline;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodySmall,
      tileColor: Colors.transparent,
      selectedTileColor: scheme.primary.withValues(alpha: 0.08),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outline.withValues(alpha: 0.35),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: textTheme.bodyMedium,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outline.withValues(alpha: 0.45),
      thickness: 1,
      space: 1,
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: tokens.badgeBackground,
      textColor: tokens.badgeForeground,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      iconColor: scheme.onSurfaceVariant,
      collapsedIconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      collapsedTextColor: scheme.onSurface,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: scheme.surfaceContainer,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
      ),
    ),
  );
}
