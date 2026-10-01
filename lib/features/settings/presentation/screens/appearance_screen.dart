import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/appearance.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/auth_controller.dart';
import '../../../../core/theme/nav_icon_sets.dart';

/// Mirrors the web `/settings/Appearance` page: mode, dark/light styles,
/// color palettes (premium-gated) and a live preview.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final appearance = ref.watch(appearanceProvider);
    final isPremium = ref.watch(authControllerProvider.select((s) => s.user?.profile.isPremium ?? false));
    final resolvedDark = Theme.of(context).brightness == Brightness.dark;
    final themeCtrl = ref.read(themeModeProvider.notifier);
    final appearanceCtrl = ref.read(appearanceProvider.notifier);

    void upgrade() => context.push(AppRoutes.wallet);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Heading('Mode'),
          Row(
            children: [
              for (final (m, label, icon) in const [
                (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
                (ThemeMode.light, 'Light', Icons.light_mode_outlined),
                (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
              ]) ...[
                if (m != ThemeMode.dark) const SizedBox(width: 10),
                Expanded(
                  child: _ModeOption(
                    label: label,
                    icon: icon,
                    active: mode == m,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      themeCtrl.setThemeMode(m);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          const _Heading('Dark mode styles', hint: 'Choose how dark mode looks. Picking one switches to dark mode.'),
          _Grid(
            children: [
              for (final s in duoDarkStyles)
                _StyleCard(
                  style: s,
                  active: appearance.darkStyle == s.id && resolvedDark,
                  locked: s.premium && !isPremium,
                  onTap: () {
                    if (s.premium && !isPremium) return upgrade();
                    appearanceCtrl.setDarkStyle(s.id);
                    if (!resolvedDark) themeCtrl.setThemeMode(ThemeMode.dark);
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _Heading('Light mode styles', hint: 'Choose how light mode looks. Picking one switches to light mode.'),
          _Grid(
            children: [
              for (final s in duoLightStyles)
                _StyleCard(
                  style: s,
                  active: appearance.lightStyle == s.id && !resolvedDark,
                  locked: s.premium && !isPremium,
                  onTap: () {
                    if (s.premium && !isPremium) return upgrade();
                    appearanceCtrl.setLightStyle(s.id);
                    if (resolvedDark) themeCtrl.setThemeMode(ThemeMode.light);
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _Heading('Color theme', hint: 'Pick a palette for buttons, highlights and gradients across Duo.'),
          if (!isPremium) ...[
            _UpgradeBanner(onUpgrade: upgrade),
            const SizedBox(height: 12),
          ],
          _Grid(
            children: [
              for (final p in duoPalettes)
                _PaletteCard(
                  palette: p,
                  active: appearance.palette == p.id,
                  locked: p.premium && !isPremium,
                  onTap: () {
                    if (p.premium && !isPremium) return upgrade();
                    HapticFeedback.selectionClick();
                    appearanceCtrl.setPalette(p.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _Heading('Navbar icons', hint: 'Choose the icon style for the bottom navigation bar.'),
          _Grid(
            children: [
              for (final set in duoNavIconSets)
                _IconSetCard(
                  set: set,
                  active: appearance.iconSet == set.id,
                  locked: set.premium && !isPremium,
                  onTap: () {
                    if (set.premium && !isPremium) return upgrade();
                    HapticFeedback.selectionClick();
                    appearanceCtrl.setIconSet(set.id);
                  },
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _Heading('Preview'),
          const _PreviewCard(),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _IconSetCard extends StatelessWidget {
  const _IconSetCard({required this.set, required this.active, required this.locked, required this.onTap});

  final NavIconSet set;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.primary : scheme.onSurfaceVariant;
    return Material(
      color: active ? scheme.primary.withValues(alpha: 0.1) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
          width: active ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < set.icons.length; i++)
                      Icon(i == 2 ? set.icons[i].$2 : set.icons[i].$1, size: 19, color: fg),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      set.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (locked)
                    Icon(Icons.lock_rounded, size: 14, color: scheme.onSurfaceVariant)
                  else if (active)
                    Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary)
                  else if (set.premium)
                    const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFD4A24C)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 560 ? 3 : 2;
        const gap = 12.0;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Material(
      color: active ? scheme.primary.withValues(alpha: 0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.preview,
    required this.name,
    required this.description,
    required this.premium,
    required this.active,
    required this.locked,
    required this.onTap,
  });

  final Widget preview;
  final String name;
  final String description;
  final bool premium;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final premiumColor = context.duo.premium;
    return Material(
      clipBehavior: Clip.antiAlias,
      color: scheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.35),
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                preview,
                if (locked)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x59000000),
                      child: Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 22)),
                    ),
                  ),
                if (active)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded, size: 14, color: scheme.onPrimary),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: premium
                              ? premiumColor.withValues(alpha: 0.15)
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          premium ? 'PREMIUM' : 'FREE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: premium ? premiumColor : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({required this.palette, required this.active, required this.locked, required this.onTap});

  final DuoPalette palette;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final [c1, c2, c3] = palette.swatch;
    return _CardShell(
      name: palette.name,
      description: palette.description,
      premium: palette.premium,
      active: active,
      locked: locked,
      onTap: onTap,
      preview: Container(
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.previewSurface,
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [c1.withValues(alpha: 0.33), palette.previewSurface],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [c1, c3]),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(colors: [c1, c2, c3]),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c2,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.active, required this.locked, required this.onTap});

  final DuoSurfaceStyle style;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final [bg, card, text] = style.preview;
    final primary = Theme.of(context).colorScheme.primary;
    return _CardShell(
      name: style.name,
      description: style.description,
      premium: style.premium,
      active: active,
      locked: locked,
      onTap: onTap,
      preview: Container(
        height: 80,
        color: bg,
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.66,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(99)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final premium = context.duo.premium;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: premium.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: premium.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: premium),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Premium themes', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Upgrade to Duo Premium to unlock every color theme plus the extra dark and light styles.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onUpgrade, child: const Text('Upgrade')),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: duo.brandGradient),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alex, 26', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      'Coffee, hikes and late-night talks.',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: duo.brandGradient,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.favorite_rounded, color: scheme.onPrimary, size: 18),
                    label: Text('Like', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
