import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_extensions.dart';
import '../domain/map_layer_catalog.dart';
import '../providers/map_providers.dart';

/// Right-side map controls — layers toggle, settings, compass.
class MapFloatingControls extends ConsumerStatefulWidget {
  const MapFloatingControls({
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
  ConsumerState<MapFloatingControls> createState() => _MapFloatingControlsState();
}

class _MapFloatingControlsState extends ConsumerState<MapFloatingControls> {
  bool _layersOpen = false;

  void _haptic() => HapticFeedback.lightImpact();

  void _closeLayers() {
    if (_layersOpen) setState(() => _layersOpen = false);
  }

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
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topRight,
          child: _layersOpen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < styles.length; i++) ...[
                      _MapFab(
                        icon: styles[i].icon,
                        tooltip: styles[i].label,
                        highlighted: styles[i].id == activeStyle.id,
                        onTap: () {
                          _haptic();
                          notifier.setBaseMap(styles[i].id);
                          setState(() => _layersOpen = false);
                        },
                      ).animate().fadeIn(duration: 160.ms).slideX(begin: 0.05, end: 0),
                      if (i < styles.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                )
              : const SizedBox.shrink(),
        ),
        if (_layersOpen) const SizedBox(height: 8),
        _MapFab(
          icon: _layersOpen ? Icons.layers_rounded : activeStyle.icon,
          tooltip: 'Map layers',
          highlighted: _layersOpen,
          onTap: () {
            _haptic();
            setState(() => _layersOpen = !_layersOpen);
          },
        ),
        const SizedBox(height: 8),
        _MapFab(
          icon: Icons.tune_rounded,
          tooltip: 'Map settings',
          onTap: () {
            _haptic();
            _closeLayers();
            notifier.toggleSettingsOpen();
            widget.onOpenSettings();
          },
        ),
        const SizedBox(height: 8),
        _MapFab(
          icon: Icons.explore_rounded,
          tooltip: 'Reset compass',
          onTap: () {
            _haptic();
            _closeLayers();
            widget.onRecenterNorth();
          },
        ),
        if (widget.onLocateMe != null) ...[
          const SizedBox(height: 8),
          MapLocateButton(
            loading: widget.locateLoading,
            onPressed: widget.onLocateMe!,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 280.ms).slideX(begin: 0.08, end: 0);
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
    const size = 48.0;
    final duo = context.duo;
    final button = AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: duo.mapControlBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: duo.mapControlBorder),
          boxShadow: [
            BoxShadow(
              color: duo.cardShadow,
              blurRadius: _pressed ? 6 : 12,
              offset: Offset(0, _pressed ? 2 : 4),
            ),
          ],
        ),
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
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: duo.mapControlForeground,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    size: 22,
                    color: duo.mapControlForeground,
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
    const size = 44.0;
    const iconSize = 21.0;
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.highlighted ? scheme.primary : duo.mapControlBackground;
    final fg = widget.highlighted ? scheme.onPrimary : duo.mapControlForeground;

    final button = AnimatedScale(
      scale: _pressed ? 0.9 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.highlighted
                ? scheme.primary.withValues(alpha: 0.6)
                : duo.mapControlBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: duo.cardShadow,
              blurRadius: _pressed ? 6 : 12,
              offset: Offset(0, _pressed ? 2 : 4),
            ),
          ],
        ),
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
            child: Icon(widget.icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
