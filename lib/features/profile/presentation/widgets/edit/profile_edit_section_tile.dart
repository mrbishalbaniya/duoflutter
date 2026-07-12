import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileEditSectionTile extends StatelessWidget {
  const ProfileEditSectionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.animationIndex = 0,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          leading: Icon(icon, color: scheme.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
          children: [child],
        ),
      ),
    )
        .animate(delay: (40 * animationIndex).ms)
        .fadeIn(duration: 240.ms)
        .slideY(begin: 0.03, end: 0);
  }
}
