import 'package:dio/dio.dart';

/// Port of DuoFrontend `lib/chatLocation.ts`.
///
/// Shared-location messages are plain text containing a standard Google Maps link,
/// so web and mobile render the same card and other clients still see a link:
///   `Shared location: <address>\n<google maps url>`
class SharedLocation {
  const SharedLocation({
    required this.lat,
    required this.lng,
    required this.url,
    this.address,
  });

  final double lat;
  final double lng;
  final String url;
  final String? address;
}

const locationMessagePrefix = 'Shared location';

String googleMapsUrl(double lat, double lng) =>
    'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

String buildLocationMessage(double lat, double lng, [String? address]) {
  var clean = (address ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.length > 160) clean = clean.substring(0, 160);
  final url = googleMapsUrl(lat, lng);
  return clean.isNotEmpty
      ? '$locationMessagePrefix: $clean\n$url'
      : '$locationMessagePrefix: $url';
}

const _coord = r'(-?\d{1,2}(?:\.\d+)?),\s*(-?\d{1,3}(?:\.\d+)?)';
final _patterns = [
  RegExp(
    'google\\.[a-z.]+/maps/search/\\?api=1&query=$_coord',
    caseSensitive: false,
  ),
  RegExp('google\\.[a-z.]+/maps\\?q=$_coord', caseSensitive: false),
  RegExp('google\\.[a-z.]+/maps/@$_coord', caseSensitive: false),
  RegExp('maps\\.google\\.[a-z.]+/\\?q=$_coord', caseSensitive: false),
];

/// Returns the location if the whole message is a shared-location link.
SharedLocation? parseLocationMessage(String? content) {
  final text = (content ?? '').trim();
  if (text.isEmpty || text.length > 300) return null;
  final urlMatch = RegExp(r'https?://\S+').firstMatch(text);
  if (urlMatch == null) return null;
  final url = urlMatch.group(0)!;
  final hasPrefix = text.startsWith('$locationMessagePrefix:');
  final rest = text
      .replaceFirst(url, '')
      .replaceFirst('$locationMessagePrefix:', '')
      .trim();
  // Without our prefix only a bare link counts; with it, the rest is the address.
  if (rest.isNotEmpty && !hasPrefix) return null;
  for (final re in _patterns) {
    final m = re.firstMatch(url);
    if (m == null) continue;
    final lat = double.tryParse(m.group(1)!);
    final lng = double.tryParse(m.group(2)!);
    if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
      return SharedLocation(
        lat: lat,
        lng: lng,
        url: url,
        address: rest.isEmpty ? null : rest,
      );
    }
  }
  return null;
}

/// "Kathmandu Metropolitan City" -> "Kathmandu".
String _shortCity(String name) => name
    .replaceAll(
      RegExp(
        r'\s+(Sub-?Metropolitan City|Metropolitan City|Rural Municipality|Municipality|City)$',
        caseSensitive: false,
      ),
      '',
    )
    .trim();

final _geoDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Accept': 'application/json', 'User-Agent': 'DuoMobile/1.0'},
  ),
);

/// Short "Street, Area, City" address via OpenStreetMap Nominatim (same source the
/// web's /api/geocode/reverse route uses). Returns null on any failure.
Future<String?> fetchShortAddress(double lat, double lng) async {
  try {
    final res = await _geoDio.get<Map<String, dynamic>>(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'addressdetails': 1,
        'zoom': 18,
        // English names, never Devanagari.
        'accept-language': 'en',
      },
    );
    final data = res.data ?? const {};
    final a = (data['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    String pick(List<String> keys) => keys
        .map((k) => (a[k] ?? '').toString().trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final street = pick(['road', 'pedestrian', 'footway']);
    final area = pick(['neighbourhood', 'suburb', 'quarter']);
    final city = _shortCity(
      pick(['city', 'town', 'village', 'municipality', 'county']),
    );
    final parts = <String>[];
    for (final p in [street, area, city]) {
      if (p.isNotEmpty && !parts.contains(p)) parts.add(p);
    }
    if (parts.isNotEmpty) return parts.join(', ');
    final label = (data['display_name'] ?? '').toString();
    return label.isEmpty ? null : label.split(',').take(3).join(',').trim();
  } catch (_) {
    return null;
  }
}
