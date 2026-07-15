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
    this.onSkip,
    this.skipLabel = 'Skip for now',
    this.skipDisabled = false,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSkip;
  final String skipLabel;
  final bool skipDisabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DuoGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (onSkip != null)
                TextButton(
                  onPressed: skipDisabled
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onSkip!();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    skipLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(label!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 8.0;
            final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
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
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                                ),
                              ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text(
                          option.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenuFormField<String>(
              initialSelection: value.isEmpty ? null : value,
              label: Text(label),
              width: constraints.maxWidth,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: options
                  .map((o) => DropdownMenuEntry<String>(value: o, label: o))
                  .toList(),
              onSelected: onChanged,
            );
          },
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenuFormField<T>(
              initialSelection: value.isEmpty ? null : value as T,
              label: Text(label),
              width: constraints.maxWidth,
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: options
                  .map((o) => DropdownMenuEntry<T>(value: o.value, label: o.label))
                  .toList(),
              onSelected: onChanged,
            );
          },
        ),
        RegistrationFieldError(message: error),
      ],
    );
  }
}

class RegistrationAgeRangeSlider extends StatelessWidget {
  const RegistrationAgeRangeSlider({
    super.key,
    required this.minAge,
    required this.maxAge,
    required this.onChanged,
    this.min = 18,
    this.max = 80,
    this.label = 'Preferred age range',
  });

  final int minAge;
  final int maxAge;
  final ValueChanged<RangeValues> onChanged;
  final int min;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lo = minAge.clamp(min, max).toDouble();
    final hi = maxAge.clamp(min, max).toDouble();
    final values = RangeValues(lo <= hi ? lo : hi, lo <= hi ? hi : lo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
                child: Text(
                  '${values.start.round()} – ${values.end.round()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.surfaceContainerHighest,
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.16),
            rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: RangeSlider(
            values: values,
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            labels: RangeLabels('${values.start.round()}', '${values.end.round()}'),
            onChanged: (next) {
              HapticFeedback.selectionClick();
              onChanged(next);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              Text('$max', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
