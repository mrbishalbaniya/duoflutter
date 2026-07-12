import '../../../chat/widgets/chat_media_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    return RepaintBoundary(
      child: Column(
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
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 400,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = photos[index];
                final tag = heroTagBuilder?.call(url, index) ?? 'profile-photo-$index';
                return Semantics(
                  label: 'Photo ${index + 1} of ${photos.length}',
                  button: true,
                  child: GestureDetector(
                    onTap: () => ProfileFullscreenGallery.open(
                      context,
                      photos: photos,
                      initialIndex: index,
                      heroTag: tag,
                    ),
                    child: Hero(
                      tag: tag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                        ),
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
      ),
    );
  }
}

class ProfileFullscreenGallery extends StatefulWidget {
  const ProfileFullscreenGallery({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.heroTag,
  });

  final List<String> photos;
  final int initialIndex;
  final String heroTag;

  static void open(
    BuildContext context, {
    required List<String> photos,
    required int initialIndex,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileFullscreenGallery(
          photos: photos,
          initialIndex: initialIndex,
          heroTag: heroTag,
        ),
      ),
    );
  }

  @override
  State<ProfileFullscreenGallery> createState() => _ProfileFullscreenGalleryState();
}

class _ProfileFullscreenGalleryState extends State<ProfileFullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.scrim,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onPrimary,
        title: Text('${_index + 1} / ${widget.photos.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => showChatMediaActionsSheet(
              context,
              media: ChatMediaActionContext(
                remoteUrl: widget.photos[_index],
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onLongPress: () => showChatMediaActionsSheet(
          context,
          media: ChatMediaActionContext(remoteUrl: widget.photos[_index]),
        ),
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            final child = InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
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
      ),
    );
  }
}
