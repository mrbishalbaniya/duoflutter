import 'package:flutter/material.dart';

import '../../../../register/registration_constants.dart';
import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditEducationSection extends StatelessWidget {
  const ProfileEditEducationSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ProfileEditFormData form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileEditTextField(
          label: 'Education summary',
          value: form.education,
          onChanged: (v) {
            form.education = v;
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Education level',
          value: form.educationLevel,
          options: enumDropdownOptions(educationLevelOptions),
          onChanged: (v) {
            form.educationLevel = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Field of study',
          value: form.fieldOfStudy,
          options: enumDropdownOptions(fieldOfStudyOptions),
          onChanged: (v) {
            form.fieldOfStudy = v ?? '';
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Occupation',
          value: form.occupation,
          onChanged: (v) {
            form.occupation = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Company',
          value: form.company,
          onChanged: (v) {
            form.company = v;
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Monthly income',
          value: form.monthlyIncome,
          options: enumDropdownOptions(incomeOptions),
          onChanged: (v) {
            form.monthlyIncome = v ?? '';
            onChanged();
          },
        ),
      ],
    );
  }
}
