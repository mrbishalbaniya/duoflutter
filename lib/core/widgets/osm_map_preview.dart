import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const _tile = 256.0;

/// OSM tile servers require an identifying User-Agent.
const _tileHeaders = {'User-Agent': 'DuoMobile/1.0'};

const _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';

Widget _tileImage(String url) => CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _tileHeaders,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );

/// Static map preview (Esri Light/Dark Gray Canvas) centred on [lat]/[lng] with a pin.
/// Fills the available width; no map SDK or API key needed.
class OsmMapPreview extends StatelessWidget {
  const OsmMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 176,
    this.zoom = 14,
    this.showAreaCircle = false,
  });

  final double lat;
  final double lng;
  final double height;
  final int zoom;

  /// Soft circle around the pin: signals "approximate area", not an exact address.
  final bool showAreaCircle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final n = math.pow(2, zoom).toInt();
        final x = (lng + 180) / 360 * n;
        final rad = lat * math.pi / 180;
        final y = (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n;
        final tx = x.floor();
        final ty = y.floor();
        // Pixel position of the point inside the centre tile.
        final px = (x - tx) * _tile;
        final py = (y - ty) * _tile;
        final cols = (width / _tile / 2).ceil() + 1;
        final rows = (height / _tile / 2).ceil() + 1;

        final tiles = <Widget>[];
        for (var dy = -rows; dy <= rows; dy++) {
          for (var dx = -cols; dx <= cols; dx++) {
            final tileX = ((tx + dx) % n + n) % n;
            final tileY = ty + dy;
            if (tileY < 0 || tileY >= n) continue;
            tiles.add(Positioned(
              left: width / 2 - px + dx * _tile,
              top: height / 2 - py + dy * _tile,
              width: _tile,
              height: _tile,
              // Esri Gray Canvas: clean, minimal basemap (light or dark) + light label layer.
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _tileImage('$_esri/World_${dark ? 'Dark' : 'Light'}_Gray_Base/MapServer/tile/$zoom/$tileY/$tileX'),
                  _tileImage('$_esri/World_${dark ? 'Dark' : 'Light'}_Gray_Reference/MapServer/tile/$zoom/$tileY/$tileX'),
                ],
              ),
            ));
          }
        }

        final map = Stack(clipBehavior: Clip.hardEdge, children: tiles);

        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: scheme.surfaceContainerHigh)),
              Positioned.fill(child: map),
              if (showAreaCircle)
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.14),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.45), width: 1.5),
                    ),
                  ),
                ),
              // Pin tip sits on the point.
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: scheme.primary,
                    shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
