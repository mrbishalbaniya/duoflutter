import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MatchSkeleton extends StatelessWidget {
  const MatchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: base.withValues(alpha: 0.55),
              child: Container(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (_) => Shimmer.fromColors(
                baseColor: base,
                highlightColor: base.withValues(alpha: 0.55),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
