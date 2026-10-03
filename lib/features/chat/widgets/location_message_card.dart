import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/chat_location.dart';

const _zoom = 15;
const _tile = 256.0;
const _cardWidth = 260.0;
const _cardHeight = 150.0;

/// OSM tile servers require an identifying User-Agent.
const _tileHeaders = {'User-Agent': 'DuoMobile/1.0'};

/// Port of DuoFrontend `LocationMessageCard.tsx`: OpenStreetMap preview with a
/// centred pin, footer with address, tap opens Google Maps.
class LocationMessageCard extends StatelessWidget {
  const LocationMessageCard({
    super.key,
    required this.location,
    required this.mine,
    this.addressLoading = false,
  });

  final SharedLocation location;
  final bool mine;
  final bool addressLoading;

  Future<void> _open() async {
    final uri = Uri.parse(location.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coords =
        '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}';
    return Material(
      color: scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: _open,
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MapPreview(lat: location.lat, lng: location.lng),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mine ? Icons.my_location : Icons.location_on,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mine ? 'Your location' : 'Shared location',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (addressLoading)
                            Container(
                              height: 10,
                              width: 130,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: scheme.onSurface.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          else
                            Text(
                              location.address ?? coords,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: scheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3x3 OSM tiles around the point, shifted so the point sits in the card centre.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final n = math.pow(2, _zoom).toInt();
    final x = (lng + 180) / 360 * n;
    final rad = lat * math.pi / 180;
    final y =
        (1 - math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) / 2 * n;
    final tx = x.floor();
    final ty = y.floor();
    final px = (x - tx) * _tile;
    final py = (y - ty) * _tile;
    final offsetX = _cardWidth / 2 - (_tile + px);
    final offsetY = _cardHeight / 2 - (_tile + py);

    final tiles = <Widget>[];
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final tileX = ((tx + dx) % n + n) % n;
        final tileY = ty + dy;
        if (tileY < 0 || tileY >= n) continue;
        tiles.add(
          Positioned(
            left: (dx + 1) * _tile + offsetX,
            top: (dy + 1) * _tile + offsetY,
            width: _tile,
            height: _tile,
            child: CachedNetworkImage(
              imageUrl:
                  'https://tile.openstreetmap.org/$_zoom/$tileX/$tileY.png',
              httpHeaders: _tileHeaders,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      }
    }

    Widget map = Stack(clipBehavior: Clip.hardEdge, children: tiles);
    if (dark) {
      // Web inverts tiles in dark mode; a dimming + desaturating matrix keeps the
      // map readable without the harsh inverted colours on Android.
      map = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -0.55, -0.25, -0.1, 0, 230, //
          -0.25, -0.55, -0.1, 0, 230, //
          -0.25, -0.25, -0.4, 0, 225, //
          0, 0, 0, 1, 0,
        ]),
        child: map,
      );
    }

    return SizedBox(
      height: _cardHeight,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: dark ? const Color(0xFF1B1B1D) : const Color(0xFFE8E4DE),
            ),
            map,
            const Align(
              alignment: Alignment(0, -0.28),
              child: Icon(
                Icons.location_on,
                size: 38,
                color: Color(0xFFF43F5E),
                shadows: [
                  Shadow(
                    color: Color(0x80000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
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

/// Port of `LocationConfirmDialog.tsx`: preview the found spot, then Send/Cancel.
/// Returns the resolved address (may be null) when the user taps Send, or throws
/// nothing and returns `(false, null)` when cancelled.
Future<({bool send, String? address})> showShareLocationSheet(
  BuildContext context, {
  required double lat,
  required double lng,
  String? recipientName,
}) async {
  final result = await showModalBottomSheet<({bool send, String? address})>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) =>
        _ShareLocationSheet(lat: lat, lng: lng, recipientName: recipientName),
  );
  return result ?? (send: false, address: null);
}

class _ShareLocationSheet extends StatefulWidget {
  const _ShareLocationSheet({
    required this.lat,
    required this.lng,
    this.recipientName,
  });

  final double lat;
  final double lng;
  final String? recipientName;

  @override
  State<_ShareLocationSheet> createState() => _ShareLocationSheetState();
}

class _ShareLocationSheetState extends State<_ShareLocationSheet> {
  String? _address;
  bool _lookupDone = false;

  @override
  void initState() {
    super.initState();
    fetchShortAddress(widget.lat, widget.lng).then((a) {
      if (!mounted) return;
      setState(() {
        _address = a;
        _lookupDone = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final who = (widget.recipientName ?? '').isNotEmpty
        ? '${widget.recipientName} will'
        : 'They will';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share_location, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share your location?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$who see this spot and can open it in Google Maps.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              child: LocationMessageCard(
                location: SharedLocation(
                  lat: widget.lat,
                  lng: widget.lng,
                  url: googleMapsUrl(widget.lat, widget.lng),
                  address: _address,
                ),
                mine: true,
                addressLoading: !_lookupDone,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, (send: false, address: null)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, (send: true, address: _address)),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send'),
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
