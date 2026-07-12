import 'dart:convert';

import '../../../core/models/user_models.dart';

class ProfileField {
  const ProfileField({required this.label, required this.value});

  final String label;
  final String value;
}

class ProfileSections {
  const ProfileSections({
    required this.account,
    required this.personal,
    required this.education,
    required this.background,
    required this.about,
    required this.preferences,
    required this.status,
    required this.lifestyleTags,
    required this.photos,
  });

  final List<ProfileField> account;
  final List<ProfileField> personal;
  final List<ProfileField> education;
  final List<ProfileField> background;
  final List<ProfileField> about;
  final List<ProfileField> preferences;
  final List<ProfileField> status;
  final List<String> lifestyleTags;
  final List<String> photos;
}

class ParsedPrefValues {
  const ParsedPrefValues({
    this.caste,
    this.gotra,
    this.horoscope,
    this.birthTime,
    this.birthPlace,
    this.height,
    this.company,
    this.monthlyIncome,
    this.preferredReligion,
    this.interCaste,
    this.interReligion,
    this.lookingForText,
    this.futureGoals,
    this.fieldOfStudy,
    this.educationLevel,
  });

  factory ParsedPrefValues.fromJson(Map<String, dynamic> json) {
    return ParsedPrefValues(
      caste: json['caste'] as String?,
      gotra: json['gotra'] as String?,
      horoscope: json['horoscope'] as String?,
      birthTime: json['birthTime'] as String?,
      birthPlace: json['birthPlace'] as String?,
      height: json['height'] as String?,
      company: json['company'] as String?,
      monthlyIncome: json['monthlyIncome'] as String?,
      preferredReligion: json['preferredReligion'] as String?,
      interCaste: json['interCaste'] as String?,
      interReligion: json['interReligion'] as String?,
      lookingForText: json['lookingForText'] as String?,
      futureGoals: json['futureGoals'] as String?,
      fieldOfStudy: json['fieldOfStudy'] as String?,
      educationLevel: json['educationLevel'] as String?,
    );
  }

  final String? caste;
  final String? gotra;
  final String? horoscope;
  final String? birthTime;
  final String? birthPlace;
  final String? height;
  final String? company;
  final String? monthlyIncome;
  final String? preferredReligion;
  final String? interCaste;
  final String? interReligion;
  final String? lookingForText;
  final String? futureGoals;
  final String? fieldOfStudy;
  final String? educationLevel;

  Map<String, dynamic> toJson() => {
        if (caste != null) 'caste': caste,
        if (gotra != null) 'gotra': gotra,
        if (horoscope != null) 'horoscope': horoscope,
        if (birthTime != null) 'birthTime': birthTime,
        if (birthPlace != null) 'birthPlace': birthPlace,
        if (height != null) 'height': height,
        if (company != null) 'company': company,
        if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
        if (preferredReligion != null) 'preferredReligion': preferredReligion,
        if (interCaste != null) 'interCaste': interCaste,
        if (interReligion != null) 'interReligion': interReligion,
        if (lookingForText != null) 'lookingForText': lookingForText,
        if (futureGoals != null) 'futureGoals': futureGoals,
        if (fieldOfStudy != null) 'fieldOfStudy': fieldOfStudy,
        if (educationLevel != null) 'educationLevel': educationLevel,
      };
}

ParsedPrefValues parsePrefValues(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const ParsedPrefValues();
  try {
    return ParsedPrefValues.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const ParsedPrefValues();
  }
}

String displayValue(Object? value, {String fallback = 'Not set'}) {
  if (value == null) return fallback;
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is String && value.trim().isEmpty) return fallback;
  return '$value';
}

String formatGender(String? gender) {
  return switch (gender) {
    'M' => 'Male',
    'F' => 'Female',
    'O' => 'Other',
    _ => displayValue(gender),
  };
}

String formatWorkPreference(String? value) {
  return switch (value) {
    'Private' => 'Private sector',
    'Government' => 'Government',
    'Business' => 'Business / self-employed',
    'NotWorking' => 'Not working',
    _ => displayValue(value),
  };
}

String formatPrefGender(String? value) {
  return switch (value) {
    'everyone' => 'Everyone',
    'women' => 'Women',
    'men' => 'Men',
    _ => displayValue(value),
  };
}

String formatRelationshipGoal(String? value) {
  return switch (value) {
    'serious' => 'Serious relationship',
    'casual' => 'Casual',
    'dating' => 'Dating',
    'everyone' => 'Open to all',
    _ => displayValue(value),
  };
}

String formatLifestyleTag(String tag) {
  if (tag.contains(':')) {
    final parts = tag.split(':');
    final key = parts.first;
    final val = parts.length > 1 ? parts[1] : '';
    if (key.isEmpty) return tag;
    return '${key[0].toUpperCase()}${key.substring(1)}: $val';
  }
  return tag.replaceAll('_', ' ');
}

String formatPhone(DuoProfile profile) {
  final code = profile.phoneCountryCode?.trim();
  final number = profile.phoneNumber?.trim();
  if (code != null && code.isNotEmpty && number != null && number.isNotEmpty) {
    return '$code $number';
  }
  return displayValue(number ?? code);
}

ProfileSections buildProfileSections(DuoUser user, DuoProfile profile) {
  final extra = parsePrefValues(profile.prefValues);

  return ProfileSections(
    account: [
      ProfileField(label: 'Username', value: displayValue(user.username)),
      ProfileField(label: 'Email', value: displayValue(user.email)),
      ProfileField(label: 'Phone', value: formatPhone(profile)),
    ],
    personal: [
      ProfileField(label: 'Full name', value: displayValue(profile.fullName)),
      ProfileField(label: 'Age', value: displayValue(profile.age)),
      ProfileField(label: 'Gender', value: formatGender(profile.gender)),
      ProfileField(label: 'Location', value: displayValue(profile.location)),
      ProfileField(label: 'Height', value: displayValue(extra.height)),
      ProfileField(label: 'Religion', value: displayValue(profile.religion)),
      ProfileField(
        label: 'Relationship goal',
        value: formatRelationshipGoal(profile.relationshipGoal),
      ),
      ProfileField(
        label: 'Work preference',
        value: formatWorkPreference(profile.workPreference),
      ),
    ],
    education: [
      ProfileField(label: 'Education', value: displayValue(profile.education)),
      ProfileField(
        label: 'Education level',
        value: displayValue(extra.educationLevel?.replaceAll('_', ' ')),
      ),
      ProfileField(
        label: 'Field of study',
        value: displayValue(extra.fieldOfStudy?.replaceAll('_', ' ')),
      ),
      ProfileField(label: 'Occupation', value: displayValue(profile.occupation)),
      ProfileField(label: 'Company', value: displayValue(extra.company)),
      ProfileField(
        label: 'Monthly income',
        value: displayValue(extra.monthlyIncome?.replaceAll('_', ' ')),
      ),
    ],
    background: [
      ProfileField(label: 'Caste', value: displayValue(extra.caste)),
      ProfileField(label: 'Gotra', value: displayValue(extra.gotra)),
      ProfileField(label: 'Horoscope', value: displayValue(extra.horoscope)),
      ProfileField(label: 'Birth time', value: displayValue(extra.birthTime)),
      ProfileField(label: 'Birth place', value: displayValue(extra.birthPlace)),
    ],
    about: [
      ProfileField(label: 'Bio', value: displayValue(profile.bio, fallback: 'No bio yet')),
      ProfileField(label: 'Looking for', value: displayValue(extra.lookingForText)),
      ProfileField(label: 'Future goals', value: displayValue(extra.futureGoals)),
    ],
    preferences: [
      ProfileField(label: 'Looking for gender', value: formatPrefGender(profile.prefGender)),
      ProfileField(
        label: 'Age range',
        value: '${profile.prefAgeMin ?? '—'} – ${profile.prefAgeMax ?? '—'} years',
      ),
      ProfileField(label: 'Min height', value: displayValue(profile.prefMinHeight)),
      ProfileField(label: 'Preferred occupation', value: displayValue(profile.prefOccupation)),
      ProfileField(label: 'Preferred religion', value: displayValue(extra.preferredReligion)),
      ProfileField(label: 'Preferred location', value: displayValue(profile.prefLocation)),
      ProfileField(
        label: 'Max distance',
        value: '${profile.prefMaxDistanceKm ?? '—'} km',
      ),
      ProfileField(
        label: 'Relationship preference',
        value: formatRelationshipGoal(profile.prefRelationshipGoal),
      ),
      ProfileField(
        label: 'Verified profiles only',
        value: displayValue(profile.prefVerifiedOnly),
      ),
      ProfileField(label: 'Inter-caste', value: displayValue(extra.interCaste)),
      ProfileField(label: 'Inter-religion', value: displayValue(extra.interReligion)),
    ],
    status: [
      ProfileField(
        label: 'Profile completeness',
        value: '${profile.profileCompleteness}%',
      ),
      ProfileField(label: 'Identity verified', value: displayValue(profile.isVerified)),
      ProfileField(label: 'Onboarding complete', value: displayValue(profile.isOnboarded)),
    ],
    lifestyleTags: profile.lifestyleTags.map(formatLifestyleTag).toList(),
    photos: profile.allPhotos,
  );
}

List<({String label, bool done})> profileCompletenessChecklist(DuoProfile profile) {
  return [
    (label: 'Full name added', done: profile.fullName.trim().isNotEmpty),
    (label: 'Education details', done: (profile.education ?? '').trim().isNotEmpty),
    (label: 'Bio written', done: (profile.bio ?? '').trim().isNotEmpty),
    (label: 'Identity verified', done: profile.isVerified),
  ];
}

String profileHeroTag(DuoProfile profile) => 'my-profile-${profile.resolvedUserId ?? profile.id}';
