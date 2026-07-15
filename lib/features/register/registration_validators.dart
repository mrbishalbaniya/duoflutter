import 'dart:convert';

import 'registration_models.dart';

class PasswordStrength {
  const PasswordStrength({required this.score, required this.label});

  final int score;
  final String label;
}

PasswordStrength getPasswordStrength(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength(score: score, label: 'Weak');
  if (score <= 3) return PasswordStrength(score: score, label: 'Fair');
  if (score <= 4) return PasswordStrength(score: score, label: 'Good');
  return PasswordStrength(score: score, label: 'Strong');
}

bool isValidPhoneNumber(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return false;
  final digits = normalized.replaceAll(RegExp(r'[^\d+]'), '');
  return RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(digits);
}

int calculateAgeFromDob(String dateOfBirth) {
  if (dateOfBirth.isEmpty) return 0;
  final dob = DateTime.tryParse(dateOfBirth);
  if (dob == null) return 0;
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

DateTime minBirthDate() => DateTime(DateTime.now().year - 80);

DateTime maxBirthDateForMinAge(int minAge) {
  final now = DateTime.now();
  return DateTime(now.year - minAge, now.month, now.day);
}

String? validateAccount({
  required String phone,
  required String email,
  required String password,
  required String confirmPassword,
}) {
  if (!isValidPhoneNumber(phone)) return 'Enter a valid mobile number';
  if (email.trim().isEmpty) return 'Email is required';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim())) {
    return 'Enter a valid email';
  }
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Include at least one uppercase letter';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Include at least one number';
  if (confirmPassword.isEmpty) return 'Confirm your password';
  if (password != confirmPassword) return 'Passwords do not match';
  return null;
}

String? validateGooglePhone(String phone) {
  if (!isValidPhoneNumber(phone)) return 'Enter a valid mobile number';
  return null;
}

String? validateOtp(String otp) {
  if (otp.length != 6) return 'Enter the 6-digit code';
  if (!RegExp(r'^\d{6}$').hasMatch(otp)) return 'OTP must be 6 digits';
  return null;
}

String? validateBasicInfo(RegistrationData data) {
  if (data.firstName.trim().length < 2) return 'First name is required';
  if (data.lastName.trim().length < 2) return 'Last name is required';
  if (data.gender.isEmpty) return 'Select gender';
  if (data.dateOfBirth.isEmpty) return 'Date of birth is required';
  if (calculateAgeFromDob(data.dateOfBirth) < 18) return 'You must be at least 18 years old';
  final feet = data.heightFeet is int ? data.heightFeet as int : int.tryParse('${data.heightFeet}');
  final inches = data.heightInches is int ? data.heightInches as int : int.tryParse('${data.heightInches}');
  if (feet == null || feet < 4 || feet > 7) return 'Select height (feet)';
  if (inches == null || inches < 0 || inches > 11) return 'Select height (inches)';
  if (data.maritalStatus.isEmpty) return 'Select marital status';
  if (data.relationshipGoal.isEmpty) return 'Select relationship goal';
  return null;
}

String? validateLocation(RegistrationData data) {
  if (!data.gpsEnabled) {
    return 'We need your GPS location to continue. Tap detect and allow permission.';
  }
  if (data.country.trim().isEmpty) return 'Country is required';
  if (data.province.isEmpty) return 'Select a province';
  if (data.district.trim().length < 2) return 'District is required';
  if (data.municipality.trim().length < 2) return 'Municipality or city is required';
  return null;
}

String? validateEducation(RegistrationData data) {
  if (data.educationLevel.isEmpty) return 'Select education level';
  if (data.fieldOfStudy.isEmpty) return 'Select field of study';
  if (data.employment.isEmpty) return 'Select employment status';
  if (data.occupation.trim().length < 2) return 'Occupation is required';
  if (data.monthlyIncome.isEmpty) return 'Select income range';
  return null;
}

String? validateReligion(RegistrationData data) {
  if (data.religion.isEmpty) return 'Select religion';
  if (data.caste.isEmpty) return 'Select caste';
  if (data.gotra.isEmpty) return 'Select gotra';
  if (data.horoscope.isEmpty) return 'Select horoscope preference';
  return null;
}

String? validateLifestyle(RegistrationData data) {
  if (data.personality.isEmpty) return 'Select personality';
  if (data.lifestyle.isEmpty) return 'Select lifestyle';
  if (data.smoking.isEmpty) return 'Select smoking preference';
  if (data.drinking.isEmpty) return 'Select drinking preference';
  if (data.exercise.isEmpty) return 'Select exercise preference';
  return null;
}

String? validateInterests(List<String> interests) {
  if (interests.length < 5) return 'Select at least 5 interests';
  return null;
}

String? validatePreferences(RegistrationData data) {
  if (data.lookingFor.isEmpty) return 'Select who you are looking for';
  if (data.prefAgeMin < 18 || data.prefAgeMin > 80) return 'Minimum age is 18';
  if (data.prefAgeMax < 18 || data.prefAgeMax > 80) return 'Maximum age is 80';
  if (data.prefAgeMin > data.prefAgeMax) return 'Minimum age must be less than maximum age';
  if (data.distancePreference.isEmpty) return 'Select distance preference';
  if (data.preferredReligion.isEmpty) return 'Select preferred religion';
  if (data.interCaste.isEmpty) return 'Select inter-caste preference';
  if (data.interReligion.isEmpty) return 'Select inter-religion preference';
  return null;
}

String? validateAbout(RegistrationData data) {
  if (data.bio.trim().length < 40) return 'Bio should be at least 40 characters';
  if (data.lookingForText.trim().length < 20) return 'Tell us what you are looking for';
  if (data.futureGoals.trim().length < 20) return 'Share your future goals';
  return null;
}

String? validatePhotos(List<RegistrationPhoto> photos) {
  if (photos.length < 2) return 'Upload at least 2 verified photos';
  if (photos.length > 9) return 'Maximum 9 photos allowed';
  final approved = photos.where((p) => p.status == RegistrationPhotoStatus.approved && (p.imageUrl?.isNotEmpty ?? false));
  if (approved.length < 2) return 'Each photo must pass AI verification before continuing';
  return null;
}

Map<String, String>? splitPhoneValue(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.trim();
  final match = RegExp(r'^\+(\d{1,3})(\d+)$').firstMatch(normalized.replaceAll(RegExp(r'[\s-]'), ''));
  if (match == null) return null;
  return {
    'phone_country_code': '+${match.group(1)}',
    'phone_number': match.group(2)!,
  };
}

String registrationEmail(RegistrationData data) => data.email.trim().toLowerCase();

String buildLocation(RegistrationData data) {
  if (data.currentLocation.trim().isNotEmpty) return data.currentLocation.trim();
  final parts = [data.municipality, data.district, data.province, data.country].where((p) => p.isNotEmpty);
  final joined = parts.join(', ');
  return joined.isEmpty ? 'Kathmandu, Nepal' : joined;
}

String buildEducation(RegistrationData data) {
  if (data.educationLevel.isEmpty && data.fieldOfStudy.isEmpty) return '';
  final level = data.educationLevel.replaceAll('_', ' ').toUpperCase();
  final field = data.fieldOfStudy.replaceAll('_', ' ');
  return [if (level.isNotEmpty) level, if (field.isNotEmpty) field].join(' · ');
}

List<String> buildLifestyleTags(RegistrationData data) {
  return [
    ...data.interests,
    if (data.personality.isNotEmpty) data.personality,
    if (data.lifestyle.isNotEmpty) data.lifestyle,
    if (data.smoking.isNotEmpty) 'smoking:${data.smoking}',
    if (data.drinking.isNotEmpty) 'drinking:${data.drinking}',
    if (data.exercise.isNotEmpty) 'exercise:${data.exercise}',
    if (data.maritalStatus.isNotEmpty) 'marital:${data.maritalStatus}',
  ];
}

String buildPrefValues(RegistrationData data) {
  return jsonEncode({
    'caste': data.caste,
    'gotra': data.gotra,
    'horoscope': data.horoscope,
    'birthTime': data.birthTime,
    'birthPlace': data.birthPlace,
    'height': "${data.heightFeet}'${data.heightInches}\"",
    'company': data.company,
    'monthlyIncome': data.monthlyIncome,
    'preferredReligion': data.preferredReligion,
    'interCaste': data.interCaste,
    'interReligion': data.interReligion,
    'lookingForText': data.lookingForText,
    'futureGoals': data.futureGoals,
    'fieldOfStudy': data.fieldOfStudy,
    'educationLevel': data.educationLevel,
  });
}

String buildBio(RegistrationData data) {
  final sections = <String>[
    if (data.bio.trim().isNotEmpty) data.bio.trim(),
    if (data.lookingForText.trim().isNotEmpty) 'Looking for: ${data.lookingForText.trim()}',
    if (data.futureGoals.trim().isNotEmpty) 'Future goals: ${data.futureGoals.trim()}',
  ];
  return sections.join('\n\n');
}

Map<String, dynamic> mapRegistrationToProfile(
  RegistrationData data, {
  String profilePhotoUrl = '',
  List<String> galleryUrls = const [],
}) {
  final phoneParts = splitPhoneValue(data.phone);
  return {
    'full_name': '${data.firstName.trim()} ${data.lastName.trim()}'.trim(),
    'age': calculateAgeFromDob(data.dateOfBirth),
    'gender': _mapGender(data.gender),
    if (phoneParts != null) ...phoneParts,
    'location': buildLocation(data),
    'religion': _mapReligion(data.religion),
    'education': buildEducation(data),
    'occupation': data.occupation.trim(),
    'work_preference': _mapWorkPreference(data.employment),
    'relationship_goal': _mapRelationshipGoal(data.relationshipGoal),
    'bio': buildBio(data),
    'lifestyle_tags': buildLifestyleTags(data),
    'photo_url': profilePhotoUrl,
    'photo_urls': galleryUrls,
    'pref_age_min': data.prefAgeMin,
    'pref_age_max': data.prefAgeMax,
    'pref_gender': _mapPrefGender(data.lookingFor),
    'pref_location': '',
    'pref_max_distance_km': _mapDistanceKm(data.distancePreference),
    'pref_relationship_goal': _mapPrefRelationshipGoal(data.relationshipGoal),
    'pref_values': buildPrefValues(data),
    'pref_min_height': "${data.heightFeet}'${data.heightInches}\"",
    'pref_occupation': data.occupation.trim(),
    'is_onboarded': true,
  };
}

String _mapGender(String gender) {
  if (gender == 'male') return 'M';
  if (gender == 'female') return 'F';
  return 'O';
}

String _mapReligion(String religion) {
  const map = {
    'hindu': 'Hindu',
    'buddhist': 'Buddhist',
    'muslim': 'Muslim',
    'christian': 'Christian',
    'kirat': 'Other',
    'other': 'Other',
  };
  return map[religion] ?? 'Other';
}

String _mapWorkPreference(String employment) {
  const map = {
    'student': 'Private',
    'employed': 'Private',
    'self_employed': 'Business',
    'freelancer': 'Private',
    'business_owner': 'Business',
    'unemployed': 'NotWorking',
  };
  return map[employment] ?? 'Private';
}

String _mapPrefGender(String lookingFor) {
  if (lookingFor == 'male') return 'men';
  if (lookingFor == 'female') return 'women';
  return 'everyone';
}

String _mapRelationshipGoal(String goal) {
  if (goal == 'dating') return 'dating';
  if (goal == 'friendship') return 'casual';
  return 'serious';
}

String _mapPrefRelationshipGoal(String goal) {
  if (goal == 'dating') return 'dating';
  if (goal == 'friendship') return 'casual';
  if (goal == 'serious' || goal == 'marriage') return 'serious';
  return 'everyone';
}

int _mapDistanceKm(String distance) {
  if (distance == 'anywhere') return 500;
  return int.tryParse(distance) ?? 25;
}

({String profilePhotoUrl, List<String> galleryUrls}) collectRegistrationPhotoUrls(
  List<RegistrationPhoto> photos,
) {
  final approved = photos
      .where((p) => p.status == RegistrationPhotoStatus.approved && (p.imageUrl?.isNotEmpty ?? false))
      .toList();
  if (approved.length < 2) {
    throw StateError('Upload and verify at least 2 photos on the Photos step.');
  }
  final profilePhoto = approved.firstWhere((p) => p.isProfile, orElse: () => approved.first);
  final galleryUrls = <String>[];
  for (final photo in approved) {
    if (photo.id == profilePhoto.id) continue;
    if (photo.imageUrl != null) galleryUrls.add(photo.imageUrl!);
  }
  return (profilePhotoUrl: profilePhoto.imageUrl ?? '', galleryUrls: galleryUrls);
}
