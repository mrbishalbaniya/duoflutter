import 'package:flutter/material.dart';

import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditPersonalSection extends StatelessWidget {
  const ProfileEditPersonalSection({
    super.key,
    required this.form,
    required this.locationController,
    required this.detectingLocation,
    required this.locationError,
    required this.fieldErrors,
    required this.onChanged,
    required this.onDetectLocation,
  });

  final ProfileEditFormData form;
  final TextEditingController locationController;
  final bool detectingLocation;
  final String? locationError;
  final Map<String, String?> fieldErrors;
  final VoidCallback onChanged;
  final Future<void> Function() onDetectLocation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        ProfileEditTextField(
          label: 'Full name',
          value: form.fullName,
          errorText: fieldErrors['fullName'],
          onChanged: (v) {
            form.fullName = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Age',
          value: form.age,
          keyboardType: TextInputType.number,
          errorText: fieldErrors['age'],
          onChanged: (v) {
            form.age = v;
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Gender',
          value: form.gender,
          options: profileGenderOptions,
          onChanged: (v) {
            form.gender = v ?? '';
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Phone country code',
          value: form.phoneCountryCode,
          onChanged: (v) {
            form.phoneCountryCode = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Phone number',
          value: form.phoneNumber,
          keyboardType: TextInputType.phone,
          onChanged: (v) {
            form.phoneNumber = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Height',
          value: form.height,
          onChanged: (v) {
            form.height = v;
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Religion',
          value: form.religion,
          options: religionDropdownOptions(),
          onChanged: (v) {
            form.religion = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Relationship goal',
          value: form.relationshipGoal,
          options: profileRelationshipGoalOptions,
          onChanged: (v) {
            form.relationshipGoal = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Work preference',
          value: form.workPreference,
          options: profileWorkPreferenceOptions,
          onChanged: (v) {
            form.workPreference = v ?? '';
            onChanged();
          },
        ),
        TextField(
          controller: locationController,
          onChanged: (v) {
            form.location = v;
            onChanged();
          },
          decoration: InputDecoration(
            labelText: 'Location',
            suffixIcon: IconButton(
              tooltip: 'Detect location',
              icon: Icon(
                Icons.my_location_rounded,
                color: detectingLocation ? null : scheme.primary,
              ),
              onPressed: detectingLocation ? null : onDetectLocation,
            ),
          ),
        ),
        if (locationError != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                locationError!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
