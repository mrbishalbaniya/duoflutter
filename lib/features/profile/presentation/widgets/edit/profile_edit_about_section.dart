import 'package:flutter/material.dart';

import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditAboutSection extends StatelessWidget {
  const ProfileEditAboutSection({
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
          label: 'Bio',
          value: form.bio,
          maxLines: 4,
          onChanged: (v) {
            form.bio = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Looking for',
          value: form.lookingForText,
          maxLines: 3,
          onChanged: (v) {
            form.lookingForText = v;
            onChanged();
          },
        ),
        ProfileEditTextField(
          label: 'Future goals',
          value: form.futureGoals,
          maxLines: 3,
          onChanged: (v) {
            form.futureGoals = v;
            onChanged();
          },
        ),
      ],
    );
  }
}
