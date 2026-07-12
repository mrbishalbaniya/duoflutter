import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePhotoGallery extends StatelessWidget {
  const ProfilePhotoGallery({
    super.key,
    required this.photos,
    this.heroTagBuilder,
  });

  final List<String> photos;
  final String Function(String url, int index)? heroTagBuilder;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'PHOTOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final url = photos[index];
              final tag = heroTagBuilder?.call(url, index) ?? 'profile-photo-$index';
              return GestureDetector(
                onTap: () => _openViewer(context, photos, index, tag),
                child: Hero(
                  tag: tag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ).animate(delay: (40 * index).ms).fadeIn().scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                  );
            },
          ),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<String> photos, int initial, String heroTag) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenGallery(
          photos: photos,
          initialIndex: initial,
          heroTag: heroTag,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.photos,
    required this.initialIndex,
    required this.heroTag,
  });

  final List<String> photos;
  final int initialIndex;
  final String heroTag;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          final child = InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(imageUrl: photo, fit: BoxFit.contain),
            ),
          );
          if (index == widget.initialIndex) {
            return Hero(tag: widget.heroTag, child: child);
          }
          return child;
        },
      ),
    );
  }
}
