import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../domain/partner_pref_options.dart';
import '../../../domain/profile_edit_models.dart';
import 'profile_edit_preferences_section.dart';

/// Own-profile editor sections mirroring web `ProfileEditForm`:
/// Personal, Religion & Background, Education & Career,
/// Lifestyle & Interests and About (with Duo AI writing suggestions).

InputDecoration _inputDecoration(BuildContext context, {String? hint, Widget? suffix}) {
  final scheme = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
  );
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.secondaryContainer.withValues(alpha: 0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border,
    enabledBorder: border,
  );
}

class _TextInput extends StatefulWidget {
  const _TextInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final int? maxLength;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_TextInput old) {
    super.didUpdateWidget(old);
    // Picking an AI suggestion changes the value from outside.
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrefLabel(widget.label),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: widget.onChanged,
          decoration: _inputDecoration(context, hint: widget.hint).copyWith(counterText: ''),
        ),
      ],
    );
  }
}

/// Base for sections that edit [form] in place and report changes.
abstract class _FormSectionState<T extends StatefulWidget> extends State<T> {
  ProfileEditFormData get f;
  VoidCallback get notify;

  void patch(VoidCallback change) {
    setState(change);
    notify();
  }
}

List<Widget> _spaced(List<Widget> children) => [
      for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 16), c],
    ];

// --- Personal ----------------------------------------------------------------

int _ageFromDob(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
  return age;
}

class ProfileEditPersonalFields extends StatefulWidget {
  const ProfileEditPersonalFields({
    super.key,
    required this.form,
    required this.onChanged,
    required this.locationController,
    required this.detectingLocation,
    required this.locationError,
    required this.onDetectLocation,
  });

  final ProfileEditFormData form;
  final VoidCallback onChanged;
  final TextEditingController locationController;
  final bool detectingLocation;
  final String? locationError;
  final VoidCallback onDetectLocation;

  @override
  State<ProfileEditPersonalFields> createState() => _PersonalState();
}

class _PersonalState extends _FormSectionState<ProfileEditPersonalFields> {
  @override
  ProfileEditFormData get f => widget.form;
  @override
  VoidCallback get notify => widget.onChanged;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final current = DateTime.tryParse(f.dateOfBirth);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: latest,
      helpText: 'Date of birth',
    );
    if (picked == null) return;
    patch(() {
      f.dateOfBirth = DateFormat('yyyy-MM-dd').format(picked);
      f.age = '${_ageFromDob(picked)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dob = DateTime.tryParse(f.dateOfBirth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced([
        _TextInput(label: 'Full name', value: f.fullName, onChanged: (v) => patch(() => f.fullName = v)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PrefLabel('Date of birth'),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDob,
              child: InputDecorator(
                decoration: _inputDecoration(context, suffix: const Icon(Icons.calendar_today_outlined)),
                child: Text(
                  dob != null ? DateFormat.yMMMMd().format(dob) : 'Select your date of birth',
                  style: TextStyle(color: dob != null ? scheme.onSurface : scheme.onSurfaceVariant),
                ),
              ),
            ),
            if (f.age.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Text('Age: ${f.age}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ),
          ],
        ),
        PrefSelect(
          label: 'Gender',
          value: f.gender,
          options: [('', 'Select gender'), ...profileGenderSelectOptions],
          onChanged: (v) => patch(() => f.gender = v),
        ),
        PrefSelect(
          label: 'Relationship goal',
          value: f.relationshipGoal,
          options: [
            ('', 'Select goal'),
            ...profileRelationshipGoalSelectOptions,
            // Keep an older saved value (e.g. "everyone") selectable.
            if (f.relationshipGoal.isNotEmpty &&
                !profileRelationshipGoalSelectOptions.any((o) => o.$1 == f.relationshipGoal))
              (f.relationshipGoal, f.relationshipGoal == 'everyone' ? 'Open to all' : f.relationshipGoal),
          ],
          onChanged: (v) => patch(() => f.relationshipGoal = v),
        ),
        _HeightSlider(value: f.height, onChanged: (v) => patch(() => f.height = v)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PrefLabel('Location'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.locationController,
                    onChanged: (v) => patch(() => f.location = v),
                    decoration: _inputDecoration(
                      context,
                      hint: widget.detectingLocation ? 'Detecting location…' : 'City, Country',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton.filledTonal(
                    tooltip: 'Detect current location',
                    onPressed: widget.detectingLocation ? null : widget.onDetectLocation,
                    icon: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
            if (widget.locationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(widget.locationError!, style: TextStyle(fontSize: 12, color: scheme.error)),
              ),
          ],
        ),
      ]),
    );
  }
}

class _HeightSlider extends StatelessWidget {
  const _HeightSlider({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = parseHeightInches(value);
    final inches = (parsed ?? 65).clamp(prefHeightMinIn, prefHeightMaxIn);
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
            Text(parsed == null ? 'Not set' : formatHeight(inches),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            if (parsed != null)
              TextButton(
                onPressed: () => onChanged(''),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        Slider(
          value: inches.toDouble(),
          min: prefHeightMinIn.toDouble(),
          max: prefHeightMaxIn.toDouble(),
          divisions: prefHeightMaxIn - prefHeightMinIn,
          label: shortHeight(inches),
          onChanged: (v) => onChanged(formatHeight(v.round())),
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

// --- Religion & Background -----------------------------------------------------

class ProfileEditBackgroundFields extends StatefulWidget {
  const ProfileEditBackgroundFields({super.key, required this.form, required this.onChanged});

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  State<ProfileEditBackgroundFields> createState() => _BackgroundState();
}

class _BackgroundState extends _FormSectionState<ProfileEditBackgroundFields> {
  @override
  ProfileEditFormData get f => widget.form;
  @override
  VoidCallback get notify => widget.onChanged;

  List<String> _withSaved(List<String> list, String saved) =>
      saved.isNotEmpty && !list.contains(saved) ? [saved, ...list] : list;

  /// Religion drives caste, caste drives sub-caste and gotra (web patchBackground).
  void _patchBackground({String? religion, String? caste}) {
    final nextReligion = religion ?? f.religion;
    final next = reconcileBackground(
      religion: nextReligion,
      caste: caste ?? f.caste,
      subCaste: f.subCaste,
      gotra: f.gotra,
    );
    patch(() {
      f.religion = nextReligion;
      f.caste = next.caste;
      f.subCaste = next.subCaste;
      f.gotra = next.gotra;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final castes = casteOptionsFor(f.religion);
    final casteChoices = castes.isEmpty ? castes : _withSaved(castes, f.caste);
    final sub = subCasteFor(f.caste);
    final gotras = gotraOptionsFor(f.religion, f.caste);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced([
        // Web saves the religion label ("Hindu"), which the backend validates.
        PrefSelect(
          label: 'Religion',
          value: f.religion,
          options: [('', 'Select religion'), for (final o in prefReligionOptions) (o.$2, o.$2)],
          onChanged: (v) => _patchBackground(religion: v),
        ),
        if (casteChoices.isNotEmpty)
          PrefSelect(
            label: casteLabelFor(f.religion),
            value: f.caste,
            options: [('', 'Select'), for (final c in casteChoices) (c, c)],
            onChanged: (v) => _patchBackground(caste: v),
          ),
        if (sub != null)
          PrefSelect(
            label: sub.$1,
            value: f.subCaste,
            options: [('', 'Select'), for (final c in _withSaved(sub.$2, f.subCaste)) (c, c)],
            onChanged: (v) => patch(() => f.subCaste = v),
          ),
        if (gotras != null)
          PrefSelect(
            label: 'Gotra',
            value: f.gotra,
            options: [('', 'Select gotra'), for (final g in _withSaved(gotras, f.gotra)) (g, g)],
            onChanged: (v) => patch(() => f.gotra = v),
          ),
        if (f.religion.isEmpty)
          Text(
            'Choose a religion to see matching community, clan and gotra options.',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        PrefSelect(
          label: 'Horoscope (Rashi)',
          value: f.horoscope,
          options: [('', 'Select your rashi'), ...profileRashiOptions],
          onChanged: (v) => patch(() => f.horoscope = v),
        ),
        _BirthTimeField(value: f.birthTime, onChanged: (v) => patch(() => f.birthTime = v)),
        _TextInput(label: 'Birth place', value: f.birthPlace, onChanged: (v) => patch(() => f.birthPlace = v)),
        PrefGroupedPicker(
          label: 'Languages',
          groups: prefLanguageGroups,
          searchHint: 'Search languages',
          selected: f.languages,
          onChanged: (next) => patch(() => f.languages = next),
        ),
      ]),
    );
  }
}

class _BirthTimeField extends StatelessWidget {
  const _BirthTimeField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  TimeOfDay? get _time {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
    return m == null ? null : TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = _time;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrefLabel('Birth time'),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? const TimeOfDay(hour: 6, minute: 0),
            );
            if (picked == null) return;
            // Same "HH:MM" format as the web time input.
            onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
          },
          child: InputDecorator(
            decoration: _inputDecoration(context, suffix: const Icon(Icons.schedule_rounded)),
            child: Text(
              time != null ? time.format(context) : 'Not set',
              style: TextStyle(color: time != null ? scheme.onSurface : scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Education & Career --------------------------------------------------------

const _otherOccupation = '__other';

class ProfileEditEducationFields extends StatefulWidget {
  const ProfileEditEducationFields({super.key, required this.form, required this.onChanged});

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  State<ProfileEditEducationFields> createState() => _EducationState();
}

class _EducationState extends _FormSectionState<ProfileEditEducationFields> {
  @override
  ProfileEditFormData get f => widget.form;
  @override
  VoidCallback get notify => widget.onChanged;

  late bool _otherMode = f.occupation.trim().isNotEmpty && _listed == null;

  String? get _listed {
    final v = f.occupation.trim().toLowerCase();
    for (final o in prefOccupationOptions) {
      if (o.$2.toLowerCase() == v) return o.$2;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final workOptions = [
      ('', 'Select work preference'),
      ...prefWorkOptions,
      if (f.workPreference.isNotEmpty && !prefWorkOptions.any((o) => o.$1 == f.workPreference))
        (f.workPreference, f.workPreference),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced([
        PrefSelect(
          label: 'Education level',
          value: f.educationLevel,
          options: [('', 'Select level'), ...prefEducationLevelOptions],
          onChanged: (v) => patch(() => f.educationLevel = v),
        ),
        PrefSelect(
          label: 'Field of study',
          value: f.fieldOfStudy,
          options: [('', 'Select field'), ...prefFieldOfStudyOptions],
          onChanged: (v) => patch(() => f.fieldOfStudy = v),
        ),
        // Same groups as partner preferences, with "Other" for free text.
        PrefSelect(
          label: 'Occupation',
          value: _otherMode ? _otherOccupation : (_listed ?? ''),
          options: [
            ('', 'Select occupation'),
            for (final o in prefOccupationOptions) (o.$2, o.$2),
            (_otherOccupation, 'Other (type your own)'),
          ],
          onChanged: (v) => patch(() {
            if (v == _otherOccupation) {
              _otherMode = true;
              if (_listed != null) f.occupation = '';
            } else {
              _otherMode = false;
              f.occupation = v;
            }
          }),
        ),
        if (_otherMode)
          _TextInput(
            label: 'Your occupation',
            value: f.occupation,
            maxLength: 300,
            onChanged: (v) => patch(() => f.occupation = v),
          ),
        _TextInput(label: 'Company', value: f.company, onChanged: (v) => patch(() => f.company = v)),
        PrefSelect(
          label: 'Work preference',
          value: f.workPreference,
          options: workOptions,
          onChanged: (v) => patch(() => f.workPreference = v),
        ),
        PrefSelect(
          label: 'Monthly income',
          value: f.monthlyIncome,
          options: [('', 'Select income range'), ...prefIncomeOptions],
          onChanged: (v) => patch(() => f.monthlyIncome = v),
        ),
      ]),
    );
  }
}

// --- Lifestyle & Interests -----------------------------------------------------

class ProfileEditLifestyleFields extends StatefulWidget {
  const ProfileEditLifestyleFields({super.key, required this.form, required this.onChanged});

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  State<ProfileEditLifestyleFields> createState() => _LifestyleState();
}

class _LifestyleState extends _FormSectionState<ProfileEditLifestyleFields> {
  @override
  ProfileEditFormData get f => widget.form;
  @override
  VoidCallback get notify => widget.onChanged;

  void _set(LifestyleGroup group, List<String> next) =>
      patch(() => f.lifestyleTagsText = setLifestyleGroup(f.lifestyleTagsText, group, next));

  Widget _single(String label, LifestyleGroup group, List<PrefOption> options) {
    final current = lifestyleSelected(f.lifestyleTagsText, group);
    return PrefSelect(
      label: label,
      value: current.isEmpty ? '' : current.first,
      options: [('', 'Not set'), ...options],
      onChanged: (v) => _set(group, v.isEmpty ? [] : [v]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced([
        _single('Personality', LifestyleGroup.personality, prefPersonalityOptions),
        _single('Lifestyle', LifestyleGroup.lifestyle, prefLifestyleOptions),
        _single('Smoking', LifestyleGroup.smoking, prefFrequencyOptions),
        _single('Drinking', LifestyleGroup.drinking, prefFrequencyOptions),
        PrefChipSelect(
          label: 'Exercise',
          options: prefExerciseOptions,
          selected: lifestyleSelected(f.lifestyleTagsText, LifestyleGroup.exercise),
          onChanged: (next) => _set(LifestyleGroup.exercise, next),
        ),
        PrefGroupedPicker(
          label: 'Interests',
          groups: prefInterestGroups,
          searchHint: 'Search interests',
          selected: lifestyleSelected(f.lifestyleTagsText, LifestyleGroup.interests),
          onChanged: (next) => _set(LifestyleGroup.interests, next),
        ),
      ]),
    );
  }
}

// --- About ---------------------------------------------------------------------

class ProfileEditAboutFields extends StatefulWidget {
  const ProfileEditAboutFields({super.key, required this.form, required this.onChanged});

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  State<ProfileEditAboutFields> createState() => _AboutState();
}

class _AboutState extends _FormSectionState<ProfileEditAboutFields> {
  @override
  ProfileEditFormData get f => widget.form;
  @override
  VoidCallback get notify => widget.onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced([
        _TextInput(
          label: 'Bio',
          value: f.bio,
          maxLines: 4,
          hint: 'A few lines about you: what you do, what you love, and what makes you laugh.',
          onChanged: (v) => patch(() => f.bio = v),
        ),
        _WritingSuggestions(field: 'bio', form: f, onPick: (v) => patch(() => f.bio = v)),
        _TextInput(
          label: 'Looking for',
          value: f.lookingForText,
          maxLines: 2,
          hint: 'Who you hope to meet, e.g. someone kind, family-oriented and up for weekend treks.',
          onChanged: (v) => patch(() => f.lookingForText = v),
        ),
        _WritingSuggestions(field: 'looking_for', form: f, onPick: (v) => patch(() => f.lookingForText = v)),
        _TextInput(
          label: 'Future goals',
          value: f.futureGoals,
          maxLines: 2,
          hint: 'Where you see yourself in a few years: career, family, travel or anything else.',
          onChanged: (v) => patch(() => f.futureGoals = v),
        ),
        _WritingSuggestions(field: 'future_goals', form: f, onPick: (v) => patch(() => f.futureGoals = v)),
      ]),
    );
  }
}

/// "Write with Duo AI" under an About field (web `WritingSuggestions`).
class _WritingSuggestions extends ConsumerStatefulWidget {
  const _WritingSuggestions({required this.field, required this.form, required this.onPick});

  final String field;
  final ProfileEditFormData form;
  final ValueChanged<String> onPick;

  @override
  ConsumerState<_WritingSuggestions> createState() => _WritingSuggestionsState();
}

class _WritingSuggestionsState extends ConsumerState<_WritingSuggestions> {
  List<String>? _items;
  List<String> _basedOn = const [];
  bool _loading = false;
  int _variant = 0;
  String? _error;

  /// Only the profile facts the writer uses are sent (no phone, email, etc.).
  Map<String, dynamic> get _draft {
    final f = widget.form;
    return {
      'full_name': f.fullName,
      'age': f.age,
      'location': f.location,
      'occupation': f.occupation,
      'company': f.company,
      'education': f.education,
      'fieldOfStudy': f.fieldOfStudy,
      'work_preference': f.workPreference,
      'relationship_goal': f.relationshipGoal,
      'lifestyleTagsText': f.lifestyleTagsText,
      'languages': f.languages,
      'pref_age_min': f.prefAgeMin,
      'pref_age_max': f.prefAgeMax,
      'pref_relationship_goal': f.prefRelationshipGoal,
    };
  }

  Future<void> _load(int variant) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(dioClientProvider).post<Map<String, dynamic>>(
        '/profiles/me/writing-suggestions/',
        data: {'field': widget.field, 'draft': _draft, 'variant': variant},
      );
      final data = res.data ?? const {};
      if (!mounted) return;
      setState(() {
        _items = (data['suggestions'] as List<dynamic>? ?? []).whereType<String>().toList();
        _basedOn = (data['based_on'] as List<dynamic>? ?? []).whereType<String>().toList();
        _variant = variant;
      });
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't get suggestions right now.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = _items;
    if (items == null) {
      return Row(
        children: [
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _load(0),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: _loading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: Text(_loading ? 'Writing…' : 'Write with Duo AI'),
          ),
          if (_error != null) ...[
            const SizedBox(width: 8),
            Flexible(child: Text(_error!, style: TextStyle(fontSize: 12, color: scheme.error))),
          ],
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Duo AI suggestions',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    children: [
                      if (_basedOn.isNotEmpty)
                        TextSpan(
                          text: ' · based on your ${_basedOn.join(', ')}',
                          style: TextStyle(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hide suggestions',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () => setState(() => _items = null),
              ),
            ],
          ),
          for (final text in items)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: scheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onPick(text),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
                        const SizedBox(width: 8),
                        Text('Use',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pick one, then edit it to sound like you.',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
              TextButton.icon(
                onPressed: _loading ? null : () => _load(_variant + 1),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: const Text('More ideas', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
