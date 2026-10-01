import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_extensions.dart';
import '../domain/map_layer_catalog.dart';
import '../providers/map_providers.dart';

/// Top-right: the city you are in, with the current temperature below it.
class MapLocationWeatherCard extends ConsumerWidget {
  const MapLocationWeatherCard({super.key});

  static IconData _iconFor(String main) {
    final m = main.toLowerCase();
    if (m.contains('thunder')) return Icons.thunderstorm_rounded;
    if (m.contains('snow')) return Icons.ac_unit_rounded;
    if (m.contains('rain') || m.contains('drizzle')) return Icons.water_drop_rounded;
    if (m.contains('cloud')) return Icons.cloud_rounded;
    if (m.contains('mist') || m.contains('fog') || m.contains('haze') || m.contains('smoke')) {
      return Icons.foggy;
    }
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(mapCurrentCityProvider).valueOrNull;
    final weather = ref.watch(mapCurrentTemperatureProvider).valueOrNull;
    // Never show placeholder values.
    if (city == null && weather == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // Short condition only ("Clouds", "Rain"), not the long description.
    final label = weather?.main.trim() ?? '';

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: _themedControlDecoration(context, radius: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (city != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: scheme.primary, shadows: _mapShadows),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, shadows: _mapShadows),
                  ),
                ),
              ],
            ),
          if (weather != null) ...[
            if (city != null) const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(weather.main), size: 14, color: scheme.primary, shadows: _mapShadows),
                const SizedBox(width: 4),
                Text(
                  '${weather.temperature.round()}°',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, shadows: _mapShadows),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), shadows: _mapShadows),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

/// Map controls float without a background; this only keeps the shape
/// (for the ink ripple).
BoxDecoration _themedControlDecoration(BuildContext context, {double radius = 14, bool pressed = false}) {
  return BoxDecoration(borderRadius: BorderRadius.circular(radius));
}

/// Soft dark halo so bare icons and text stay readable over any map style.
const _mapShadows = [Shadow(color: Color(0xB3000000), blurRadius: 6)];

/// Bottom-right, top to bottom: map settings, layers (with "reset rotation"
/// inside), find my location.
class MapBottomControls extends ConsumerStatefulWidget {
  const MapBottomControls({
    super.key,
    required this.onRecenterNorth,
    required this.onOpenSettings,
    this.onLocateMe,
    this.locateLoading = false,
  });

  final VoidCallback onRecenterNorth;
  final VoidCallback onOpenSettings;
  final VoidCallback? onLocateMe;
  final bool locateLoading;

  @override
  ConsumerState<MapBottomControls> createState() => _MapBottomControlsState();
}

class _MapBottomControlsState extends ConsumerState<MapBottomControls> {
  bool _layersOpen = false;

  void _haptic() => HapticFeedback.lightImpact();

  @override
  Widget build(BuildContext context) {
    final layers = ref.watch(mapLayerStateProvider);
    final notifier = ref.read(mapLayerStateProvider.notifier);
    final activeBaseId = activeBaseMapId(layers.enabled);
    final activeStyle = layerById(activeBaseId) ?? baseMapStyles().first;
    final styles = baseMapStyles();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MapFab(
          icon: Icons.settings_rounded,
          tooltip: 'Map settings',
          onTap: () {
            _haptic();
            if (_layersOpen) setState(() => _layersOpen = false);
            ref.read(mapLayerStateProvider.notifier).toggleSettingsOpen();
            widget.onOpenSettings();
          },
        ),
        const SizedBox(height: 10),
        // Layers panel opens upward from the layers button.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomRight,
          child: _layersOpen
              // Icon-only options (names stay as long-press tooltips).
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final style in styles) ...[
                        _MapFab(
                          icon: style.icon,
                          tooltip: style.label,
                          highlighted: style.id == activeStyle.id,
                          onTap: () {
                            _haptic();
                            notifier.setBaseMap(style.id);
                            setState(() => _layersOpen = false);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      _MapFab(
                        icon: Icons.explore_rounded,
                        tooltip: 'Reset rotation (north up)',
                        onTap: () {
                          _haptic();
                          widget.onRecenterNorth();
                          setState(() => _layersOpen = false);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 160.ms).slideY(begin: 0.05, end: 0)
              : const SizedBox.shrink(),
        ),
        // Layers sits directly above the find-my-location button.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _MapFab(
              icon: _layersOpen ? Icons.close_rounded : Icons.layers_rounded,
              tooltip: 'Map layers',
              highlighted: _layersOpen,
              onTap: () {
                _haptic();
                setState(() => _layersOpen = !_layersOpen);
              },
            ),
            if (widget.onLocateMe != null) ...[
              const SizedBox(height: 10),
              MapLocateButton(
                loading: widget.locateLoading,
                onPressed: () {
                  if (_layersOpen) setState(() => _layersOpen = false);
                  widget.onLocateMe!();
                },
              ),
            ],
          ],
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Glass-style locate button for the map screen.
class MapLocateButton extends StatefulWidget {
  const MapLocateButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  State<MapLocateButton> createState() => _MapLocateButtonState();
}

class _MapLocateButtonState extends State<MapLocateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    final duo = context.duo;
    final button = AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: _themedControlDecoration(context, radius: 16, pressed: _pressed),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.loading ? null : () {
              HapticFeedback.lightImpact();
              widget.onPressed();
            },
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(16),
            splashColor: duo.mapControlForeground.withValues(alpha: 0.12),
            highlightColor: duo.mapControlForeground.withValues(alpha: 0.06),
            child: widget.loading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: duo.mapControlForeground,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                    shadows: _mapShadows,
                  ),
          ),
        ),
      ),
    );

    return Tooltip(message: 'Find my location', child: button);
  }
}

class _MapFab extends StatefulWidget {
  const _MapFab({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool highlighted;

  @override
  State<_MapFab> createState() => _MapFabState();
}

class _MapFabState extends State<_MapFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const iconSize = 20.0;
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.highlighted ? Colors.white : scheme.primary;

    final button = AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: _themedControlDecoration(context, pressed: _pressed),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(14),
            splashColor: fg.withValues(alpha: 0.12),
            highlightColor: fg.withValues(alpha: 0.06),
            child: Icon(
              widget.icon,
              size: iconSize,
              color: fg,
              shadows: widget.highlighted
                  ? [Shadow(color: scheme.primary, blurRadius: 10), ..._mapShadows]
                  : _mapShadows,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
