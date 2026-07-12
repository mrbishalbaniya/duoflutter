import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/chat_emoji_constants.dart';
import '../services/chat_debug_log.dart';

typedef EmojiPickCallback = void Function(String emoji);

/// Material 3 emoji picker — default grid matches Next.js `EMOJI_LIST`.
class ChatEmojiPicker extends StatefulWidget {
  const ChatEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.recentEmojis = const [],
    this.height = 280,
  });

  final EmojiPickCallback onEmojiSelected;
  final List<String> recentEmojis;
  final double height;

  @override
  State<ChatEmojiPicker> createState() => _ChatEmojiPickerState();
}

class _ChatEmojiPickerState extends State<ChatEmojiPicker> {
  final _searchController = TextEditingController();
  String _query = '';
  int _categoryIndex = 0;

  late final List<_EmojiCategory> _categories;

  @override
  void initState() {
    super.initState();
    _rebuildCategories();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  void _rebuildCategories() {
    final recent = widget.recentEmojis.where((e) => e.isNotEmpty).toList();
    _categories = [
      _EmojiCategory(
        label: 'Default',
        icon: Icons.sentiment_satisfied_alt_outlined,
        emojis: ChatEmojiConstants.composerPicker,
      ),
      if (recent.isNotEmpty)
        _EmojiCategory(
          label: 'Recent',
          icon: Icons.history_rounded,
          emojis: recent,
        ),
      ...ChatEmojiConstants.categories.entries.map(
        (e) => _EmojiCategory(
          label: e.key,
          icon: _iconForCategory(e.key),
          emojis: e.value,
        ),
      ),
    ];
    if (_categoryIndex >= _categories.length) {
      _categoryIndex = 0;
    }
  }

  @override
  void didUpdateWidget(covariant ChatEmojiPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentEmojis != widget.recentEmojis) {
      _rebuildCategories();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleEmojis {
    if (_query.isEmpty) {
      return _categories[_categoryIndex].emojis;
    }
    return ChatEmojiConstants.allEmojis
        .where((e) => e.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emojis = _visibleEmojis;

    return Material(
      elevation: 0,
      color: scheme.surface,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search emoji',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            if (_query.isEmpty)
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = index == _categoryIndex;
                    return FilterChip(
                      label: Text(cat.label),
                      avatar: Icon(cat.icon, size: 16),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryIndex = index),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
            Expanded(
              child: emojis.isEmpty
                  ? Center(
                      child: Text(
                        'No emojis found',
                        style: themeOf(context, scheme),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _query.isEmpty && _categoryIndex == 0 ? 4 : 8,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 1,
                      ),
                      itemCount: emojis.length,
                      itemBuilder: (context, index) {
                        final emoji = emojis[index];
                        return _EmojiCell(
                          emoji: emoji,
                          onTap: () => _pick(emoji),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? themeOf(BuildContext context, ColorScheme scheme) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        );
  }

  void _pick(String emoji) {
    HapticFeedback.selectionClick();
    ChatDebugLog.emojiSelected(emoji: emoji);
    widget.onEmojiSelected(emoji);
  }

  IconData _iconForCategory(String name) {
    switch (name) {
      case 'Smileys':
        return Icons.emoji_emotions_outlined;
      case 'Gestures':
        return Icons.back_hand_outlined;
      case 'Hearts':
        return Icons.favorite_border_rounded;
      case 'Celebration':
        return Icons.celebration_outlined;
      default:
        return Icons.emoji_symbols_outlined;
    }
  }
}

class _EmojiCategory {
  const _EmojiCategory({
    required this.label,
    required this.icon,
    required this.emojis,
  });

  final String label;
  final IconData icon;
  final List<String> emojis;
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
