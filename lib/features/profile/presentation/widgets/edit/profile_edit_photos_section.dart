import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/duo_theme.dart';
import '../../../domain/profile_edit_models.dart';
import '../profile_photo_gallery.dart';

class ProfileEditPhotosSection extends StatelessWidget {
  const ProfileEditPhotosSection({
    super.key,
    required this.photos,
    required this.photoError,
    required this.analyzingPhotos,
    required this.uploadProgress,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    required this.onSetPrimary,
    required this.onReorder,
  });

  final List<ProfileEditPhoto> photos;
  final String? photoError;
  final bool analyzingPhotos;
  final double? uploadProgress;
  final VoidCallback onPickPhotos;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<String> onSetPrimary;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add up to 9 photos. Drag to reorder. Star marks your main photo.',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 12),
        if (photoError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(photoError!, style: TextStyle(color: scheme.error)),
          ),
        if (analyzingPhotos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uploading and analyzing…'),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: uploadProgress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
        if (photos.isEmpty)
          _AddPhotoTile(onTap: analyzingPhotos ? null : onPickPhotos, analyzing: analyzingPhotos)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: photos.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoTile(
                key: ValueKey(photo.id),
                photo: photo,
                index: index,
                onRemove: () => onRemovePhoto(photo.id),
                onSetPrimary: () => onSetPrimary(photo.id),
                onTap: () => ProfileFullscreenGallery.open(
                  context,
                  photos: photos.map((p) => p.url).toList(),
                  initialIndex: index,
                  heroTag: 'edit-photo-${photo.id}',
                ),
              );
            },
          ),
        if (photos.isNotEmpty && photos.length < 9) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: analyzingPhotos ? null : onPickPhotos,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(analyzingPhotos ? 'Analyzing…' : 'Add more photos'),
          ),
        ],
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap, required this.analyzing});

  final VoidCallback? onTap;
  final bool analyzing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              analyzing ? 'Analyzing…' : 'Add your first photo',
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.index,
    required this.onRemove,
    required this.onSetPrimary,
    required this.onTap,
  });

  final ProfileEditPhoto photo;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle_rounded, color: scheme.onSurfaceVariant),
          ),
          title: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 72,
                child: CachedNetworkImage(imageUrl: photo.url, fit: BoxFit.cover),
              ),
            ),
          ),
          subtitle: Text(
            photo.isProfile ? 'Main photo' : 'Tap star to set main',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Set as main photo',
                onPressed: onSetPrimary,
                icon: Icon(
                  photo.isProfile ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: photo.isProfile ? DuoColors.warning : scheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
