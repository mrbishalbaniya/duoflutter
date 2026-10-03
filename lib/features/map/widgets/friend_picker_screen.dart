import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/media_url.dart';
import '../../../core/theme/duo_theme.dart';
import '../map_models.dart';

/// Full-screen picker for "My friends, except…" / "Only these friends".
/// Returns the chosen user ids, or null when closed without saving.
Future<List<int>?> showFriendPicker(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<MapProfile> friends,
  required List<int> initialSelected,
}) {
  return Navigator.of(context).push<List<int>>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FriendPickerScreen(
        title: title,
        subtitle: subtitle,
        friends: friends,
        initialSelected: initialSelected,
      ),
    ),
  );
}

class _FriendPickerScreen extends StatefulWidget {
  const _FriendPickerScreen({
    required this.title,
    required this.subtitle,
    required this.friends,
    required this.initialSelected,
  });

  final String title;
  final String subtitle;
  final List<MapProfile> friends;
  final List<int> initialSelected;

  @override
  State<_FriendPickerScreen> createState() => _FriendPickerScreenState();
}

class _FriendPickerScreenState extends State<_FriendPickerScreen> {
  late final Set<int> _selected = {...widget.initialSelected};
  String _query = '';

  List<MapProfile> get _people {
    final seen = <int>{};
    final list = [
      for (final f in widget.friends)
        if (f.profile.userId != null && seen.add(f.profile.userId!)) f,
    ]..sort((a, b) => a.profile.displayName.toLowerCase().compareTo(b.profile.displayName.toLowerCase()));
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((f) => f.profile.displayName.toLowerCase().contains(q)).toList();
  }

  void _toggle(int id) {
    HapticFeedback.selectionClick();
    setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final people = _people;
    final allIds = {for (final f in widget.friends) if (f.profile.userId != null) f.profile.userId!};
    final allSelected = allIds.isNotEmpty && allIds.every(_selected.contains);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(
              _selected.isEmpty ? 'No one selected' : '${_selected.length} selected',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _selected.toList()),
              style: FilledButton.styleFrom(backgroundColor: DuoColors.primary, shape: const StadiumBorder()),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(widget.subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search matches',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (allIds.isNotEmpty && _query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => allSelected ? _selected.clear() : _selected.addAll(allIds)),
                    child: Text(allSelected ? 'Clear all' : 'Select all'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.friends.isEmpty
                ? _EmptyState(
                    icon: Icons.people_outline_rounded,
                    text: 'No matches yet. Once you match with someone, you can choose them here.',
                  )
                : people.isEmpty
                    ? _EmptyState(icon: Icons.search_off_rounded, text: 'No matches named "$_query".')
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: people.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 80,
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (context, i) {
                          final p = people[i].profile;
                          final id = p.userId!;
                          final checked = _selected.contains(id);
                          final subtitle = [
                            if ((p.age ?? 0) > 0) '${p.age}',
                            if ((p.location ?? '').trim().isNotEmpty) p.location!.split(',').first.trim(),
                          ].join(' · ');
                          return InkWell(
                            onTap: () => _toggle(id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  _Avatar(url: resolveProfilePhotoUrl(p), name: p.displayName, selected: checked),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                        if (subtitle.isNotEmpty)
                                          Text(subtitle,
                                              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: checked,
                                    shape: const CircleBorder(),
                                    activeColor: DuoColors.primary,
                                    onChanged: (_) => _toggle(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.selected});

  final String url;
  final String name;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? DuoColors.primary : Colors.transparent, width: 2),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundImage: url.isEmpty ? null : NetworkImage(url),
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
