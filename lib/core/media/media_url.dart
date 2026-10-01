import '../config/app_config.dart';
import '../models/user_models.dart';
import 'cloudinary_url.dart';

const _placeholderPhotos = [
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&h=800&fit=crop&q=80',
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&h=800&fit=crop&q=80',
];

int _hashSeed(String seed) {
  var hash = 0;
  for (var i = 0; i < seed.length; i++) {
    hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return hash;
}

String placeholderPhotoUrl(String seed, {int index = 0, String size = '600/800'}) {
  final parts = size.split('/');
  final w = parts.isNotEmpty ? parts[0] : '600';
  final h = parts.length > 1 ? parts[1] : '800';
  final base = _placeholderPhotos[(_hashSeed(seed) + index) % _placeholderPhotos.length];
  return base.replaceAll('w=600&h=800', 'w=$w&h=$h');
}

String? _backendOrigin() {
  final api = Uri.tryParse(AppConfig.apiBaseUrl);
  if (api == null || api.host.isEmpty) return null;
  return Uri(
    scheme: api.scheme,
    host: api.host,
    port: api.hasPort ? api.port : null,
  ).toString();
}

const _loopbackHosts = {'localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0'};

/// Local dev data stores photos as `http://localhost:8000/media/...`, which a
/// physical phone cannot reach. When the app talks to a plain-HTTP (LAN dev)
/// backend, point those URLs and bare `/media/` paths at that backend instead.
/// Production (HTTPS API) URLs are returned unchanged.
String localizeMediaUrl(String url) {
  final origin = _backendOrigin();
  if (origin == null || !origin.startsWith('http://')) return url;
  if (url.startsWith('/media/')) return '$origin$url';
  final uri = Uri.tryParse(url);
  if (uri == null || !_loopbackHosts.contains(uri.host) || !uri.path.startsWith('/media/')) {
    return url;
  }
  final base = Uri.parse(origin);
  return uri.replace(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null).toString();
}

bool _isDeadLocalMediaUrl(String url) {
  return url.startsWith('/media/') ||
      (url.contains('://localhost') && url.contains('/media/'));
}

String? _remapPicsumUrl(String url) {
  final match = RegExp(r'picsum\.photos/seed/([^/]+)').firstMatch(url);
  final seed = match?.group(1) ?? 'duo';
  final indexMatch = RegExp(r'-(\d+)$').firstMatch(seed);
  final index = indexMatch != null ? int.tryParse(indexMatch.group(1) ?? '0') ?? 0 : 0;
  final baseSeed = seed.replaceAll(RegExp(r'-\d+$'), '');
  final sizeMatch = RegExp(r'/(\d+)/(\d+)(?:\?|$)').firstMatch(url);
  final size = sizeMatch != null ? '${sizeMatch.group(1)}/${sizeMatch.group(2)}' : '600/800';
  return placeholderPhotoUrl(baseSeed, index: index > 0 ? index - 1 : 0, size: size);
}

/// Resolve stored media URLs (Cloudinary HTTPS, legacy /media/, or broken picsum seeds).
String? resolveMediaUrl(String? url, {CloudinaryPreset preset = CloudinaryPreset.medium}) {
  final trimmed = localizeMediaUrl(url?.trim() ?? '');
  if (trimmed.isEmpty) return null;
  if (trimmed.contains('picsum.photos')) return _remapPicsumUrl(trimmed);
  if (_isDeadLocalMediaUrl(trimmed)) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    final cloudinary = cloudinaryDeliveryUrl(trimmed, preset: preset);
    return cloudinary.isNotEmpty ? cloudinary : trimmed;
  }

  if (trimmed.startsWith('/media/')) {
    final origin = _backendOrigin();
    if (origin == null) return null;
    return cloudinaryDeliveryUrl('$origin$trimmed', preset: preset);
  }

  return trimmed;
}

/// Primary discover/match card photo with placeholder fallback.
String resolveProfilePhotoUrl(DuoProfile profile, {CloudinaryPreset preset = CloudinaryPreset.matchCard}) {
  final seed = '${profile.resolvedUserId ?? profile.fullName}';
  final primary = resolveMediaUrl(profile.photoUrl, preset: preset);
  if (primary != null && primary.isNotEmpty) return primary;

  for (final url in profile.photoUrls) {
    final resolved = resolveMediaUrl(url, preset: preset);
    if (resolved != null && resolved.isNotEmpty) return resolved;
  }

  return placeholderPhotoUrl(seed);
}

/// Up to [count] card photos, padded with placeholders (mirrors web
/// `resolveProfilePhotoUrls`).
List<String> resolveProfilePhotoUrls(
  DuoProfile profile, {
  int count = 3,
  CloudinaryPreset preset = CloudinaryPreset.matchCard,
}) {
  final seed = '${profile.resolvedUserId ?? profile.fullName}';
  final fallbacks = [for (var i = 0; i < count; i++) placeholderPhotoUrl(seed, index: i)];

  if (profile.photoUrls.isNotEmpty) {
    final urls = profile.photoUrls
        .map((u) => resolveMediaUrl(u, preset: preset))
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .take(count)
        .toList();
    for (var i = urls.length; i < count; i++) {
      urls.add(fallbacks[i]);
    }
    return urls;
  }

  final primary = resolveMediaUrl(profile.photoUrl, preset: preset);
  if (primary != null && primary.isNotEmpty) return [primary, ...fallbacks.skip(1)];
  return fallbacks;
}
