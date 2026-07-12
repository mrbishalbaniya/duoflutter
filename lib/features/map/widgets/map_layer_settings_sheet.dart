import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/map_layer_catalog.dart';
import '../providers/map_providers.dart';
import 'location_privacy_section.dart';

const _settingsCategories = [
  MapLayerCategoryId.globeFx,
  MapLayerCategoryId.duo,
  MapLayerCategoryId.weather,
  MapLayerCategoryId.geographic,
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
                'Privacy · globe effects · activity · weather · geographic',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search layers…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  isDense: true,
                ),
                onChanged: notifier.setSettingsSearchQuery,
              ),
              const SizedBox(height: 20),
              const LocationPrivacySection(),
              const SizedBox(height: 20),
              if (layers.favorites.isNotEmpty) ...[
                _SectionTitle(title: 'Favorites'),
                const SizedBox(height: 8),
                for (final id in layers.favorites)
                  if (layerById(id) != null)
                    _LayerToggle(
                      layer: layerById(id)!,
                      value: isLayerEnabled(layers.enabled, id, fallback: false),
                      favorite: true,
                      onChanged: () => notifier.toggleLayer(id),
                      onFavorite: () => notifier.toggleFavorite(id),
                    ),
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
                  const SizedBox(height: 16),
                ],
              ],
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: IconButton(
        icon: Icon(favorite ? Icons.star : Icons.star_border_outlined),
        color: favorite ? DuoColors.primary : null,
        onPressed: onFavorite,
      ),
      title: Row(
        children: [
          Icon(layer.icon, size: 18, color: DuoColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(layer.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: layer.description != null ? Text(layer.description!) : null,
      value: value,
      activeThumbColor: DuoColors.primary,
      onChanged: (_) => onChanged(),
    );
  }
}
