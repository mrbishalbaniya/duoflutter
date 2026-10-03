import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/map_layer_catalog.dart';
import '../providers/map_providers.dart';
import 'location_privacy_section.dart';

const _settingsCategories = [
  MapLayerCategoryId.duo,
  MapLayerCategoryId.weather,
  MapLayerCategoryId.geographic,
  MapLayerCategoryId.globeFx,
  MapLayerCategoryId.developer,
];

class MapLayerSettingsSheet extends ConsumerStatefulWidget {
  const MapLayerSettingsSheet({super.key});

  @override
  ConsumerState<MapLayerSettingsSheet> createState() => _MapLayerSettingsSheetState();
}

class _MapLayerSettingsSheetState extends ConsumerState<MapLayerSettingsSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layers = ref.watch(mapLayerStateProvider);
    final notifier = ref.read(mapLayerStateProvider.notifier);
    final query = layers.settingsSearchQuery.trim().toLowerCase();

    List<MapLayerDefinition> filteredLayers(MapLayerCategoryId categoryId) {
      final items = layersForCategory(categoryId);
      if (query.isEmpty) return items;
      return items.where((layer) {
        final haystack = '${layer.label} ${layer.description ?? ''} ${layer.keywords.join(' ')}'
            .toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Map Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'Privacy · weather · geographic · globe effects',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search settings…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  isDense: true,
                ),
                onChanged: notifier.setSettingsSearchQuery,
              ),
              const SizedBox(height: 6),
              Text(
                'Tip: long-press a setting to pin it to Favorites.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              const LocationPrivacySection(),
              const SizedBox(height: 20),
              if (layers.favorites.isNotEmpty) ...[
                _SectionTitle(title: 'Favorites'),
                const SizedBox(height: 8),
                _SettingsGroup(children: [
                  for (final id in layers.favorites)
                    if (layerById(id) != null)
                      _LayerToggle(
                        layer: layerById(id)!,
                        value: isLayerEnabled(layers.enabled, id, fallback: false),
                        favorite: true,
                        onChanged: () => notifier.toggleLayer(id),
                        onFavorite: () => notifier.toggleFavorite(id),
                      ),
                ]),
                const SizedBox(height: 20),
              ],
              for (final categoryId in _settingsCategories) ...[
                if (filteredLayers(categoryId).isNotEmpty) ...[
                  _SectionTitle(
                    title: mapLayerCategories
                        .firstWhere((c) => c.id == categoryId)
                        .label,
                  ),
                  const SizedBox(height: 8),
                  _SettingsGroup(children: [
                    for (final layer in filteredLayers(categoryId))
                      _LayerToggle(
                        layer: layer,
                        value: layer.categoryId == MapLayerCategoryId.base
                            ? layers.enabled[layer.id] == true
                            : isLayerEnabled(layers.enabled, layer.id, fallback: false),
                        favorite: layers.favorites.contains(layer.id),
                        onChanged: () => notifier.toggleLayer(layer.id),
                        onFavorite: () => notifier.toggleFavorite(layer.id),
                      ),
                  ]),
                  const SizedBox(height: 18),
                ],
              ],
              const SizedBox(height: 24),
              // Map data/imagery credit (required by the tile licences).
              Center(
                child: Text(
                  '© OpenStreetMap contributors · CARTO · Esri',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: DuoColors.primary,
          ),
    );
  }
}

/// Rounded card that groups a category's rows with thin dividers.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 64, color: scheme.outlineVariant.withValues(alpha: 0.18)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One setting: tinted icon, label (+ description), switch. Whole row toggles;
/// long-press pins it to Favorites (replaces the old star button on every row).
class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    required this.layer,
    required this.value,
    required this.onChanged,
    required this.onFavorite,
    this.favorite = false,
  });

  final MapLayerDefinition layer;
  final bool value;
  final VoidCallback onChanged;
  final VoidCallback onFavorite;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onFavorite();
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text(favorite ? 'Removed from Favorites' : 'Pinned to Favorites'),
          duration: const Duration(seconds: 1),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value ? DuoColors.primary.withValues(alpha: 0.16) : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(layer.icon, size: 20, color: value ? DuoColors.primary : scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(layer.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (favorite) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 16, color: DuoColors.primary),
                      ],
                    ],
                  ),
                  if (layer.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(layer.description!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: DuoColors.primary,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
