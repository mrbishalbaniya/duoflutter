import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/duo_gradients.dart';
import '../../../../widgets/duo_ui.dart';
import '../../models/permission_models.dart';
import 'permission_progress_header.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.definition,
    required this.status,
    required this.showSuccess,
    required this.isRequesting,
    required this.onAllow,
    required this.onSkip,
  });

  final DuoPermissionDefinition definition;
  final DuoPermissionStatus? status;
  final bool showSuccess;
  final bool isRequesting;
  final VoidCallback onAllow;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width > 700 ? 520.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DuoGlassCard(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          borderRadius: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showSuccess
                    ? _SuccessState(key: const ValueKey('success'), accent: definition.accent)
                    : _PermissionBody(
                        key: ValueKey(definition.type),
                        definition: definition,
                        status: status,
                      ),
              ),
              const SizedBox(height: 24),
              if (!showSuccess) ...[
                FilledButton(
                  onPressed: isRequesting ? null : onAllow,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isRequesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
                          definition.allowLabel ??
                              (definition.optional
                                  ? 'Allow access'
                                  : 'Allow ${definition.title.toLowerCase()}'),
                        ),
                ),
                if (definition.optional && onSkip != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: isRequesting ? null : onSkip,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Skip for now'),
                  ),
                ],
              ] else
                FilledButton(
                  onPressed: onAllow,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Continue'),
                ),
              if (status != null && !showSuccess) ...[
                const SizedBox(height: 12),
                Text(
                  'Current status: ${status!.label}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status!.statusColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Duo only uses permissions for the features you enable.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionBody extends StatelessWidget {
  const _PermissionBody({
    super.key,
    required this.definition,
    required this.status,
  });

  final DuoPermissionDefinition definition;
  final DuoPermissionStatus? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'permission_icon_${definition.type.name}',
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    definition.accent.withValues(alpha: 0.9),
                    definition.accent.withValues(alpha: 0.55),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: definition.accent.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(definition.icon, color: Colors.white, size: 42),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          definition.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          definition.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 18),
        PermissionBenefitChips(benefits: definition.benefits, accent: definition.accent),
      ],
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0);
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: DuoGradients.brand,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 18),
        Text(
          'All set',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change this anytime in Settings.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}
