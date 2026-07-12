import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../widgets/duo_ui.dart';

class SecurityHeroHeader extends StatelessWidget {
  const SecurityHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.shield_outlined,
    this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;

    return DuoGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}

class SecurityStatusChip extends StatelessWidget {
  const SecurityStatusChip({super.key, required this.enabled, this.enabledLabel, this.disabledLabel});

  final bool enabled;
  final String? enabledLabel;
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = enabled ? scheme.primary : scheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        enabled ? (enabledLabel ?? 'Enabled') : (disabledLabel ?? 'Off'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class SecurityNavTile extends StatelessWidget {
  const SecurityNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
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
                            color: destructive ? scheme.error : null,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.score, required this.label});

  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color;
    if (score <= 0.4) {
      color = scheme.error;
    } else if (score <= 0.7) {
      color = scheme.tertiary;
    } else {
      color = scheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            'Strength: $label',
            key: ValueKey(label),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.location,
    required this.osVersion,
    required this.lastActive,
    required this.isCurrent,
    required this.isTrusted,
    required this.platform,
    this.onTap,
    this.actions,
  });

  final String deviceName;
  final String location;
  final String osVersion;
  final String lastActive;
  final bool isCurrent;
  final bool isTrusted;
  final String platform;
  final VoidCallback? onTap;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = platform == 'web' ? '💻' : '📱';

    return DuoGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (location.isNotEmpty)
                        Text(location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Current',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (osVersion.isNotEmpty) ...[
                  Icon(Icons.memory_rounded, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(osVersion, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.schedule_rounded, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Last active $lastActive', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            if (isTrusted) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: scheme.tertiary),
                  const SizedBox(width: 4),
                  Text('Trusted device', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.tertiary)),
                ],
              ),
            ],
            if (actions != null) ...[const SizedBox(height: 12), actions!],
          ],
        ),
      ),
    );
  }
}

class SecurityCodeField extends StatelessWidget {
  const SecurityCodeField({
    super.key,
    required this.controller,
    this.label = 'Verification code',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: '000000',
        counterText: '',
      ),
      maxLength: 8,
      onSubmitted: onSubmitted,
    );
  }
}
