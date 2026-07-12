import 'package:flutter/material.dart';

import '../../../../register/registration_constants.dart';
import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditBackgroundSection extends StatelessWidget {
  const ProfileEditBackgroundSection({
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
        ProfileEditDropdownField(
          label: 'Caste',
          value: form.caste,
          options: casteOptions.map((e) => (e, e)).toList(),
          onChanged: (v) {
            form.caste = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Gotra',
          value: form.gotra,
          options: gotraOptions.map((e) => (e, e)).toList(),
          onChanged: (v) {
            form.gotra = v ?? '';
            onChanged();
          },
        ),
        ProfileEditDropdownField(
          label: 'Horoscope',
          value: form.horoscope,
          options: enumDropdownOptions(horoscopeOptions),
          onChanged: (v) {
            form.horoscope = v ?? '';
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Birth time',
          value: form.birthTime,
          onChanged: (v) {
            form.birthTime = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Birth place',
          value: form.birthPlace,
          onChanged: (v) {
            form.birthPlace = v;
            onChanged();
          },
        ),
      ],
    );
  }
}
