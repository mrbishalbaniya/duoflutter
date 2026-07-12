import 'package:flutter/material.dart';

import '../../../domain/profile_edit_models.dart';
import 'profile_edit_form_fields.dart';

class ProfileEditLifestyleSection extends StatelessWidget {
  const ProfileEditLifestyleSection({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Separate tags with commas (e.g. fitness:often, diet:vegetarian).',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ProfileEditTextField(
          label: 'Lifestyle tags',
          value: form.lifestyleTagsText,
          maxLines: 3,
          onChanged: (v) {
            form.lifestyleTagsText = v;
            onChanged();
          },
        ),
      ],
    );
  }
}
