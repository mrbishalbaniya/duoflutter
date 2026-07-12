import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/duo_gradients.dart';
import '../../../widgets/duo_ui.dart';
import '../registration_constants.dart';
import '../registration_models.dart';

class RegistrationStepper extends StatelessWidget {
  const RegistrationStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = ((currentStep / totalRegistrationSteps) * 100).round();
    final label = registrationStepLabels[currentStep] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP $currentStep OF $totalRegistrationSteps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: scheme.surfaceContainerHighest),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    widthFactor: progress / 100,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: DuoGradients.brand),
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

class RegistrationStepCard extends StatelessWidget {
  const RegistrationStepCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DuoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class RegistrationFieldError extends StatelessWidget {
  const RegistrationFieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(
        message!,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
      ),
    );
  }
}

class RegistrationStepNavigation extends StatelessWidget {
  const RegistrationStepNavigation({
    super.key,
    this.onBack,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.loading = false,
    this.disableNext = false,
    this.showBack = true,
  });

  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final bool loading;
  final bool disableNext;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (showBack && onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : () {
                  HapticFeedback.lightImpact();
                  onBack!();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: showBack && onBack != null ? 2 : 1,
            child: DuoGradientButton(
              onPressed: loading || disableNext ? null : () {
                HapticFeedback.mediumImpact();
                onNext();
              },
              loading: loading,
              label: loading ? 'Please wait...' : nextLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationChipSelect<T extends String> extends StatelessWidget {
  const RegistrationChipSelect({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.error,
    this.columns = 2,
  });

  final String? label;
  final T? value;
  final List<DuoOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? error;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final active = value == option.value;
                return SizedBox(
                  width: width,
                  child: Material(
                    color: active ? null : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(option.value);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: active
                            ? BoxDecoration(
                                gradient: DuoGradients.brand,
                                borderRadius: BorderRadius.circular(18),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Text(
                          option.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        RegistrationFieldError(message: error),
      ],
    );
  }
}

class RegistrationMultiChipSelect extends StatelessWidget {
  const RegistrationMultiChipSelect({
    super.key,
    this.label,
    required this.values,
    required this.options,
    required this.onChanged,
    this.min = 0,
    this.error,
  });

  final String? label;
  final List<String> values;
  final List<String> options;
  final ValueChanged<List<String>> onChanged;
  final int min;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (label != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            if (min > 0)
              Text(
                '${values.length}/$min minimum',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = values.contains(option);
            return FilterChip(
              label: Text(option),
              selected: active,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                if (active) {
                  onChanged(values.where((v) => v != option).toList());
                } else {
                  onChanged([...values, option]);
                }
              },
              selectedColor: scheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: active ? Colors.white : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        RegistrationFieldError(message: error),
      ],
    );
  }
}

class RegistrationSelectField extends StatelessWidget {
  const RegistrationSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenuFormField<String>(
          initialSelection: value.isEmpty ? null : value,
          label: Text(label),
          dropdownMenuEntries: options
              .map((o) => DropdownMenuEntry<String>(value: o, label: o))
              .toList(),
          onSelected: onChanged,
        ),
        RegistrationFieldError(message: error),
      ],
    );
  }
}

class RegistrationOptionSelectField<T extends String> extends StatelessWidget {
  const RegistrationOptionSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String value;
  final List<DuoOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenuFormField<T>(
          initialSelection: value.isEmpty ? null : value as T,
          label: Text(label),
          dropdownMenuEntries: options
              .map((o) => DropdownMenuEntry<T>(value: o.value, label: o.label))
              .toList(),
          onSelected: onChanged,
        ),
        RegistrationFieldError(message: error),
      ],
    );
  }
}
