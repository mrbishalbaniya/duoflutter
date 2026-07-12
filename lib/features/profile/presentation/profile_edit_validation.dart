import '../domain/profile_edit_models.dart';

Map<String, String?> validateProfileEditForm(ProfileEditFormData form) {
  final errors = <String, String?>{};

  if (form.fullName.trim().isEmpty) {
    errors['fullName'] = 'Full name is required';
  }

  if (form.age.trim().isNotEmpty) {
    final age = int.tryParse(form.age.trim());
    if (age == null) {
      errors['age'] = 'Enter a valid age';
    } else if (age < 18 || age > 99) {
      errors['age'] = 'Age must be between 18 and 99';
    }
  }

  return errors;
}

bool profileEditFormIsValid(ProfileEditFormData form) {
  final errors = validateProfileEditForm(form);
  return errors.values.every((e) => e == null);
}
