import 'package:flutter/material.dart';

import '../../../domain/partner_pref_options.dart';
import '../../../domain/profile_edit_models.dart';

const _any = '__any';
const _same = '__same';

/// Web `PartnerPreferencesFields`, shared by Edit Profile and the Match
/// Preferences screen: Religion & Background, Education & Career, and
/// Lifestyle & Interests. Values are saved in `pref_values` exactly like web.
class ProfileEditPreferencesSection extends StatefulWidget {
  const ProfileEditPreferencesSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  State<ProfileEditPreferencesSection> createState() => _ProfileEditPreferencesSectionState();
}

class _ProfileEditPreferencesSectionState extends State<ProfileEditPreferencesSection> {
  ProfileEditFormData get f => widget.form;

  void _patch(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  // Religion: "any"/"same" are the old inter-religion answers ("yes"/"no");
  // a specific pick narrows to one religion. Caste works the same way.
  String get _ownReligionKey => toReligionKey(f.religion);

  String get _prefReligionValue =>
      f.preferredReligion.isNotEmpty ? f.preferredReligion : (f.interReligion == 'no' ? _same : _any);

  List<String> _castesFor(String religionValue) {
    if (f.preferredReligion.isNotEmpty) return casteOptionsFor(f.preferredReligion);
    if (religionValue == _same) return casteOptionsFor(f.religion);
    return casteOptionsFor('other');
  }

  void _onReligion(String value) {
    final preferredReligion = value == _any || value == _same ? '' : value;
    final interReligion =
        value == _same || (preferredReligion.isNotEmpty && preferredReligion == _ownReligionKey) ? 'no' : 'yes';
    final castes = preferredReligion.isNotEmpty
        ? casteOptionsFor(preferredReligion)
        : value == _same
            ? casteOptionsFor(f.religion)
            : casteOptionsFor('other');
    final keepCaste = castes.isNotEmpty && (f.preferredCaste.isEmpty || castes.contains(f.preferredCaste));
    _patch(() {
      f.preferredReligion = preferredReligion;
      f.interReligion = interReligion;
      if (!keepCaste) f.preferredCaste = '';
      if (castes.isEmpty) f.interCaste = '';
    });
  }

  void _onCaste(String value) {
    final preferredCaste = value == _any || value == _same ? '' : value;
    final interCaste = value == _same || (preferredCaste.isNotEmpty && preferredCaste == f.caste) ? 'no' : 'yes';
    _patch(() {
      f.preferredCaste = preferredCaste;
      f.interCaste = interCaste;
    });
  }

  @override
  Widget build(BuildContext context) {
    final religionValue = _prefReligionValue;
    final casteList = _castesFor(religionValue);
    final casteValue = f.preferredCaste.isNotEmpty ? f.preferredCaste : (f.interCaste == 'no' ? _same : _any);
    final casteChoices = [
      if (f.preferredCaste.isNotEmpty && !casteList.contains(f.preferredCaste)) f.preferredCaste,
      ...casteList,
    ];
    final casteIsCommunity =
        casteLabelFor(f.preferredReligion.isNotEmpty ? f.preferredReligion : f.religion) == 'Community';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrefSection(
          title: 'Religion & Background',
          icon: Icons.temple_hindu_outlined,
          children: [
            PrefSelect(
              label: 'Preferred religion',
              value: religionValue,
              options: [
                (_any, 'Any religion (open to inter-religion)'),
                (_same, 'Same religion as mine'),
                ...prefReligionOptions,
              ],
              onChanged: _onReligion,
            ),
            if (casteList.isNotEmpty)
              PrefSelect(
                label: casteIsCommunity ? 'Preferred community' : 'Preferred caste',
                value: casteValue,
                options: [
                  (_any, 'Any caste (open to inter-caste)'),
                  (_same, 'Same caste as mine'),
                  for (final c in casteChoices) (c, c),
                ],
                onChanged: _onCaste,
              ),
            PrefSelect(
              label: 'Preferred horoscope (Rashi)',
              value: f.preferredRashi.isEmpty ? _any : f.preferredRashi,
              options: [(_any, 'Any rashi'), ...prefRashiOptions],
              onChanged: (v) => _patch(() => f.preferredRashi = v == _any ? '' : v),
            ),
            _HeightRange(
              minValue: f.prefMinHeight,
              maxValue: f.preferredMaxHeight,
              onChanged: (min, max) => _patch(() {
                f.prefMinHeight = min;
                f.preferredMaxHeight = max;
              }),
            ),
            PrefGroupedPicker(
              label: 'Languages',
              groups: prefLanguageGroups,
              searchHint: 'Search languages',
              selected: f.preferredLanguages,
              onChanged: (next) => _patch(() => f.preferredLanguages = next),
            ),
          ],
        ),
        _PrefSection(
          title: 'Education & Career',
          icon: Icons.school_outlined,
          children: [
            PrefChipSelect(
              label: 'Education level',
              options: prefEducationLevelOptions,
              selected: f.preferredEducationLevels,
              onChanged: (next) => _patch(() => f.preferredEducationLevels = next),
            ),
            PrefChipSelect(
              label: 'Field of study',
              options: prefFieldOfStudyOptions,
              selected: f.preferredFieldsOfStudy,
              onChanged: (next) => _patch(() => f.preferredFieldsOfStudy = next),
            ),
            PrefChipSelect(
              label: 'Work',
              options: prefWorkOptions,
              selected: f.preferredWorkPreferences,
              onChanged: (next) => _patch(() => f.preferredWorkPreferences = next),
            ),
            PrefSelect(
              label: 'Monthly income',
              value: f.preferredIncomes.isEmpty ? _any : f.preferredIncomes.first,
              options: [(_any, 'Any income'), ...prefIncomeOptions],
              onChanged: (v) => _patch(() => f.preferredIncomes = v == _any ? [] : [v]),
            ),
            PrefChipSelect(
              label: 'Occupation',
              options: prefOccupationOptions,
              selected: f.preferredOccupations,
              // The chips replace the old free-text field; clear it so a hidden
              // value stops affecting matches (same as web).
              onChanged: (next) => _patch(() {
                f.preferredOccupations = next;
                f.prefOccupation = '';
              }),
            ),
          ],
        ),
        _PrefSection(
          title: 'Lifestyle & Interests',
          icon: Icons.style_outlined,
          children: [
            PrefSelect(
              label: 'Personality',
              value: f.preferredPersonalities.isEmpty ? _any : f.preferredPersonalities.first,
              options: [(_any, 'Any'), ...prefPersonalityOptions],
              onChanged: (v) => _patch(() => f.preferredPersonalities = v == _any ? [] : [v]),
            ),
            PrefSelect(
              label: 'Lifestyle',
              value: f.preferredLifestyles.isEmpty ? _any : f.preferredLifestyles.first,
              options: [(_any, 'Any'), ...prefLifestyleOptions],
              onChanged: (v) => _patch(() => f.preferredLifestyles = v == _any ? [] : [v]),
            ),
            PrefSelect(
              label: 'Smoking',
              value: f.preferredSmoking.isEmpty ? _any : f.preferredSmoking,
              options: [(_any, 'Any'), ...prefFrequencyOptions],
              onChanged: (v) => _patch(() => f.preferredSmoking = v == _any ? '' : v),
            ),
            PrefSelect(
              label: 'Drinking',
              value: f.preferredDrinking.isEmpty ? _any : f.preferredDrinking,
              options: [(_any, 'Any'), ...prefFrequencyOptions],
              onChanged: (v) => _patch(() => f.preferredDrinking = v == _any ? '' : v),
            ),
            PrefChipSelect(
              label: 'Exercise',
              options: prefExerciseOptions,
              selected: f.preferredExercise,
              onChanged: (next) => _patch(() => f.preferredExercise = next),
            ),
            PrefGroupedPicker(
              label: 'Interests',
              groups: prefInterestGroups,
              searchHint: 'Search interests',
              selected: f.preferredInterests,
              onChanged: (next) => _patch(() => f.preferredInterests = next),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrefSection extends StatelessWidget {
  const _PrefSection({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 18),
            child,
          ],
        ],
      ),
    );
  }
}

class PrefLabel extends StatelessWidget {
  const PrefLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
            ),
          ),
          if (trailing != null) Text(trailing!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class PrefSelect extends StatelessWidget {
  const PrefSelect({super.key, required this.label, required this.value, required this.options, required this.onChanged});

  final String label;
  final String value;
  final List<PrefOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = options.any((o) => o.$1 == value) ? value : options.first.$1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrefLabel(label),
        DropdownButtonFormField<String>(
          key: ValueKey('$label-$resolved'),
          initialValue: resolved,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: scheme.secondaryContainer.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          items: [
            for (final (v, l) in options)
              DropdownMenuItem(value: v, child: Text(l, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            if (v != null && v != resolved) onChanged(v);
          },
        ),
      ],
    );
  }
}

/// Tappable chips; nothing selected means "any" (web `ChipSelect`).
class PrefChipSelect extends StatelessWidget {
  const PrefChipSelect({super.key, required this.label, required this.options, required this.selected, required this.onChanged});

  final String label;
  final List<PrefOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrefLabel(label, trailing: selected.isEmpty ? 'Any' : '${selected.length} selected'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, text) in options)
              PrefChip(
                label: text,
                active: selected.contains(value),
                onTap: () => onChanged(
                  selected.contains(value) ? selected.where((v) => v != value).toList() : [...selected, value],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class PrefChip extends StatelessWidget {
  const PrefChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grouped, searchable chip picker (web `InterestPicker`).
class PrefGroupedPicker extends StatefulWidget {
  const PrefGroupedPicker({super.key, 
    required this.label,
    required this.groups,
    required this.searchHint,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<PrefGroup> groups;
  final String searchHint;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<PrefGroupedPicker> createState() => _PrefGroupedPickerState();
}

class _PrefGroupedPickerState extends State<PrefGroupedPicker> {
  String _query = '';
  bool _expanded = false;

  void _toggle(String item) {
    final selected = widget.selected;
    widget.onChanged(selected.contains(item) ? selected.where((v) => v != item).toList() : [...selected, item]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final showAll = _expanded || q.isNotEmpty;
    final groups = [
      for (final (title, items) in widget.groups)
        (title, items.where((i) => q.isEmpty || i.toLowerCase().contains(q)).toList()),
    ].where((g) => g.$2.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrefLabel(
          widget.label,
          trailing: widget.selected.isEmpty ? 'Any' : '${widget.selected.length} selected',
        ),
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.selected) PrefChip(label: '$item  ✕', active: true, onTap: () => _toggle(item)),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            filled: true,
            fillColor: scheme.secondaryContainer.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          Text('No matches', style: TextStyle(color: scheme.onSurfaceVariant))
        else
          for (final (title, items) in showAll ? groups : groups.take(1)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  PrefChip(label: item, active: widget.selected.contains(item), onTap: () => _toggle(item)),
              ],
            ),
          ],
        if (q.isEmpty && widget.groups.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'Show less' : 'Show all'),
            ),
          ),
      ],
    );
  }
}

/// Two-thumb height range; an end left at its limit means "no limit" ("").
class _HeightRange extends StatelessWidget {
  const _HeightRange({required this.minValue, required this.maxValue, required this.onChanged});

  final String minValue;
  final String maxValue;
  final void Function(String min, String max) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final min = (parseHeightInches(minValue) ?? prefHeightMinIn).clamp(prefHeightMinIn, prefHeightMaxIn);
    final max = (parseHeightInches(maxValue) ?? prefHeightMaxIn).clamp(min, prefHeightMaxIn);
    final any = min == prefHeightMinIn && max == prefHeightMaxIn;
    final summary = any
        ? 'Any height'
        : min == prefHeightMinIn
            ? 'Under ${shortHeight(max)}'
            : max == prefHeightMaxIn
                ? '${shortHeight(min)}+'
                : '${shortHeight(min)} – ${shortHeight(max)}';

    void emit(int lo, int hi) => onChanged(
          lo <= prefHeightMinIn ? '' : formatHeight(lo),
          hi >= prefHeightMaxIn ? '' : formatHeight(hi),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Height',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
              ),
            ),
            Text(summary, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (!any)
              TextButton(
                onPressed: () => onChanged('', ''),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        RangeSlider(
          values: RangeValues(min.toDouble(), max.toDouble()),
          min: prefHeightMinIn.toDouble(),
          max: prefHeightMaxIn.toDouble(),
          divisions: prefHeightMaxIn - prefHeightMinIn,
          labels: RangeLabels(shortHeight(min), shortHeight(max)),
          onChanged: (v) => emit(v.start.round(), v.end.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(shortHeight(prefHeightMinIn), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            Text(shortHeight(prefHeightMaxIn), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
