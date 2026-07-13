/// Cloudinary delivery URL transforms — mirrors backend presets.
library;

const _defaultDelivery = 'f_auto,q_auto:good,fl_progressive,dpr_auto';

enum CloudinaryPreset {
  thumb,
  avatar,
  small,
  medium,
  large,
  discoverCard,
  matchCard,
  chatPreview,
  gallery,
  verification,
}

const _presetTransforms = <CloudinaryPreset, String>{
  CloudinaryPreset.thumb: 'w_96,h_96,c_fill,g_face,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.avatar:
      'w_128,h_128,c_fill,g_face,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.small:
      'w_320,h_400,c_fill,g_auto,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.medium:
      'w_640,h_800,c_fill,g_auto,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.large:
      'w_1080,h_1350,c_limit,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.discoverCard:
      'w_480,h_600,c_fill,g_auto,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.matchCard:
      'w_420,h_560,c_fill,g_face,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.chatPreview:
      'w_480,h_480,c_limit,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.gallery:
      'w_720,h_900,c_limit,f_auto,q_auto:good,fl_progressive,dpr_auto',
  CloudinaryPreset.verification:
      'w_512,h_512,c_fill,g_face,f_auto,q_auto:good,fl_progressive,dpr_auto',
};

final _transformSegment = RegExp(r'^(?:[a-z]{1,3}_[^,/]+)(?:,[a-z]{1,3}_[^,/]+)*$');

bool isCloudinaryUrl(String? url) =>
    url != null && url.contains('res.cloudinary.com');

bool _isTransformationSegment(String segment) {
  if (segment.isEmpty) return false;
  if (RegExp(r'^v\d+$').hasMatch(segment)) return false;
  return _transformSegment.hasMatch(segment);
}

/// Apply dynamic Cloudinary transforms; passthrough for non-Cloudinary URLs.
String cloudinaryDeliveryUrl(
  String? url, {
  CloudinaryPreset preset = CloudinaryPreset.medium,
}) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (!isCloudinaryUrl(trimmed)) return trimmed;

  final transform = _presetTransforms[preset] ?? _defaultDelivery;
  const marker = '/upload/';
  final idx = trimmed.indexOf(marker);
  if (idx < 0) return trimmed;

  final base = trimmed.substring(0, idx + marker.length);
  final rest = trimmed.substring(idx + marker.length);
  final segments = rest.split('/');
  while (segments.isNotEmpty && _isTransformationSegment(segments.first)) {
    segments.removeAt(0);
  }
  return '$base$transform/${segments.join('/')}';
}

/// Video poster frame from Cloudinary video delivery URL.
String? cloudinaryVideoPoster(String? url) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty || !isCloudinaryUrl(trimmed)) {
    return null;
  }
  if (!trimmed.contains('/video/upload/')) return null;
  final asImage = trimmed.replaceFirst('/video/upload/', '/image/upload/');
  return cloudinaryDeliveryUrl(
    asImage,
    preset: CloudinaryPreset.chatPreview,
  ).replaceFirst(
    _presetTransforms[CloudinaryPreset.chatPreview]!,
    'w_640,c_fill,f_jpg,q_auto:good',
  );
}

/// Suggested memCacheWidth for a preset (device pixel ratio ~2).
int? cloudinaryMemCacheWidth(CloudinaryPreset preset) {
  switch (preset) {
    case CloudinaryPreset.thumb:
      return 96 * 2;
    case CloudinaryPreset.avatar:
      return 128 * 2;
    case CloudinaryPreset.small:
      return 320 * 2;
    case CloudinaryPreset.medium:
      return 640 * 2;
    case CloudinaryPreset.large:
      return 1080 * 2;
    case CloudinaryPreset.discoverCard:
      return 480 * 2;
    case CloudinaryPreset.matchCard:
      return 420 * 2;
    case CloudinaryPreset.chatPreview:
      return 480 * 2;
    case CloudinaryPreset.gallery:
      return 720 * 2;
    case CloudinaryPreset.verification:
      return 512 * 2;
  }
}
