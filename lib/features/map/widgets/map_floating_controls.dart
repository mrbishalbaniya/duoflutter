import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/map_layer_catalog.dart';
import '../providers/map_providers.dart';

/// Premium Material 3 floating map controls — right-side vertical stack.
class MapFloatingControls extends ConsumerStatefulWidget {
  const MapFloatingControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenterNorth,
    required this.onLocate,
    required this.onOpenSettings,
    this.isFullscreen = false,
    this.followMe = false,
    this.onToggleFollowMe,
    this.onToggleFullscreen,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenterNorth;
  final VoidCallback onLocate;
  final VoidCallback onOpenSettings;
  final bool isFullscreen;
  final bool followMe;
  final VoidCallback? onToggleFollowMe;
  final VoidCallback? onToggleFullscreen;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.onToggleFullscreen != null && widget.isFullscreen)
          _MapFab(
            icon: Icons.fullscreen_exit_rounded,
            tooltip: 'Exit fullscreen',
            onTap: () {
              _haptic();
              widget.onToggleFullscreen!();
            },
          ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.06, end: 0),
        if (widget.onToggleFullscreen != null && widget.isFullscreen)
          const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topRight,
          child: _layersOpen
              ? _LayersFlyout(
                  activeStyleId: activeStyle.id,
                  followMe: widget.followMe,
                  onSelectStyle: (id) {
                    _haptic();
                    notifier.setBaseMap(id);
                    setState(() => _layersOpen = false);
                  },
                  onZoomIn: () {
                    _haptic();
                    widget.onZoomIn();
                  },
                  onZoomOut: () {
                    _haptic();
                    widget.onZoomOut();
                  },
                  onToggleFollowMe: widget.onToggleFollowMe == null
                      ? null
                      : () {
                          _haptic();
                          widget.onToggleFollowMe!();
                        },
                  onToggleFullscreen: widget.onToggleFullscreen == null
                      ? null
                      : () {
                          _haptic();
                          widget.onToggleFullscreen!();
                          setState(() => _layersOpen = false);
                        },
                )
              : const SizedBox.shrink(),
        ),
        if (_layersOpen) const SizedBox(height: 10),
        _MapFab(
          icon: Icons.my_location_rounded,
          tooltip: widget.followMe ? 'Following your location' : 'My location',
          highlighted: widget.followMe,
          onTap: () {
            _haptic();
            widget.onLocate();
          },
        ),
        const SizedBox(height: 10),
        _MapFab(
          icon: _layersOpen ? Icons.layers_rounded : activeStyle.icon,
          tooltip: 'Map layers',
          highlighted: _layersOpen,
          onTap: () {
            _haptic();
            setState(() => _layersOpen = !_layersOpen);
          },
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        _MapFab(
          icon: Icons.explore_rounded,
          tooltip: 'Reset compass',
          onTap: () {
            _haptic();
            _closeLayers();
            widget.onRecenterNorth();
          },
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideX(begin: 0.08, end: 0);
  }
}

class _LayersFlyout extends StatelessWidget {
  const _LayersFlyout({
    required this.activeStyleId,
    required this.followMe,
    required this.onSelectStyle,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onToggleFollowMe,
    this.onToggleFullscreen,
  });

  final String activeStyleId;
  final bool followMe;
  final ValueChanged<String> onSelectStyle;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onToggleFollowMe;
  final VoidCallback? onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < baseMapStyles().length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.15),
                  ),
                _MapFab(
                  icon: baseMapStyles()[i].icon,
                  tooltip: baseMapStyles()[i].label,
                  highlighted: baseMapStyles()[i].id == activeStyleId,
                  compact: true,
                  onTap: () => onSelectStyle(baseMapStyles()[i].id),
                ),
              ],
              Divider(
                height: 1,
                color: scheme.outline.withValues(alpha: 0.15),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapFab(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom in',
                    compact: true,
                    onTap: onZoomIn,
                  ),
                  _MapFab(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom out',
                    compact: true,
                    onTap: onZoomOut,
                  ),
                  if (onToggleFollowMe != null)
                    _MapFab(
                      icon: followMe ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                      tooltip: followMe ? 'Stop following' : 'Follow me',
                      highlighted: followMe,
                      compact: true,
                      onTap: onToggleFollowMe!,
                    ),
                  if (onToggleFullscreen != null)
                    _MapFab(
                      icon: Icons.fullscreen_rounded,
                      tooltip: 'Fullscreen',
                      compact: true,
                      onTap: onToggleFullscreen!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

class _MapFab extends StatefulWidget {
  const _MapFab({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.highlighted = false,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool highlighted;
  final bool compact;

  @override
  State<_MapFab> createState() => _MapFabState();
}

class _MapFabState extends State<_MapFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.compact ? 44.0 : 46.0;
    final iconSize = 21.0;
    final bg = widget.highlighted
        ? DuoColors.primary
        : scheme.surface.withValues(alpha: 0.94);
    final fg = widget.highlighted ? Colors.white : scheme.onSurface;

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
                ? DuoColors.primary.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: _pressed ? 0.08 : 0.16),
              blurRadius: _pressed ? 8 : 14,
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
            splashColor: DuoColors.primary.withValues(alpha: 0.12),
            highlightColor: DuoColors.primary.withValues(alpha: 0.06),
            child: Icon(widget.icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
