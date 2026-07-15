import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/permission_models.dart';

/// Frontend-style glass row: permission icon + copy + enable/disable switch.
class PermissionToggleTile extends StatelessWidget {
  const PermissionToggleTile({
    super.key,
    required this.definition,
    required this.status,
    required this.enabled,
    required this.isBusy,
    required this.onChanged,
  });

  final DuoPermissionDefinition definition;
  final DuoPermissionStatus status;
  final bool enabled;
  final bool isBusy;
  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isBusy
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged(!enabled);
              },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: definition.accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(definition.icon, color: definition.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              definition.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (definition.optional)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: scheme.surfaceContainerHigh,
                              ),
                              child: Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        definition.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: status.statusColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                if (isBusy)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  )
                else
                  Switch.adaptive(
                    value: enabled,
                    activeTrackColor: definition.accent.withValues(alpha: 0.55),
                    activeThumbColor: definition.accent,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      onChanged(value);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
