import '../../../core/models/match_models.dart';
import '../../../core/models/user_models.dart';

enum DiscoverTab { visitors, sent, received }

enum PremiumSheetVariant { likes, visitors }

class DiscoverData {
  const DiscoverData({
    required this.visitors,
    required this.sent,
    required this.received,
  });

  final PaywalledList<VisitedProfileEntry> visitors;
  final List<LikedProfileEntry> sent;
  final PaywalledList<LikedProfileEntry> received;

  int countFor(DiscoverTab tab) => switch (tab) {
        DiscoverTab.visitors => visitors.count > 0 ? visitors.count : visitors.results.length,
        DiscoverTab.sent => sent.length,
        DiscoverTab.received => received.count > 0 ? received.count : received.results.length,
      };
}

String formatDiscoverTime(String? iso) {
  if (iso == null || iso.isEmpty) return 'Recently';
  final date = DateTime.tryParse(iso);
  if (date == null) return 'Recently';

  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.month}/${date.day}';
}

String interactionTimeLabel({
  SwipeAction? action,
  required String kind,
  String? time,
}) {
  final when = formatDiscoverTime(time);
  return switch (kind) {
    'visited' => 'Viewed your profile · $when',
    'sent' => action == SwipeAction.superlike
        ? 'Super like sent · $when'
        : 'Like sent · $when',
    'received' => action == SwipeAction.superlike
        ? 'Super like received · $when'
        : 'Like received · $when',
    _ => when,
  };
}

List<VisitedProfileEntry> filterVisitors(
  List<VisitedProfileEntry> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((e) => _profileMatches(e.profile, q)).toList();
}

List<LikedProfileEntry> filterLiked(
  List<LikedProfileEntry> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((e) => _profileMatches(e.profile, q)).toList();
}

bool _profileMatches(DuoProfile profile, String query) {
  final name = profile.displayName.toLowerCase();
  final location = (profile.location ?? '').toLowerCase();
  final bio = (profile.bio ?? '').toLowerCase();
  return name.contains(query) || location.contains(query) || bio.contains(query);
}

String profileHeroTag(DuoProfile profile) =>
    'discover-profile-${profile.userId ?? profile.id ?? profile.displayName}';
