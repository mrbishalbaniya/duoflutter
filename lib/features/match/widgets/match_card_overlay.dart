import 'package:flutter/material.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';

class MatchCardOverlay extends StatelessWidget {
  const MatchCardOverlay({
    super.key,
    required this.profile,
    required this.isTopCard,
    this.onInfoTap,
    this.infoDisabled = false,
  });

  final DuoProfile profile;
  final bool isTopCard;
  final VoidCallback? onInfoTap;
  final bool infoDisabled;

  @override
  Widget build(BuildContext context) {
    if (!isTopCard) return const SizedBox.shrink();

    final age = profile.age;
    final ageText = age != null ? ', $age' : '';

    // Let swipe gestures pass through most of the overlay; only the info
    // control absorbs taps.
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x8C000000),
                      Color(0xE6000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${profile.displayName}$ageText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            if (profile.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: Colors.lightBlueAccent,
                                  size: 22,
                                ),
                              ),
                            if (profile.isPremium)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DuoColors.tertiary.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (profile.location != null && profile.location!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    profile.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (onInfoTap != null)
                  Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: infoDisabled ? null : onInfoTap,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
