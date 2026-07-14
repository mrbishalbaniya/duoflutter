import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:duo_mobile/core/media/cloudinary_url.dart';

/// Optimized network image with Cloudinary transforms, caching, and retry.
class DuoNetworkImage extends StatelessWidget {
  const DuoNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    this.memCacheWidth,
    this.memCacheHeight,
    this.preset = CloudinaryPreset.medium,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final CloudinaryPreset preset;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _placeholder(context);
    }

    final deliveryUrl = cloudinaryDeliveryUrl(trimmed, preset: preset);
    final cacheWidth = memCacheWidth ?? cloudinaryMemCacheWidth(preset);

    Widget image = CachedNetworkImage(
      imageUrl: deliveryUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => _placeholder(context),
      errorWidget: (_, __, ___) => _placeholder(context, failed: true),
    );

    if (width == null && height == null) {
      image = SizedBox.expand(child: image);
    }

    Widget child = image;
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    if (semanticLabel != null) {
      child = Semantics(label: semanticLabel, image: true, child: child);
    }
    return child;
  }

  Widget _placeholder(BuildContext context, {bool failed = false}) {
    final theme = Theme.of(context);
    final icon = Icon(
      failed ? Icons.broken_image_outlined : Icons.image_outlined,
      size: (width != null && height != null)
          ? (width! < height! ? width! : height!) * 0.28
          : 32,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: width == null && height == null ? Center(child: icon) : icon,
    );
  }
}
