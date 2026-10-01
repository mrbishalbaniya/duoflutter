import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../storage/local_storage.dart';
import 'theme_extensions.dart';
import 'nav_icon_sets.dart';

/// Appearance catalog ported from DuoFrontend `lib/palettes.ts` and the
/// palette / surface rules in `app/globals.css`. Keep ids in sync with web.

class DuoPrimarySet {
  const DuoPrimarySet(this.primary, this.container, [this.onPrimary]);
  final Color primary;
  final Color container;
  final Color? onPrimary;
}

class DuoSurfaces {
  const DuoSurfaces({
    required this.background,
    required this.surface,
    required this.dim,
    required this.bright,
    required this.variant,
    required this.container,
    required this.low,
    required this.lowest,
    required this.high,
    required this.highest,
    required this.secondary,
    required this.secondaryContainer,
    this.onSurface,
    this.onSurfaceVariant,
    this.border,
  });

  final Color background;
  final Color surface;
  final Color dim;
  final Color bright;
  final Color variant;
  final Color container;
  final Color low;
  final Color lowest;
  final Color high;
  final Color highest;
  final Color secondary;
  final Color secondaryContainer;
  final Color? onSurface;
  final Color? onSurfaceVariant;
  final Color? border;
}

class DuoPalette {
  const DuoPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.premium,
    required this.swatch,
    required this.previewSurface,
    this.dark,
    this.light,
    this.brand2,
    this.brand3,
    this.darkSurfaces,
    this.lightSurfaces,
    this.tint = 1,
  });

  final String id;
  final String name;
  final String description;
  final bool premium;

  /// Picker preview colors: primary, secondary, accent.
  final List<Color> swatch;
  final Color previewSurface;
  final DuoPrimarySet? dark;
  final DuoPrimarySet? light;
  final Color? brand2;
  final Color? brand3;

  /// Full surface override (only Noir); otherwise premium palettes tint.
  final DuoSurfaces? darkSurfaces;
  final DuoSurfaces? lightSurfaces;

  /// Multiplier for the premium surface tint (love themes run deeper).
  final double tint;
}

class DuoSurfaceStyle {
  const DuoSurfaceStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.premium,
    required this.preview,
    this.surfaces,
  });

  final String id;
  final String name;
  final String description;
  final bool premium;

  /// Preview colors: background, card, text.
  final List<Color> preview;
  final DuoSurfaces? surfaces;
}

const _white = Color(0xFFFFFFFF);

const duoPalettes = <DuoPalette>[
  DuoPalette(
    id: 'rose',
    name: 'Rose',
    description: "Duo's signature pink",
    premium: false,
    swatch: [Color(0xFFE84A7A), Color(0xFFFF4D6D), Color(0xFFD4A574)],
    previewSurface: Color(0xFF17181A),
  ),
  DuoPalette(
    id: 'ocean',
    name: 'Ocean',
    description: 'Calm, clear blue',
    premium: false,
    swatch: [Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF22D3EE)],
    previewSurface: Color(0xFF17181A),
    dark: DuoPrimarySet(Color(0xFF3B82F6), Color(0xFF2563EB)),
    light: DuoPrimarySet(Color(0xFF2563EB), Color(0xFF1D4ED8)),
    brand2: Color(0xFF60A5FA),
    brand3: Color(0xFF22D3EE),
  ),
  DuoPalette(
    id: 'lagoon',
    name: 'Lagoon',
    description: 'Tropical teal',
    premium: false,
    swatch: [Color(0xFF14B8A6), Color(0xFF2DD4BF), Color(0xFF38BDF8)],
    previewSurface: Color(0xFF17181A),
    dark: DuoPrimarySet(Color(0xFF14B8A6), Color(0xFF0D9488), _white),
    light: DuoPrimarySet(Color(0xFF0D9488), Color(0xFF0F766E), _white),
    brand2: Color(0xFF2DD4BF),
    brand3: Color(0xFF38BDF8),
  ),
  DuoPalette(
    id: 'aurum',
    name: 'Aurum',
    description: 'Warm gold luxury',
    premium: true,
    swatch: [Color(0xFFD4A24C), Color(0xFFF6D365), Color(0xFFB8862F)],
    previewSurface: Color(0xFF1A1712),
    dark: DuoPrimarySet(Color(0xFFD4A24C), Color(0xFFB8862F), Color(0xFF1C1408)),
    light: DuoPrimarySet(Color(0xFFA87A28), Color(0xFF8A6420), _white),
    brand2: Color(0xFFF6D365),
    brand3: Color(0xFFB8862F),
  ),
  DuoPalette(
    id: 'amethyst',
    name: 'Amethyst',
    description: 'Royal violet glow',
    premium: true,
    swatch: [Color(0xFF8B5CF6), Color(0xFFC084FC), Color(0xFFF0ABFC)],
    previewSurface: Color(0xFF18151F),
    dark: DuoPrimarySet(Color(0xFF8B5CF6), Color(0xFF7C3AED)),
    light: DuoPrimarySet(Color(0xFF7C3AED), Color(0xFF6D28D9)),
    brand2: Color(0xFFC084FC),
    brand3: Color(0xFFF0ABFC),
  ),
  DuoPalette(
    id: 'emerald',
    name: 'Emerald',
    description: 'Fresh jewel green',
    premium: true,
    swatch: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFFA3E635)],
    previewSurface: Color(0xFF121A17),
    dark: DuoPrimarySet(Color(0xFF10B981), Color(0xFF059669)),
    light: DuoPrimarySet(Color(0xFF059669), Color(0xFF047857)),
    brand2: Color(0xFF34D399),
    brand3: Color(0xFFA3E635),
  ),
  DuoPalette(
    id: 'sunset',
    name: 'Sunset',
    description: 'Golden-hour orange',
    premium: true,
    swatch: [Color(0xFFF97316), Color(0xFFFB7185), Color(0xFFFACC15)],
    previewSurface: Color(0xFF1C1613),
    dark: DuoPrimarySet(Color(0xFFF97316), Color(0xFFEA580C)),
    light: DuoPrimarySet(Color(0xFFEA580C), Color(0xFFC2410C)),
    brand2: Color(0xFFFB7185),
    brand3: Color(0xFFFACC15),
  ),
  DuoPalette(
    id: 'midnight',
    name: 'Midnight',
    description: 'Deep indigo night',
    premium: true,
    swatch: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFF38BDF8)],
    previewSurface: Color(0xFF13151F),
    dark: DuoPrimarySet(Color(0xFF6366F1), Color(0xFF4F46E5)),
    light: DuoPrimarySet(Color(0xFF4F46E5), Color(0xFF4338CA)),
    brand2: Color(0xFF818CF8),
    brand3: Color(0xFF38BDF8),
  ),
  DuoPalette(
    id: 'crimson',
    name: 'Crimson',
    description: 'Bold ruby red',
    premium: true,
    swatch: [Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFF59E0B)],
    previewSurface: Color(0xFF1C1215),
    dark: DuoPrimarySet(Color(0xFFE11D48), Color(0xFFBE123C), _white),
    light: DuoPrimarySet(Color(0xFFBE123C), Color(0xFF9F1239), _white),
    brand2: Color(0xFFFB7185),
    brand3: Color(0xFFF59E0B),
  ),
  DuoPalette(
    id: 'sakura',
    name: 'Sakura',
    description: 'Soft cherry blossom',
    premium: true,
    swatch: [Color(0xFFF472B6), Color(0xFFF9A8D4), Color(0xFFC4B5FD)],
    previewSurface: Color(0xFF1C151A),
    dark: DuoPrimarySet(Color(0xFFF472B6), Color(0xFFEC4899), _white),
    light: DuoPrimarySet(Color(0xFFDB2777), Color(0xFFBE185D), _white),
    brand2: Color(0xFFF9A8D4),
    brand3: Color(0xFFC4B5FD),
  ),
  DuoPalette(
    id: 'mocha',
    name: 'Mocha',
    description: 'Cozy coffee brown',
    premium: true,
    swatch: [Color(0xFFC08457), Color(0xFFE0B48A), Color(0xFF8B5E3C)],
    previewSurface: Color(0xFF1A1612),
    dark: DuoPrimarySet(Color(0xFFC08457), Color(0xFFA16207), _white),
    light: DuoPrimarySet(Color(0xFF9A5B2C), Color(0xFF7C4A24), _white),
    brand2: Color(0xFFE0B48A),
    brand3: Color(0xFF8B5E3C),
  ),
  DuoPalette(
    id: 'neon',
    name: 'Neon',
    description: 'Electric cyan and magenta',
    premium: true,
    swatch: [Color(0xFF22D3EE), Color(0xFFE879F9), Color(0xFFA3E635)],
    previewSurface: Color(0xFF0F1418),
    dark: DuoPrimarySet(Color(0xFF22D3EE), Color(0xFF06B6D4), Color(0xFF0A1A1F)),
    light: DuoPrimarySet(Color(0xFF0891B2), Color(0xFF0E7490), _white),
    brand2: Color(0xFFE879F9),
    brand3: Color(0xFFA3E635),
  ),
  DuoPalette(
    id: 'royal',
    name: 'Royal',
    description: 'Sapphire blue with gold',
    premium: true,
    swatch: [Color(0xFF3B5BDB), Color(0xFF748FFC), Color(0xFFF2C14E)],
    previewSurface: Color(0xFF12141F),
    dark: DuoPrimarySet(Color(0xFF3B5BDB), Color(0xFF2F4AC0), _white),
    light: DuoPrimarySet(Color(0xFF2F4AC0), Color(0xFF253B9C), _white),
    brand2: Color(0xFF748FFC),
    brand3: Color(0xFFF2C14E),
  ),
  // Love collection
  DuoPalette(
    id: 'valentine',
    name: 'Valentine',
    description: 'Velvet red roses',
    premium: true,
    swatch: [Color(0xFFE0244F), Color(0xFFFF6B8B), Color(0xFFFFB3C1)],
    previewSurface: Color(0xFF1F0A10),
    dark: DuoPrimarySet(Color(0xFFE0244F), Color(0xFFB81A40), _white),
    light: DuoPrimarySet(Color(0xFFC81E47), Color(0xFFA3163A), _white),
    brand2: Color(0xFFFF6B8B),
    brand3: Color(0xFFFFB3C1),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'blush',
    name: 'Blush',
    description: 'Pink and champagne',
    premium: true,
    swatch: [Color(0xFFFF8FAB), Color(0xFFFFC8D6), Color(0xFFF2C98A)],
    previewSurface: Color(0xFF22121A),
    dark: DuoPrimarySet(Color(0xFFFF8FAB), Color(0xFFF06F90), Color(0xFF2A0E16)),
    light: DuoPrimarySet(Color(0xFFD94F78), Color(0xFFB83D63), _white),
    brand2: Color(0xFFFFC8D6),
    brand3: Color(0xFFF2C98A),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'passion',
    name: 'Passion',
    description: 'Burgundy wine and gold',
    premium: true,
    swatch: [Color(0xFFB0174A), Color(0xFFD8456F), Color(0xFFE8B86D)],
    previewSurface: Color(0xFF1C070D),
    dark: DuoPrimarySet(Color(0xFFC21D55), Color(0xFF9C1644), _white),
    light: DuoPrimarySet(Color(0xFF9C1644), Color(0xFF7C1036), _white),
    brand2: Color(0xFFD8456F),
    brand3: Color(0xFFE8B86D),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'cupid',
    name: 'Cupid',
    description: 'Pink arrows, lilac sky',
    premium: true,
    swatch: [Color(0xFFFF5C9A), Color(0xFFB388FF), Color(0xFFFFD1E8)],
    previewSurface: Color(0xFF1A0D22),
    dark: DuoPrimarySet(Color(0xFFFF5C9A), Color(0xFFE8447F), _white),
    light: DuoPrimarySet(Color(0xFFD6336F), Color(0xFFB3275B), _white),
    brand2: Color(0xFFB388FF),
    brand3: Color(0xFFFFD1E8),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'honeymoon',
    name: 'Honeymoon',
    description: 'Rose-gold glow',
    premium: true,
    swatch: [Color(0xFFE7A48C), Color(0xFFF3C9B4), Color(0xFFC79A6B)],
    previewSurface: Color(0xFF21140F),
    dark: DuoPrimarySet(Color(0xFFE7A48C), Color(0xFFD48A70), Color(0xFF2B130C)),
    light: DuoPrimarySet(Color(0xFFB5654C), Color(0xFF96503A), _white),
    brand2: Color(0xFFF3C9B4),
    brand3: Color(0xFFC79A6B),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'twilight',
    name: 'Twilight',
    description: 'Magenta sunset dusk',
    premium: true,
    swatch: [Color(0xFFD946EF), Color(0xFFFB7185), Color(0xFFFBBF24)],
    previewSurface: Color(0xFF1C0A22),
    dark: DuoPrimarySet(Color(0xFFD946EF), Color(0xFFB62FCC), _white),
    light: DuoPrimarySet(Color(0xFFA21CAF), Color(0xFF86198F), _white),
    brand2: Color(0xFFFB7185),
    brand3: Color(0xFFFBBF24),
    tint: 2.5,
  ),
  DuoPalette(
    id: 'noir',
    name: 'Noir',
    description: 'Pure monochrome',
    premium: true,
    swatch: [Color(0xFFF5F5F5), Color(0xFFA3A3A3), Color(0xFF525252)],
    previewSurface: Color(0xFF0A0A0A),
    dark: DuoPrimarySet(Color(0xFFF5F5F5), Color(0xFFD4D4D4), Color(0xFF0A0A0A)),
    light: DuoPrimarySet(Color(0xFF111111), Color(0xFF262626), _white),
    brand2: Color(0xFFA3A3A3),
    brand3: Color(0xFF525252),
    darkSurfaces: DuoSurfaces(
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0A),
      dim: Color(0xFF050505),
      bright: Color(0xFF1A1A1A),
      variant: Color(0xFF141414),
      container: Color(0xFF0F0F0F),
      low: Color(0xFF0A0A0A),
      lowest: Color(0xFF000000),
      high: Color(0xFF1A1A1A),
      highest: Color(0xFF222222),
      secondary: Color(0xFF0F0F0F),
      secondaryContainer: Color(0xFF171717),
    ),
    lightSurfaces: DuoSurfaces(
      background: Color(0xFFFAFAFA),
      surface: Color(0xFFFFFFFF),
      dim: Color(0xFFF0F0F0),
      bright: Color(0xFFFFFFFF),
      variant: Color(0xFFF5F5F5),
      container: Color(0xFFFFFFFF),
      low: Color(0xFFFAFAFA),
      lowest: Color(0xFFF5F5F5),
      high: Color(0xFFF0F0F0),
      highest: Color(0xFFE5E5E5),
      secondary: Color(0xFFF5F5F5),
      secondaryContainer: Color(0xFFE5E5E5),
    ),
  ),
];

const duoDarkStyles = <DuoSurfaceStyle>[
  DuoSurfaceStyle(
    id: 'default',
    name: 'Charcoal',
    description: "Duo's classic dark",
    premium: false,
    preview: [Color(0xFF0F0F10), Color(0xFF1B1D20), Color(0xFFFFFFFF)],
  ),
  DuoSurfaceStyle(
    id: 'amoled',
    name: 'AMOLED',
    description: 'True black, saves battery',
    premium: true,
    preview: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFFFFFFFF)],
    surfaces: DuoSurfaces(
      background: Color(0xFF000000),
      surface: Color(0xFF000000),
      dim: Color(0xFF050505),
      bright: Color(0xFF1C1C1C),
      variant: Color(0xFF141414),
      container: Color(0xFF0A0A0A),
      low: Color(0xFF050505),
      lowest: Color(0xFF000000),
      high: Color(0xFF141414),
      highest: Color(0xFF1C1C1C),
      secondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF141414),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFA3A3A3),
      border: Color(0xFF1F1F1F),
    ),
  ),
  DuoSurfaceStyle(
    id: 'dim',
    name: 'Dim',
    description: 'Soft blue-gray night',
    premium: true,
    preview: [Color(0xFF15202B), Color(0xFF192734), Color(0xFFF7F9F9)],
    surfaces: DuoSurfaces(
      background: Color(0xFF10171E),
      surface: Color(0xFF15202B),
      dim: Color(0xFF131C26),
      bright: Color(0xFF2C3A47),
      variant: Color(0xFF22303C),
      container: Color(0xFF192734),
      low: Color(0xFF131C26),
      lowest: Color(0xFF10171E),
      high: Color(0xFF22303C),
      highest: Color(0xFF2C3A47),
      secondary: Color(0xFF15202B),
      secondaryContainer: Color(0xFF22303C),
      onSurface: Color(0xFFF7F9F9),
      onSurfaceVariant: Color(0xFF8B98A5),
      border: Color(0xFF38444D),
    ),
  ),
  DuoSurfaceStyle(
    id: 'graphite',
    name: 'Graphite',
    description: 'Neutral warm gray',
    premium: true,
    preview: [Color(0xFF1C1C1E), Color(0xFF2C2C2E), Color(0xFFFFFFFF)],
    surfaces: DuoSurfaces(
      background: Color(0xFF111113),
      surface: Color(0xFF1C1C1E),
      dim: Color(0xFF161618),
      bright: Color(0xFF3A3A3C),
      variant: Color(0xFF2C2C2E),
      container: Color(0xFF1F1F22),
      low: Color(0xFF161618),
      lowest: Color(0xFF111113),
      high: Color(0xFF2C2C2E),
      highest: Color(0xFF3A3A3C),
      secondary: Color(0xFF1C1C1E),
      secondaryContainer: Color(0xFF2C2C2E),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFAEAEB2),
      border: Color(0xFF38383A),
    ),
  ),
  DuoSurfaceStyle(
    id: 'nord',
    name: 'Nord',
    description: 'Arctic slate blue',
    premium: true,
    preview: [Color(0xFF2E3440), Color(0xFF3B4252), Color(0xFFECEFF4)],
    surfaces: DuoSurfaces(
      background: Color(0xFF242933),
      surface: Color(0xFF2E3440),
      dim: Color(0xFF2A303B),
      bright: Color(0xFF434C5E),
      variant: Color(0xFF3B4252),
      container: Color(0xFF333A47),
      low: Color(0xFF2A303B),
      lowest: Color(0xFF242933),
      high: Color(0xFF3B4252),
      highest: Color(0xFF434C5E),
      secondary: Color(0xFF2E3440),
      secondaryContainer: Color(0xFF3B4252),
      onSurface: Color(0xFFECEFF4),
      onSurfaceVariant: Color(0xFFB8C0CF),
      border: Color(0xFF4C566A),
    ),
  ),
  DuoSurfaceStyle(
    id: 'velvet',
    name: 'Velvet',
    description: 'Deep plum darkness',
    premium: true,
    preview: [Color(0xFF15101F), Color(0xFF241C33), Color(0xFFF5F0FF)],
    surfaces: DuoSurfaces(
      background: Color(0xFF0D0A14),
      surface: Color(0xFF15101F),
      dim: Color(0xFF120D1A),
      bright: Color(0xFF2E2440),
      variant: Color(0xFF241C33),
      container: Color(0xFF1A1426),
      low: Color(0xFF120D1A),
      lowest: Color(0xFF0D0A14),
      high: Color(0xFF241C33),
      highest: Color(0xFF2E2440),
      secondary: Color(0xFF15101F),
      secondaryContainer: Color(0xFF241C33),
      onSurface: Color(0xFFF5F0FF),
      onSurfaceVariant: Color(0xFFB9AED0),
      border: Color(0xFF3A2E4F),
    ),
  ),
];

const duoLightStyles = <DuoSurfaceStyle>[
  DuoSurfaceStyle(
    id: 'default',
    name: 'Snow',
    description: "Duo's classic light",
    premium: false,
    preview: [Color(0xFFF7F7F8), Color(0xFFFFFFFF), Color(0xFF111827)],
  ),
  DuoSurfaceStyle(
    id: 'cream',
    name: 'Cream',
    description: 'Warm, easy on the eyes',
    premium: true,
    preview: [Color(0xFFF8F3E9), Color(0xFFFFFDF8), Color(0xFF2B2419)],
    surfaces: DuoSurfaces(
      background: Color(0xFFF8F3E9),
      surface: Color(0xFFFFFBF3),
      dim: Color(0xFFFAF5EA),
      bright: Color(0xFFE8DDC9),
      variant: Color(0xFFF1E9DA),
      container: Color(0xFFFFFDF8),
      low: Color(0xFFFAF5EA),
      lowest: Color(0xFFF8F3E9),
      high: Color(0xFFF1E9DA),
      highest: Color(0xFFE8DDC9),
      secondary: Color(0xFFFFFBF3),
      secondaryContainer: Color(0xFFF1E9DA),
      onSurface: Color(0xFF2B2419),
      onSurfaceVariant: Color(0xFF6B5F4B),
      border: Color(0xFFE6DCC8),
    ),
  ),
  DuoSurfaceStyle(
    id: 'frost',
    name: 'Frost',
    description: 'Cool icy blue',
    premium: true,
    preview: [Color(0xFFEEF3F8), Color(0xFFFFFFFF), Color(0xFF0F1B2A)],
    surfaces: DuoSurfaces(
      background: Color(0xFFEEF3F8),
      surface: Color(0xFFF8FBFE),
      dim: Color(0xFFF3F7FB),
      bright: Color(0xFFD8E2ED),
      variant: Color(0xFFE4EBF3),
      container: Color(0xFFFFFFFF),
      low: Color(0xFFF3F7FB),
      lowest: Color(0xFFEEF3F8),
      high: Color(0xFFE4EBF3),
      highest: Color(0xFFD8E2ED),
      secondary: Color(0xFFF8FBFE),
      secondaryContainer: Color(0xFFE4EBF3),
      onSurface: Color(0xFF0F1B2A),
      onSurfaceVariant: Color(0xFF4A5A6E),
      border: Color(0xFFD5DEE8),
    ),
  ),
  DuoSurfaceStyle(
    id: 'sand',
    name: 'Sand',
    description: 'Earthy beige',
    premium: true,
    preview: [Color(0xFFEFE7DA), Color(0xFFFAF6EF), Color(0xFF33291C)],
    surfaces: DuoSurfaces(
      background: Color(0xFFEFE7DA),
      surface: Color(0xFFF7F1E7),
      dim: Color(0xFFF2EBDF),
      bright: Color(0xFFDDD0BC),
      variant: Color(0xFFE7DDCD),
      container: Color(0xFFFAF6EF),
      low: Color(0xFFF2EBDF),
      lowest: Color(0xFFEFE7DA),
      high: Color(0xFFE7DDCD),
      highest: Color(0xFFDDD0BC),
      secondary: Color(0xFFF7F1E7),
      secondaryContainer: Color(0xFFE7DDCD),
      onSurface: Color(0xFF33291C),
      onSurfaceVariant: Color(0xFF6E604A),
      border: Color(0xFFD9CBB4),
    ),
  ),
  DuoSurfaceStyle(
    id: 'mist',
    name: 'Mist',
    description: 'Hint of lavender',
    premium: true,
    preview: [Color(0xFFF3F1F8), Color(0xFFFFFFFF), Color(0xFF1D1830)],
    surfaces: DuoSurfaces(
      background: Color(0xFFF3F1F8),
      surface: Color(0xFFFBFAFF),
      dim: Color(0xFFF6F4FB),
      bright: Color(0xFFE0DCEC),
      variant: Color(0xFFEBE8F3),
      container: Color(0xFFFFFFFF),
      low: Color(0xFFF6F4FB),
      lowest: Color(0xFFF3F1F8),
      high: Color(0xFFEBE8F3),
      highest: Color(0xFFE0DCEC),
      secondary: Color(0xFFFBFAFF),
      secondaryContainer: Color(0xFFEBE8F3),
      onSurface: Color(0xFF1D1830),
      onSurfaceVariant: Color(0xFF5B5470),
      border: Color(0xFFDCD7E8),
    ),
  ),
  DuoSurfaceStyle(
    id: 'paper',
    name: 'Paper',
    description: 'High-contrast white',
    premium: true,
    preview: [Color(0xFFFFFFFF), Color(0xFFF4F4F5), Color(0xFF000000)],
    surfaces: DuoSurfaces(
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      dim: Color(0xFFFAFAFA),
      bright: Color(0xFFE4E4E7),
      variant: Color(0xFFF4F4F5),
      container: Color(0xFFFFFFFF),
      low: Color(0xFFFAFAFA),
      lowest: Color(0xFFFFFFFF),
      high: Color(0xFFF4F4F5),
      highest: Color(0xFFE4E4E7),
      secondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF4F4F5),
      onSurface: Color(0xFF000000),
      onSurfaceVariant: Color(0xFF3F3F46),
      border: Color(0xFFD4D4D8),
    ),
  ),
];

DuoPalette paletteById(String id) =>
    duoPalettes.firstWhere((p) => p.id == id, orElse: () => duoPalettes.first);
DuoSurfaceStyle darkStyleById(String id) =>
    duoDarkStyles.firstWhere((s) => s.id == id, orElse: () => duoDarkStyles.first);
DuoSurfaceStyle lightStyleById(String id) =>
    duoLightStyles.firstWhere((s) => s.id == id, orElse: () => duoLightStyles.first);

/// The selected palette and dark/light styles, saved on this device like web.
@immutable
class DuoAppearance {
  const DuoAppearance({
    this.palette = 'rose',
    this.darkStyle = 'default',
    this.lightStyle = 'default',
    this.iconSet = 'classic',
  });

  static const standard = DuoAppearance();

  final String palette;
  final String darkStyle;
  final String lightStyle;

  /// Bottom navigation icon set (see nav_icon_sets.dart).
  final String iconSet;

  DuoAppearance copyWith({String? palette, String? darkStyle, String? lightStyle, String? iconSet}) => DuoAppearance(
        palette: palette ?? this.palette,
        darkStyle: darkStyle ?? this.darkStyle,
        lightStyle: lightStyle ?? this.lightStyle,
        iconSet: iconSet ?? this.iconSet,
      );

  @override
  bool operator ==(Object other) =>
      other is DuoAppearance &&
      other.palette == palette &&
      other.darkStyle == darkStyle &&
      other.lightStyle == lightStyle &&
      other.iconSet == iconSet;

  @override
  int get hashCode => Object.hash(palette, darkStyle, lightStyle, iconSet);
}

class AppearanceController extends StateNotifier<DuoAppearance> {
  AppearanceController(LocalStorage storage)
      : _storage = storage,
        super(DuoAppearance(
          palette: paletteById(_read(storage, _paletteKey) ?? 'rose').id,
          darkStyle: darkStyleById(_read(storage, _darkKey) ?? 'default').id,
          lightStyle: lightStyleById(_read(storage, _lightKey) ?? 'default').id,
          iconSet: navIconSetById(_read(storage, _iconSetKey) ?? 'classic').id,
        ));

  AppearanceController.testing([super.appearance = DuoAppearance.standard]) : _storage = null;

  static const _paletteKey = 'duo_palette';
  static const _darkKey = 'duo_dark_style';
  static const _lightKey = 'duo_light_style';
  static const _iconSetKey = 'duo_icon_set';

  final LocalStorage? _storage;

  static String? _read(LocalStorage storage, String key) {
    final value = storage.settings.get(key);
    return value is String ? value : null;
  }

  void setPalette(String id) {
    state = state.copyWith(palette: id);
    _storage?.settings.put(_paletteKey, id);
  }

  void setDarkStyle(String id) {
    state = state.copyWith(darkStyle: id);
    _storage?.settings.put(_darkKey, id);
  }

  void setLightStyle(String id) {
    state = state.copyWith(lightStyle: id);
    _storage?.settings.put(_lightKey, id);
  }

  void setIconSet(String id) {
    state = state.copyWith(iconSet: id);
    _storage?.settings.put(_iconSetKey, id);
  }
}

final appearanceProvider = StateNotifierProvider<AppearanceController, DuoAppearance>((ref) {
  return AppearanceController(ref.watch(localStorageProvider));
});

/// `color-mix(in srgb, tint p%, base)`.
Color _mix(Color tint, double percent, Color base) => Color.lerp(base, tint, percent / 100)!;

/// Applies [appearance] to a base scheme, tokens and scaffold background,
/// following the same precedence as the web CSS: palette primary, then
/// premium palette tint, then the chosen dark/light surface style.
(ColorScheme, DuoThemeTokens, Color) applyAppearance(
  ColorScheme scheme,
  DuoThemeTokens tokens,
  Color background,
  DuoAppearance appearance,
) {
  final isDark = scheme.brightness == Brightness.dark;
  final palette = paletteById(appearance.palette);
  final style = isDark ? darkStyleById(appearance.darkStyle) : lightStyleById(appearance.lightStyle);
  if (palette.id == 'rose' && style.surfaces == null) return (scheme, tokens, background);

  var s = scheme;
  var t = tokens;
  var bg = background;

  final primarySet = isDark ? palette.dark : (palette.light ?? palette.dark);
  if (primarySet != null) {
    final primary = primarySet.primary;
    // Light overrides only restate primary; onPrimary falls back to dark's.
    final onPrimary = primarySet.onPrimary ?? palette.dark?.onPrimary ?? s.onPrimary;
    final brand2 = palette.brand2 ?? t.love;
    final brand3 = palette.brand3 ?? t.accent;
    s = s.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primarySet.container,
      onPrimaryContainer: onPrimary,
      surfaceTint: primary,
      inversePrimary: primary,
    );
    t = t.copyWith(
      love: brand2,
      brandGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, brand2, brand3],
      ),
      brandBrGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, brand3],
      ),
      chatOutgoingGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primarySet.container],
      ),
      chatOnOutgoing: onPrimary,
      badgeBackground: primary,
      badgeForeground: onPrimary,
      link: primary,
      ambientGlowPrimary: primary.withValues(alpha: isDark ? 0.18 : 0.10),
      ambientGlowAccent: brand3.withValues(alpha: isDark ? 0.10 : 0.08),
    );

    final full = isDark ? palette.darkSurfaces : palette.lightSurfaces;
    if (full != null) {
      (s, bg) = _withSurfaces(s, full);
    } else if (palette.premium) {
      final k = palette.tint;
      // Love themes (tint > 1) also sit on a slightly warmer, deeper base.
      final warm = k > 1;
      if (isDark) {
        (s, bg) = _withSurfaces(
          s,
          DuoSurfaces(
            background: _mix(primary, 4 * k, warm ? const Color(0xFF070506) : const Color(0xFF0B0B0C)),
            surface: _mix(primary, 5 * k, warm ? const Color(0xFF110C0E) : const Color(0xFF141517)),
            dim: _mix(primary, 4 * k, warm ? const Color(0xFF0A0708) : const Color(0xFF0E0F10)),
            bright: _mix(primary, 7 * k, warm ? const Color(0xFF1D1619) : const Color(0xFF202125)),
            variant: _mix(primary, 6 * k, warm ? const Color(0xFF1A1316) : const Color(0xFF1D1F22)),
            container: _mix(primary, 5 * k, warm ? const Color(0xFF151012) : const Color(0xFF18191C)),
            low: _mix(primary, 4 * k, warm ? const Color(0xFF0F0B0C) : const Color(0xFF121315)),
            lowest: _mix(primary, 4 * k, warm ? const Color(0xFF070506) : const Color(0xFF0B0B0C)),
            high: _mix(primary, 7 * k, warm ? const Color(0xFF1F181B) : const Color(0xFF222428)),
            highest: _mix(primary, 8 * k, warm ? const Color(0xFF272023) : const Color(0xFF2A2D32)),
            secondary: _mix(primary, 5 * k, warm ? const Color(0xFF110C0E) : const Color(0xFF141517)),
            secondaryContainer: _mix(primary, 6 * k, warm ? const Color(0xFF1A1316) : const Color(0xFF1D1F22)),
            border: _mix(primary, 12 * (warm ? 2 : 1), warm ? const Color(0xFF2B2427) : const Color(0xFF33373E)),
          ),
        );
      } else {
        bg = _mix(primary, warm ? 9 : 4, warm ? const Color(0xFFFBF7F8) : const Color(0xFFF7F7F8));
        s = s.copyWith(
          surfaceContainerLow: _mix(primary, warm ? 6 : 3, warm ? const Color(0xFFFDFAFB) : const Color(0xFFF9FAFB)),
          secondary: _mix(primary, warm ? 10 : 5, warm ? const Color(0xFFF6F1F3) : const Color(0xFFF3F4F6)),
        );
      }
    }
  }

  // A chosen surface style wins over a palette's tint, as on web.
  if (style.surfaces != null) {
    (s, bg) = _withSurfaces(s, style.surfaces!);
    final border = style.surfaces!.border;
    t = t.copyWith(
      mutedForeground: style.surfaces!.onSurfaceVariant,
      chatIncomingBackground: style.surfaces!.highest,
      chatIncomingBorder: border,
      navBarSurface: style.surfaces!.surface.withValues(alpha: 0.92),
      glassSurface: style.surfaces!.surface.withValues(alpha: isDark ? 0.72 : 0.82),
      cardGradientTop: style.surfaces!.high.withValues(alpha: 0.96),
      cardGradientBottom: style.surfaces!.surface.withValues(alpha: 0.92),
    );
  }

  return (s, t, bg);
}

(ColorScheme, Color) _withSurfaces(ColorScheme s, DuoSurfaces v) {
  return (
    s.copyWith(
      surface: v.surface,
      surfaceDim: v.dim,
      surfaceBright: v.bright,
      surfaceContainer: v.container,
      surfaceContainerLow: v.low,
      surfaceContainerLowest: v.lowest,
      surfaceContainerHigh: v.high,
      surfaceContainerHighest: v.highest,
      secondary: v.secondary,
      secondaryContainer: v.secondaryContainer,
      onSurface: v.onSurface,
      onSurfaceVariant: v.onSurfaceVariant,
      outlineVariant: v.border,
    ),
    v.background,
  );
}
