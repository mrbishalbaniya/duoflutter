import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: base.withValues(alpha: 0.55),
          child: Column(
            children: [
              Container(height: 140, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20))),
              const SizedBox(height: 60),
              Container(height: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 12),
              ...List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16)),
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
