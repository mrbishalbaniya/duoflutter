import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme_extensions.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duo = context.duo;
    final iconColor = destructive ? scheme.error : scheme.primary;
    final iconBg = destructive
        ? scheme.error.withValues(alpha: 0.12)
        : scheme.primary.withValues(alpha: 0.1);
    final titleColor = destructive ? scheme.error : scheme.onSurface;

    return Semantics(
      button: onTap != null,
      enabled: enabled && onTap != null,
      label: semanticLabel ?? _buildSemanticLabel(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !enabled || onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: enabled ? iconColor : duo.disabledForeground, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: enabled ? titleColor : duo.disabledForeground,
                            ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled ? scheme.onSurfaceVariant : duo.disabledForeground,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    if (description == null || description!.isEmpty) return title;
    return '$title. $description';
  }
}

class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
