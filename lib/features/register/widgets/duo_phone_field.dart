import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// E.164 phone field with country dial-code selector (web `DuoPhoneInput` parity).
class DuoPhoneField extends StatefulWidget {
  const DuoPhoneField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Mobile number',
    this.enabled = true,
    this.errorText,
  });

  /// Full E.164 value, e.g. `+97798XXXXXXXX`.
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final bool enabled;
  final String? errorText;

  @override
  State<DuoPhoneField> createState() => _DuoPhoneFieldState();
}

class _DuoPhoneFieldState extends State<DuoPhoneField> {
  late final TextEditingController _nationalController;
  late String _dialCode;

  static const _countries = <({String code, String name, String dial})>[
    (code: 'NP', name: 'Nepal', dial: '+977'),
    (code: 'IN', name: 'India', dial: '+91'),
    (code: 'US', name: 'United States', dial: '+1'),
    (code: 'GB', name: 'United Kingdom', dial: '+44'),
    (code: 'AU', name: 'Australia', dial: '+61'),
    (code: 'AE', name: 'UAE', dial: '+971'),
    (code: 'QA', name: 'Qatar', dial: '+974'),
    (code: 'SA', name: 'Saudi Arabia', dial: '+966'),
    (code: 'JP', name: 'Japan', dial: '+81'),
    (code: 'KR', name: 'South Korea', dial: '+82'),
  ];

  @override
  void initState() {
    super.initState();
    final parsed = _parse(widget.value);
    _dialCode = parsed.dial;
    _nationalController = TextEditingController(text: parsed.national);
  }

  @override
  void didUpdateWidget(covariant DuoPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final parsed = _parse(widget.value);
      if (parsed.dial != _dialCode || parsed.national != _nationalController.text) {
        _dialCode = parsed.dial;
        if (_nationalController.text != parsed.national) {
          _nationalController.text = parsed.national;
        }
      }
    }
  }

  @override
  void dispose() {
    _nationalController.dispose();
    super.dispose();
  }

  ({String dial, String national}) _parse(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.isEmpty) {
      return (dial: '+977', national: '');
    }
    for (final country in _countries) {
      if (cleaned.startsWith(country.dial)) {
        return (dial: country.dial, national: cleaned.substring(country.dial.length));
      }
    }
    if (cleaned.startsWith('+')) {
      final match = RegExp(r'^(\+\d{1,3})(\d*)$').firstMatch(cleaned);
      if (match != null) {
        return (dial: match.group(1)!, national: match.group(2) ?? '');
      }
    }
    return (dial: '+977', national: cleaned.replaceAll(RegExp(r'[^\d]'), ''));
  }

  void _emit() {
    final national = _nationalController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (national.isEmpty) {
      widget.onChanged('');
      return;
    }
    widget.onChanged('$_dialCode$national');
  }

  Future<void> _pickCountry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Country / region', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              ..._countries.map((c) {
                final active = c.dial == _dialCode;
                return ListTile(
                  leading: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                  title: Text(c.name),
                  trailing: Text(c.dial, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  selected: active,
                  onTap: () => Navigator.pop(context, c.dial),
                );
              }),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _dialCode = selected);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nationalController,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '98XXXXXXXX',
            errorText: widget.errorText,
            prefixIcon: InkWell(
              onTap: widget.enabled ? _pickCountry : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dialCode,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.only(left: 8),
                      color: scheme.outline.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
