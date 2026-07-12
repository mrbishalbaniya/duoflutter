import 'dart:convert';
import 'dart:io';

import '../../../core/models/user_models.dart';
import '../../../repositories/photo_repository.dart';
import '../../register/registration_constants.dart';
import 'profile_domain.dart';

/// Web profile edit stores religion display labels (e.g. "Hindu"), not enum slugs.
String normalizeReligionLabel(String? religion) {
  if (religion == null || religion.trim().isEmpty) return '';
  final trimmed = religion.trim();
  for (final option in religionOptions) {
    if (option.value == trimmed.toLowerCase() || option.label.toLowerCase() == trimmed.toLowerCase()) {
      return option.label;
    }
  }
  return trimmed;
}

String normalizeEnumValue(String? raw, List<DuoOption<String>> options) {
  if (raw == null || raw.trim().isEmpty) return '';
  final trimmed = raw.trim();
  for (final option in options) {
    if (option.value == trimmed || option.label.toLowerCase() == trimmed.toLowerCase()) {
      return option.value;
    }
  }
  return trimmed;
}

/// Resolves a stored value to a valid dropdown item value, or null to avoid Flutter assertions.
String? resolveDropdownValue(String value, List<(String value, String label)> options) {
  if (value.isEmpty) return null;
  for (final option in options) {
    if (option.$1 == value || option.$2 == value) return option.$1;
  }
  return null;
}

String normalizeStaticDropdown(String? raw, List<(String, String)> options) {
  if (raw == null || raw.trim().isEmpty) return '';
  final trimmed = raw.trim();
  for (final option in options) {
    if (option.$1 == trimmed || option.$2.toLowerCase() == trimmed.toLowerCase()) {
      return option.$1;
    }
  }
  return trimmed;
}

List<(String, String)> religionDropdownOptions() {
  return religionOptions.map((e) => (e.label, e.label)).toList();
}

List<(String, String)> enumDropdownOptions(List<DuoOption<String>> options) {
  return options.map((e) => (e.value, e.label)).toList();
}

class ProfileEditPhoto {
  const ProfileEditPhoto({
    required this.id,
    required this.url,
    required this.fileName,
    this.isProfile = false,
    this.localFile,
  });

  final String id;
  final String url;
  final String fileName;
  final bool isProfile;
  final File? localFile;

  ProfileEditPhoto copyWith({
    String? id,
    String? url,
    String? fileName,
    bool? isProfile,
    File? localFile,
  }) {
    return ProfileEditPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      isProfile: isProfile ?? this.isProfile,
      localFile: localFile ?? this.localFile,
    );
  }
}

class ProfileEditFormData {
  ProfileEditFormData({
    this.fullName = '',
    this.age = '',
    this.phoneCountryCode = '+977',
    this.phoneNumber = '',
    this.gender = '',
    this.location = '',
    this.bio = '',
    this.religion = '',
    this.education = '',
    this.occupation = '',
    this.workPreference = '',
    this.relationshipGoal = '',
    this.lifestyleTagsText = '',
    this.height = '',
    this.company = '',
    this.monthlyIncome = '',
    this.educationLevel = '',
    this.fieldOfStudy = '',
    this.caste = '',
    this.gotra = '',
    this.horoscope = '',
    this.birthTime = '',
    this.birthPlace = '',
    this.lookingForText = '',
    this.futureGoals = '',
    this.prefGender = 'everyone',
    this.prefAgeMin = 22,
    this.prefAgeMax = 35,
    this.prefMinHeight = '',
    this.prefOccupation = '',
    this.prefLocation = '',
    this.prefMaxDistanceKm = 50,
    this.prefRelationshipGoal = 'everyone',
    this.prefVerifiedOnly = false,
    this.preferredReligion = '',
    this.interCaste = '',
    this.interReligion = '',
    List<ProfileEditPhoto>? photos,
  }) : photos = photos ?? [];

  String fullName;
  String age;
  String phoneCountryCode;
  String phoneNumber;
  String gender;
  String location;
  String bio;
  String religion;
  String education;
  String occupation;
  String workPreference;
  String relationshipGoal;
  String lifestyleTagsText;
  String height;
  String company;
  String monthlyIncome;
  String educationLevel;
  String fieldOfStudy;
  String caste;
  String gotra;
  String horoscope;
  String birthTime;
  String birthPlace;
  String lookingForText;
  String futureGoals;
  String prefGender;
  int prefAgeMin;
  int prefAgeMax;
  String prefMinHeight;
  String prefOccupation;
  String prefLocation;
  int prefMaxDistanceKm;
  String prefRelationshipGoal;
  bool prefVerifiedOnly;
  String preferredReligion;
  String interCaste;
  String interReligion;
  List<ProfileEditPhoto> photos;

  ProfileEditFormData copyWith({
    String? fullName,
    String? age,
    String? phoneCountryCode,
    String? phoneNumber,
    String? gender,
    String? location,
    String? bio,
    String? religion,
    String? education,
    String? occupation,
    String? workPreference,
    String? relationshipGoal,
    String? lifestyleTagsText,
    String? height,
    String? company,
    String? monthlyIncome,
    String? educationLevel,
    String? fieldOfStudy,
    String? caste,
    String? gotra,
    String? horoscope,
    String? birthTime,
    String? birthPlace,
    String? lookingForText,
    String? futureGoals,
    String? prefGender,
    int? prefAgeMin,
    int? prefAgeMax,
    String? prefMinHeight,
    String? prefOccupation,
    String? prefLocation,
    int? prefMaxDistanceKm,
    String? prefRelationshipGoal,
    bool? prefVerifiedOnly,
    String? preferredReligion,
    String? interCaste,
    String? interReligion,
    List<ProfileEditPhoto>? photos,
  }) {
    return ProfileEditFormData(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      workPreference: workPreference ?? this.workPreference,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      lifestyleTagsText: lifestyleTagsText ?? this.lifestyleTagsText,
      height: height ?? this.height,
      company: company ?? this.company,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      educationLevel: educationLevel ?? this.educationLevel,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      caste: caste ?? this.caste,
      gotra: gotra ?? this.gotra,
      horoscope: horoscope ?? this.horoscope,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      lookingForText: lookingForText ?? this.lookingForText,
      futureGoals: futureGoals ?? this.futureGoals,
      prefGender: prefGender ?? this.prefGender,
      prefAgeMin: prefAgeMin ?? this.prefAgeMin,
      prefAgeMax: prefAgeMax ?? this.prefAgeMax,
      prefMinHeight: prefMinHeight ?? this.prefMinHeight,
      prefOccupation: prefOccupation ?? this.prefOccupation,
      prefLocation: prefLocation ?? this.prefLocation,
      prefMaxDistanceKm: prefMaxDistanceKm ?? this.prefMaxDistanceKm,
      prefRelationshipGoal: prefRelationshipGoal ?? this.prefRelationshipGoal,
      prefVerifiedOnly: prefVerifiedOnly ?? this.prefVerifiedOnly,
      preferredReligion: preferredReligion ?? this.preferredReligion,
      interCaste: interCaste ?? this.interCaste,
      interReligion: interReligion ?? this.interReligion,
      photos: photos ?? this.photos,
    );
  }
}

ProfileEditFormData profileToEditForm(DuoProfile profile) {
  final extra = parsePrefValues(profile.prefValues);
  final photos = <ProfileEditPhoto>[];
  for (var i = 0; i < profile.allPhotos.length; i++) {
    final url = profile.allPhotos[i];
    photos.add(
      ProfileEditPhoto(
        id: 'photo-$i',
        url: url,
        fileName: 'photo-${i + 1}.jpg',
        isProfile: url == profile.photoUrl || (i == 0 && (profile.photoUrl ?? '').isEmpty),
      ),
    );
  }

  return ProfileEditFormData(
    fullName: profile.fullName,
    age: profile.age != null ? '${profile.age}' : '',
    phoneCountryCode: profile.phoneCountryCode ?? '+977',
    phoneNumber: profile.phoneNumber ?? '',
    gender: genderApiToForm(profile.gender),
    location: profile.location ?? '',
    bio: profile.bio ?? '',
    religion: normalizeReligionLabel(profile.religion),
    education: profile.education ?? '',
    occupation: profile.occupation ?? '',
    workPreference: normalizeStaticDropdown(profile.workPreference, profileWorkPreferenceOptions),
    relationshipGoal: normalizeStaticDropdown(profile.relationshipGoal, profileRelationshipGoalOptions),
    lifestyleTagsText: profile.lifestyleTags.join(', '),
    height: extra.height ?? '',
    company: extra.company ?? '',
    monthlyIncome: normalizeEnumValue(extra.monthlyIncome, incomeOptions),
    educationLevel: normalizeEnumValue(extra.educationLevel, educationLevelOptions),
    fieldOfStudy: normalizeEnumValue(extra.fieldOfStudy, fieldOfStudyOptions),
    caste: extra.caste ?? '',
    gotra: extra.gotra ?? '',
    horoscope: normalizeEnumValue(extra.horoscope, horoscopeOptions),
    birthTime: extra.birthTime ?? '',
    birthPlace: extra.birthPlace ?? '',
    lookingForText: extra.lookingForText ?? '',
    futureGoals: extra.futureGoals ?? '',
    prefGender: normalizeStaticDropdown(profile.prefGender ?? 'everyone', profilePrefGenderOptions),
    prefAgeMin: profile.prefAgeMin ?? 22,
    prefAgeMax: profile.prefAgeMax ?? 35,
    prefMinHeight: profile.prefMinHeight ?? '',
    prefOccupation: profile.prefOccupation ?? '',
    prefLocation: profile.prefLocation ?? '',
    prefMaxDistanceKm: profile.prefMaxDistanceKm ?? 50,
    prefRelationshipGoal: normalizeStaticDropdown(
      profile.prefRelationshipGoal ?? 'everyone',
      profileRelationshipGoalOptions,
    ),
    prefVerifiedOnly: profile.prefVerifiedOnly,
    preferredReligion: normalizeEnumValue(extra.preferredReligion, religionOptions),
    interCaste: normalizeEnumValue(extra.interCaste, marriagePrefOptions),
    interReligion: normalizeEnumValue(extra.interReligion, marriagePrefOptions),
    photos: photos,
  );
}

String _buildPrefValuesJson(ProfileEditFormData form, ParsedPrefValues existing) {
  return jsonEncode({
    ...existing.toJson(),
    'height': form.height.trim(),
    'company': form.company.trim(),
    'monthlyIncome': form.monthlyIncome.trim(),
    'educationLevel': form.educationLevel.trim(),
    'fieldOfStudy': form.fieldOfStudy.trim(),
    'caste': form.caste.trim(),
    'gotra': form.gotra.trim(),
    'horoscope': form.horoscope.trim(),
    'birthTime': form.birthTime.trim(),
    'birthPlace': form.birthPlace.trim(),
    'lookingForText': form.lookingForText.trim(),
    'futureGoals': form.futureGoals.trim(),
    'preferredReligion': form.preferredReligion.trim(),
    'interCaste': form.interCaste.trim(),
    'interReligion': form.interReligion.trim(),
  });
}

Future<({String photoUrl, List<String> photoUrls})> resolveProfilePhotoUrls(
  List<ProfileEditPhoto> photos,
  PhotoRepository photoRepo,
) async {
  if (photos.isEmpty) return (photoUrl: '', photoUrls: <String>[]);

  final profilePhoto = photos.cast<ProfileEditPhoto?>().firstWhere(
        (p) => p!.isProfile,
        orElse: () => photos.first,
      )!;

  var photoUrl = '';
  final photoUrls = <String>[];

  for (final photo in photos) {
    var url = photo.url;
    if (photo.localFile != null) {
      final isPrimary = photo.id == profilePhoto.id;
      final result = await photoRepo.uploadAndAnalyzePhoto(
        photo.localFile!,
        isPrimary: isPrimary,
      );
      final error = getPhotoUploadError(result, fileName: photo.fileName);
      if (error != null) throw Exception(error);
      url = result.imageUrl!;
    }
    if (photo.id == profilePhoto.id) {
      photoUrl = url;
    } else if (url.isNotEmpty) {
      photoUrls.add(url);
    }
  }

  return (photoUrl: photoUrl, photoUrls: photoUrls);
}

Future<Map<String, dynamic>> buildProfileUpdatePayload({
  required ProfileEditFormData form,
  required DuoProfile existing,
  required PhotoRepository photoRepo,
}) async {
  final existingExtra = parsePrefValues(existing.prefValues);
  final photos = await resolveProfilePhotoUrls(form.photos, photoRepo);
  final parsedAge = int.tryParse(form.age.trim());

  return {
    'full_name': form.fullName.trim(),
    'age': parsedAge,
    'phone_country_code': form.phoneCountryCode.trim(),
    'phone_number': form.phoneNumber.trim(),
    'gender': form.gender,
    'location': form.location.trim(),
    'bio': form.bio.trim(),
    'religion': form.religion,
    'education': form.education.trim(),
    'occupation': form.occupation.trim(),
    'work_preference': form.workPreference,
    'relationship_goal': form.relationshipGoal,
    'lifestyle_tags': form.lifestyleTagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(),
    'pref_gender': form.prefGender,
    'pref_age_min': form.prefAgeMin,
    'pref_age_max': form.prefAgeMax,
    'pref_min_height': form.prefMinHeight.trim(),
    'pref_occupation': form.prefOccupation.trim(),
    'pref_location': form.prefLocation.trim(),
    'pref_max_distance_km': form.prefMaxDistanceKm,
    'pref_relationship_goal': form.prefRelationshipGoal,
    'pref_verified_only': form.prefVerifiedOnly,
    'pref_values': _buildPrefValuesJson(form, existingExtra),
    'photo_url': photos.photoUrl,
    'photo_urls': photos.photoUrls,
    'is_onboarded': true,
  };
}

String genderApiToForm(String? gender) {
  return switch (gender) {
    'M' => 'M',
    'F' => 'F',
    'O' => 'O',
    _ => gender ?? '',
  };
}

const profileGenderOptions = [
  ('M', 'Male'),
  ('F', 'Female'),
  ('O', 'Other'),
];

const profileWorkPreferenceOptions = [
  ('Private', 'Private sector'),
  ('Government', 'Government'),
  ('Business', 'Business / self-employed'),
  ('NotWorking', 'Not working'),
];

const profileRelationshipGoalOptions = [
  ('dating', 'Dating'),
  ('serious', 'Serious relationship'),
  ('casual', 'Casual'),
  ('everyone', 'Open to all'),
];

const profilePrefGenderOptions = [
  ('women', 'Women'),
  ('men', 'Men'),
  ('everyone', 'Everyone'),
];
