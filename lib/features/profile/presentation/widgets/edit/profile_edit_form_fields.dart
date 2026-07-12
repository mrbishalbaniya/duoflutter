import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileEditTextField extends StatelessWidget {
  const ProfileEditTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.errorText,
    this.suffix,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? errorText;
  final Widget? suffix;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: suffix,
        ),
        onChanged: onChanged,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: errorText == null ? null : (_) => errorText,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
      ),
    );
  }
}

class ProfileEditDropdownField extends StatelessWidget {
  const ProfileEditDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveValue(value, options);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$resolved'),
        initialValue: resolved,
        decoration: InputDecoration(labelText: label, errorText: errorText),
        items: options
            .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  String? _resolveValue(String value, List<(String, String)> options) {
    if (value.isEmpty) return null;
    for (final option in options) {
      if (option.$1 == value || option.$2 == value) return option.$1;
    }
    return null;
  }
}
