import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'profile_responsive.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final heroHeight = ProfileResponsive.heroHeight(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        ProfileResponsive.horizontalPadding(context),
        0,
        ProfileResponsive.horizontalPadding(context),
        100,
      ),
      children: [
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: base.withValues(alpha: 0.55),
          child: Column(
            children: [
              Container(
                height: heroHeight,
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(24)),
              ),
              const SizedBox(height: 80),
              Container(height: 72, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 12),
              Container(height: 140, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20))),
              const SizedBox(height: 12),
              ...List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
