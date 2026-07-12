import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/map_domain.dart';
import '../providers/map_providers.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({super.key});

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() {});
    });
  }

  void _selectSuggestion(GeocodeSuggestion suggestion) {
    _controller.text = suggestion.label;
    setState(() => _query = suggestion.label);
    ref.read(mapRecentSearchesProvider.notifier).add(suggestion.label);
    ref.read(mapScreenControllerProvider.notifier).flyTo(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recent = ref.watch(mapRecentSearchesProvider);
    final debouncedQuery = _debounce?.isActive == true ? '' : _query;
    final suggestions = debouncedQuery.trim().length >= 2
        ? ref.watch(mapGeocodeSuggestionsProvider(debouncedQuery.trim()))
        : const AsyncValue<List<GeocodeSuggestion>>.data([]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onQueryChanged,
          onSubmitted: (v) {
            if (v.trim().isEmpty) return;
            ref.read(mapRecentSearchesProvider.notifier).add(v);
            ref.read(mapScreenControllerProvider.notifier).setSearchQuery(v);
          },
          decoration: InputDecoration(
            hintText: 'Search places…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: recent.isNotEmpty && _query.isEmpty
              ? Padding(
                  key: const ValueKey('recent'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in recent)
                        ActionChip(
                          label: Text(item, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            _controller.text = item;
                            _onQueryChanged(item);
                            ref.read(mapScreenControllerProvider.notifier).setSearchQuery(item);
                          },
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-recent')),
        ),
        suggestions.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (items) {
            if (items.isEmpty || _query.trim().length < 2) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: Column(
                  children: [
                    for (final item in items.take(5))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined, color: DuoColors.primary),
                        title: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => _selectSuggestion(item),
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.04, end: 0);
          },
        ),
      ],
    );
  }
}
