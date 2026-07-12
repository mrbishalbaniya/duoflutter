import 'package:flutter/material.dart';

import '../../../../register/registration_constants.dart';
import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditPreferencesSection extends StatelessWidget {
  const ProfileEditPreferencesSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ProfileEditDropdownField(
          label: 'Show me',
          value: form.prefGender,
          options: profilePrefGenderOptions,
          onChanged: (v) {
            form.prefGender = v ?? 'everyone';
            onChanged();
          },
        ),
        Text(
          'Age ${form.prefAgeMin} – ${form.prefAgeMax}',
          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
        RangeSlider(
          values: RangeValues(form.prefAgeMin.toDouble(), form.prefAgeMax.toDouble()),
          min: 18,
          max: 60,
          divisions: 42,
          labels: RangeLabels('${form.prefAgeMin}', '${form.prefAgeMax}'),
          onChanged: (v) {
            form.prefAgeMin = v.start.round();
            form.prefAgeMax = v.end.round();
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Min height',
          value: form.prefMinHeight,
          onChanged: (v) {
            form.prefMinHeight = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Preferred occupation',
          value: form.prefOccupation,
          onChanged: (v) {
            form.prefOccupation = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Preferred location',
          value: form.prefLocation,
          onChanged: (v) {
            form.prefLocation = v;
            onChanged();
          },
        ),
        Text('Max distance: ${form.prefMaxDistanceKm} km'),
        Slider(
          value: form.prefMaxDistanceKm.toDouble(),
          min: 5,
          max: 500,
          divisions: 99,
          label: '${form.prefMaxDistanceKm} km',
          onChanged: (v) {
            form.prefMaxDistanceKm = v.round();
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Relationship preference',
          value: form.prefRelationshipGoal,
          options: profileRelationshipGoalOptions,
          onChanged: (v) {
            form.prefRelationshipGoal = v ?? 'everyone';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Preferred religion',
          value: form.preferredReligion,
          options: enumDropdownOptions(religionOptions),
          onChanged: (v) {
            form.preferredReligion = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Inter-caste',
          value: form.interCaste,
          options: enumDropdownOptions(marriagePrefOptions),
          onChanged: (v) {
            form.interCaste = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Inter-religion',
          value: form.interReligion,
          options: enumDropdownOptions(marriagePrefOptions),
          onChanged: (v) {
            form.interReligion = v ?? '';
            onChanged();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Verified profiles only'),
          value: form.prefVerifiedOnly,
          onChanged: (v) {
            form.prefVerifiedOnly = v;
            onChanged();
          },
        ),
      ],
    );
  }
}
