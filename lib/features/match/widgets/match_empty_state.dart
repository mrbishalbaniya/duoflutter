import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/match_domain.dart';

class MatchEmptyState extends StatelessWidget {
  const MatchEmptyState({
    super.key,
    required this.userPrefs,
    required this.onAdjustFilters,
    required this.onRefresh,
    this.refreshing = false,
  });

  final DuoProfile? userPrefs;
  final VoidCallback onAdjustFilters;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: DuoColors.primary.withValues(alpha: 0.35),
            ).animate().fadeIn(duration: 280.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 20),
            Text(
              'No profiles to discover',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              emptyDeckMessage(userPrefs),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onAdjustFilters,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 48),
                side: BorderSide(color: DuoColors.primary.withValues(alpha: 0.35)),
              ),
              child: const Text('Adjust filters'),
            ),
            const SizedBox(height: 12),
            DuoGradientButton(
              label: refreshing ? 'Refreshing…' : 'Refresh',
              onPressed: refreshing ? null : onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
