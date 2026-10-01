import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/media/media_url.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/core_providers.dart';
import '../../repositories/chat_repository.dart';
import '../profile/domain/public_profile.dart';
import 'widgets/chat_media_viewer.dart';

/// Port of DuoFrontend `components/chat/ChatProfileView.tsx` — messenger-style
/// "contact info" for the person you're chatting with.
class ChatProfileScreen extends ConsumerStatefulWidget {
  const ChatProfileScreen({
    super.key,
    required this.profile,
    this.conversationId,
    this.matchedAt,
    this.onVoiceCall,
    this.onVideoCall,
    this.onOpenInsights,
  });

  final DuoProfile profile;
  final String? conversationId;
  final String? matchedAt;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onOpenInsights;

  @override
  ConsumerState<ChatProfileScreen> createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends ConsumerState<ChatProfileScreen> {
  @override
  void initState() {
    super.initState();
    final id = widget.profile.id;
    if (id != null) {
      // Same as web: opening someone's profile records a visit (best effort).
      ref.read(profileRepositoryProvider).recordVisit(id).catchError((_) {});
    }
  }

  void _openImage(String url) => ChatMediaViewer.open(context, remoteUrl: url, senderName: widget.profile.displayName);

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final scheme = Theme.of(context).colorScheme;
    final photos = <String>[
      for (final u in p.allPhotos) resolveMediaUrl(u) ?? u,
    ].where((u) => u.isNotEmpty).take(3).toList();
    final avatar = photos.isNotEmpty ? photos.first : '';
    final more = photos.length > 1 ? photos.sublist(1) : const <String>[];
    final details = buildPublicProfile(p);

    final distance = p.previewDistanceKm;
    final where = distance != null
        ? (distance < 1 ? 'Less than 1 km away' : '${distance.round()} km away')
        : (p.location ?? '').trim();
    final matched = DateTime.tryParse(widget.matchedAt ?? '');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final matchedLabel = matched == null
        ? null
        : 'Matched ${months[matched.toLocal().month - 1]} ${matched.toLocal().day}, ${matched.toLocal().year}';

    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      if (widget.onVoiceCall != null) (icon: Icons.call_outlined, label: 'Audio', onTap: widget.onVoiceCall!),
      if (widget.onVideoCall != null) (icon: Icons.videocam_outlined, label: 'Video', onTap: widget.onVideoCall!),
      if (widget.onOpenInsights != null) (icon: Icons.insights, label: 'Insights', onTap: widget.onOpenInsights!),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Identity
          Center(
            child: GestureDetector(
              onTap: avatar.isEmpty ? null : () => _openImage(avatar),
              child: Container(
                width: 128,
                height: 128,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceContainerHigh,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.15), width: 4),
                ),
                child: avatar.isEmpty
                    ? Icon(Icons.person, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.4))
                    : CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.person, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              if (p.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 22, color: Color(0xFF0EA5E9)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [if (p.age != null && '${p.age}'.isNotEmpty) '${p.age} years', if (where.isNotEmpty) where].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          if (matchedLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(matchedLabel, style: TextStyle(fontSize: 12, color: scheme.primary)),
              ],
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                for (final a in actions)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: a.onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Icon(a.icon, color: scheme.primary, size: 22),
                                const SizedBox(height: 6),
                                Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (details.bio.isNotEmpty)
            _Section(title: 'About', child: Text(details.bio, style: const TextStyle(fontSize: 14, height: 1.5))),
          if (more.isNotEmpty)
            _Section(
              title: 'Photos',
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 4 / 5,
                children: [
                  for (final url in more)
                    GestureDetector(
                      onTap: () => _openImage(url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(color: scheme.surfaceContainerHighest),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (widget.conversationId != null)
            _SharedMedia(conversationId: widget.conversationId!, onOpenImage: _openImage),
          if (details.lookingFor.isNotEmpty)
            _Section(title: 'Looking for', child: Text(details.lookingFor, style: const TextStyle(fontSize: 14, height: 1.5))),
          if (details.interests.isNotEmpty)
            _Section(
              title: 'Interests',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in details.interests)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          for (final section in details.sections)
            _Section(
              title: section.title,
              child: Column(
                children: [
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(row.icon, size: 18, color: scheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.value,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Text(row.label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (details.futureGoals.isNotEmpty)
            _Section(title: 'Future goals', child: Text(details.futureGoals, style: const TextStyle(fontSize: 14, height: 1.5))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Images exchanged in this chat, with counts (web `SharedMedia`).
class _SharedMedia extends ConsumerStatefulWidget {
  const _SharedMedia({required this.conversationId, required this.onOpenImage});
  final String conversationId;
  final ValueChanged<String> onOpenImage;

  @override
  ConsumerState<_SharedMedia> createState() => _SharedMediaState();
}

class _SharedMediaState extends ConsumerState<_SharedMedia> {
  ConversationMedia? _data;
  bool _failed = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    ref.read(chatRepositoryProvider).getConversationMedia(widget.conversationId).then((d) {
      if (mounted) setState(() => _data = d);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final data = _data;
    final items = data?.results ?? const <ConversationMediaItem>[];
    final shown = _expanded ? items : items.take(6).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('SHARED MEDIA',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.onSurfaceVariant)),
              ),
              if (data != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${data.count}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (data == null)
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      height: 90,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            )
          else if (data.count == 0)
            Row(
              children: [
                Icon(Icons.image_outlined, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('No photos shared in this chat yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            )
          else ...[
            Text('${data.fromMe} sent by you · ${data.fromThem} received',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final m in shown)
                  GestureDetector(
                    onTap: () => widget.onOpenImage(resolveMediaUrl(m.imageUrl) ?? m.imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: resolveMediaUrl(m.imageUrl) ?? m.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => ColoredBox(color: scheme.surfaceContainerHighest),
                          ),
                          if (m.isMine)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text('You',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (items.length > 6)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Show less' : 'Show all ${items.length}'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
