import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/models/match_models.dart';
import '../../core/theme/duo_theme.dart';

class MatchCelebrationScreen extends StatelessWidget {
  const MatchCelebrationScreen({super.key, required this.match});

  final MatchSession match;

  @override
  Widget build(BuildContext context) {
    final profile = match.otherUserProfile;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [DuoColors.primary, DuoColors.love, DuoColors.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  "It's a Match!",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 72,
                  backgroundColor: Colors.white24,
                  backgroundImage: profile.displayPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(profile.displayPhoto)
                      : null,
                  child: profile.displayPhoto.isEmpty
                      ? const Icon(Icons.person, size: 72, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                if (match.compatibilityScore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${match.compatibilityScore!.round()}% compatibility',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: DuoColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Keep swiping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
