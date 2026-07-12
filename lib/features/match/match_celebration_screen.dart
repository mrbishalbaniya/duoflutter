import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_gradients.dart';
import '../../core/theme/duo_theme.dart';
import '../auth/auth_controller.dart';

class MatchCelebrationScreen extends ConsumerWidget {
  const MatchCelebrationScreen({super.key, required this.match});

  final MatchSession match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = match.otherUserProfile;
    final me = ref.watch(authControllerProvider).user?.profile;
    final score = match.compatibilityScore;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: DuoGradients.brandBr),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    "It's a Match!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.08),
                  const SizedBox(height: 8),
                  Text(
                    'You and ${other.displayName} have expressed interest in each other.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: MediaQuery.sizeOf(context).width * 0.18,
                          child: Transform.rotate(
                            angle: -0.08,
                            child: _AvatarRing(photo: me?.displayPhoto ?? ''),
                          ),
                        ),
                        Positioned(
                          right: MediaQuery.sizeOf(context).width * 0.18,
                          child: Transform.rotate(
                            angle: 0.08,
                            child: _AvatarRing(photo: other.displayPhoto),
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: DuoGradients.brandBr,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: DuoColors.primary.withValues(alpha: 0.35),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms),
                  if (score != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${score.round()}% Compatible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: DuoColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => context.go(AppRoutes.chat),
                    child: const Text('Start Chatting'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.match),
                    child: const Text(
                      'Keep Swiping',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.photo});

  final String photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 56,
        backgroundColor: DuoColors.primary.withValues(alpha: 0.15),
        backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
        child: photo.isEmpty ? const Icon(Icons.person, size: 48, color: Colors.white54) : null,
      ),
    );
  }
}
