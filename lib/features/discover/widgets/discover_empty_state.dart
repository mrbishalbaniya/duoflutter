import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/discover_models.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({super.key, required this.tab});

  final DiscoverTab tab;

  @override
  Widget build(BuildContext context) {
    final meta = switch (tab) {
      DiscoverTab.visitors => (
          Icons.visibility_outlined,
          'No profile visits yet',
          'Update your profile and keep swiping to get noticed.',
          'Go to Match',
        ),
      DiscoverTab.sent => (
          Icons.favorite_border,
          'No likes sent yet',
          'Discover profiles and send your first like.',
          'Discover profiles',
        ),
      DiscoverTab.received => (
          Icons.favorite,
          'No likes yet',
          'When someone likes you, they will appear here.',
          'Update profile',
        ),
    };

    return ListView(
      children: [
        const SizedBox(height: 72),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Icon(meta.$1, size: 56, color: DuoColors.primary.withValues(alpha: 0.45)),
                const SizedBox(height: 16),
                Text(
                  meta.$2,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  meta.$3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.match),
                  child: Text(meta.$4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DiscoverErrorState extends StatelessWidget {
  const DiscoverErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 72),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Unable to load',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
