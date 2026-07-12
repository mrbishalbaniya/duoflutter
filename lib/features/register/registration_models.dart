import 'package:equatable/equatable.dart';

typedef RegistrationStep = int;

const int totalRegistrationSteps = 11;

const Map<int, String> registrationStepLabels = {
  1: 'Account',
  2: 'Basic Info',
  3: 'Location',
  4: 'Education',
  5: 'Religion',
  6: 'Lifestyle',
  7: 'Interests',
  8: 'Preferences',
  9: 'About',
  10: 'Photos',
  11: 'Review',
};

enum AccountSubStep { form, otp, phone }

enum RegistrationPhotoStatus { analyzing, approved, rejected }

class RegistrationPhoto extends Equatable {
  const RegistrationPhoto({
    required this.id,
    required this.fileName,
    this.localPath,
    this.isProfile = false,
    this.imageUrl,
    this.status,
    this.error,
  });

  final String id;
  final String fileName;
  final String? localPath;
  final bool isProfile;
  final String? imageUrl;
  final RegistrationPhotoStatus? status;
  final String? error;

  RegistrationPhoto copyWith({
    String? id,
    String? fileName,
    String? localPath,
    bool? isProfile,
    String? imageUrl,
    RegistrationPhotoStatus? status,
    String? error,
  }) {
    return RegistrationPhoto(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      isProfile: isProfile ?? this.isProfile,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'isProfile': isProfile,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (status != null) 'status': status!.name,
        if (error != null) 'error': error,
      };

  factory RegistrationPhoto.fromJson(Map<String, dynamic> json) {
    return RegistrationPhoto(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      isProfile: json['isProfile'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] != null
          ? RegistrationPhotoStatus.values.byName(json['status'] as String)
          : null,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, fileName, localPath, isProfile, imageUrl, status, error];
}

class RegistrationData extends Equatable {
  const RegistrationData({
    this.phone = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.otpVerified = false,
    this.signedUpWithGoogle = false,
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.heightFeet = '',
    this.heightInches = '',
    this.maritalStatus = '',
    this.relationshipGoal = '',
    this.country = 'Nepal',
    this.province = '',
    this.district = '',
    this.municipality = '',
    this.currentLocation = '',
    this.gpsEnabled = false,
    this.educationLevel = '',
    this.fieldOfStudy = '',
    this.employment = '',
    this.occupation = '',
    this.company = '',
    this.monthlyIncome = '',
    this.religion = '',
    this.caste = '',
    this.gotra = '',
    this.horoscope = '',
    this.birthTime = '',
    this.birthPlace = '',
    this.personality = '',
    this.lifestyle = '',
    this.smoking = '',
    this.drinking = '',
    this.exercise = '',
    this.interests = const [],
    this.lookingFor = '',
    this.prefAgeMin = 22,
    this.prefAgeMax = 35,
    this.distancePreference = '',
    this.preferredReligion = '',
    this.interCaste = '',
    this.interReligion = '',
    this.bio = '',
    this.lookingForText = '',
    this.futureGoals = '',
    this.photos = const [],
  });

  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final bool otpVerified;
  final bool signedUpWithGoogle;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final dynamic heightFeet;
  final dynamic heightInches;
  final String maritalStatus;
  final String relationshipGoal;
  final String country;
  final String province;
  final String district;
  final String municipality;
  final String currentLocation;
  final bool gpsEnabled;
  final String educationLevel;
  final String fieldOfStudy;
  final String employment;
  final String occupation;
  final String company;
  final String monthlyIncome;
  final String religion;
  final String caste;
  final String gotra;
  final String horoscope;
  final String birthTime;
  final String birthPlace;
  final String personality;
  final String lifestyle;
  final String smoking;
  final String drinking;
  final String exercise;
  final List<String> interests;
  final String lookingFor;
  final int prefAgeMin;
  final int prefAgeMax;
  final String distancePreference;
  final String preferredReligion;
  final String interCaste;
  final String interReligion;
  final String bio;
  final String lookingForText;
  final String futureGoals;
  final List<RegistrationPhoto> photos;

  RegistrationData copyWith({
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    bool? otpVerified,
    bool? signedUpWithGoogle,
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    dynamic heightFeet,
    dynamic heightInches,
    String? maritalStatus,
    String? relationshipGoal,
    String? country,
    String? province,
    String? district,
    String? municipality,
    String? currentLocation,
    bool? gpsEnabled,
    String? educationLevel,
    String? fieldOfStudy,
    String? employment,
    String? occupation,
    String? company,
    String? monthlyIncome,
    String? religion,
    String? caste,
    String? gotra,
    String? horoscope,
    String? birthTime,
    String? birthPlace,
    String? personality,
    String? lifestyle,
    String? smoking,
    String? drinking,
    String? exercise,
    List<String>? interests,
    String? lookingFor,
    int? prefAgeMin,
    int? prefAgeMax,
    String? distancePreference,
    String? preferredReligion,
    String? interCaste,
    String? interReligion,
    String? bio,
    String? lookingForText,
    String? futureGoals,
    List<RegistrationPhoto>? photos,
  }) {
    return RegistrationData(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      otpVerified: otpVerified ?? this.otpVerified,
      signedUpWithGoogle: signedUpWithGoogle ?? this.signedUpWithGoogle,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightFeet: heightFeet ?? this.heightFeet,
      heightInches: heightInches ?? this.heightInches,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      country: country ?? this.country,
      province: province ?? this.province,
      district: district ?? this.district,
      municipality: municipality ?? this.municipality,
      currentLocation: currentLocation ?? this.currentLocation,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      educationLevel: educationLevel ?? this.educationLevel,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      employment: employment ?? this.employment,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      religion: religion ?? this.religion,
      caste: caste ?? this.caste,
      gotra: gotra ?? this.gotra,
      horoscope: horoscope ?? this.horoscope,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      personality: personality ?? this.personality,
      lifestyle: lifestyle ?? this.lifestyle,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      exercise: exercise ?? this.exercise,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
      prefAgeMin: prefAgeMin ?? this.prefAgeMin,
      prefAgeMax: prefAgeMax ?? this.prefAgeMax,
      distancePreference: distancePreference ?? this.distancePreference,
      preferredReligion: preferredReligion ?? this.preferredReligion,
      interCaste: interCaste ?? this.interCaste,
      interReligion: interReligion ?? this.interReligion,
      bio: bio ?? this.bio,
      lookingForText: lookingForText ?? this.lookingForText,
      futureGoals: futureGoals ?? this.futureGoals,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toPersistedJson() {
    return {
      'phone': phone,
      'email': email,
      'otpVerified': otpVerified,
      'signedUpWithGoogle': signedUpWithGoogle,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'heightFeet': heightFeet,
      'heightInches': heightInches,
      'maritalStatus': maritalStatus,
      'relationshipGoal': relationshipGoal,
      'country': country,
      'province': province,
      'district': district,
      'municipality': municipality,
      'currentLocation': currentLocation,
      'gpsEnabled': gpsEnabled,
      'educationLevel': educationLevel,
      'fieldOfStudy': fieldOfStudy,
      'employment': employment,
      'occupation': occupation,
      'company': company,
      'monthlyIncome': monthlyIncome,
      'religion': religion,
      'caste': caste,
      'gotra': gotra,
      'horoscope': horoscope,
      'birthTime': birthTime,
      'birthPlace': birthPlace,
      'personality': personality,
      'lifestyle': lifestyle,
      'smoking': smoking,
      'drinking': drinking,
      'exercise': exercise,
      'interests': interests,
      'lookingFor': lookingFor,
      'prefAgeMin': prefAgeMin,
      'prefAgeMax': prefAgeMax,
      'distancePreference': distancePreference,
      'preferredReligion': preferredReligion,
      'interCaste': interCaste,
      'interReligion': interReligion,
      'bio': bio,
      'lookingForText': lookingForText,
      'futureGoals': futureGoals,
    };
  }

  factory RegistrationData.fromPersistedJson(Map<String, dynamic> json) {
    return RegistrationData(
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      otpVerified: json['otpVerified'] as bool? ?? false,
      signedUpWithGoogle: json['signedUpWithGoogle'] as bool? ?? false,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      heightFeet: json['heightFeet'] ?? '',
      heightInches: json['heightInches'] ?? '',
      maritalStatus: json['maritalStatus'] as String? ?? '',
      relationshipGoal: json['relationshipGoal'] as String? ?? '',
      country: json['country'] as String? ?? 'Nepal',
      province: json['province'] as String? ?? '',
      district: json['district'] as String? ?? '',
      municipality: json['municipality'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
      gpsEnabled: json['gpsEnabled'] as bool? ?? false,
      educationLevel: json['educationLevel'] as String? ?? '',
      fieldOfStudy: json['fieldOfStudy'] as String? ?? '',
      employment: json['employment'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      company: json['company'] as String? ?? '',
      monthlyIncome: json['monthlyIncome'] as String? ?? '',
      religion: json['religion'] as String? ?? '',
      caste: json['caste'] as String? ?? '',
      gotra: json['gotra'] as String? ?? '',
      horoscope: json['horoscope'] as String? ?? '',
      birthTime: json['birthTime'] as String? ?? '',
      birthPlace: json['birthPlace'] as String? ?? '',
      personality: json['personality'] as String? ?? '',
      lifestyle: json['lifestyle'] as String? ?? '',
      smoking: json['smoking'] as String? ?? '',
      drinking: json['drinking'] as String? ?? '',
      exercise: json['exercise'] as String? ?? '',
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lookingFor: json['lookingFor'] as String? ?? '',
      prefAgeMin: json['prefAgeMin'] as int? ?? 22,
      prefAgeMax: json['prefAgeMax'] as int? ?? 35,
      distancePreference: json['distancePreference'] as String? ?? '',
      preferredReligion: json['preferredReligion'] as String? ?? '',
      interCaste: json['interCaste'] as String? ?? '',
      interReligion: json['interReligion'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      lookingForText: json['lookingForText'] as String? ?? '',
      futureGoals: json['futureGoals'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        phone,
        email,
        password,
        confirmPassword,
        otpVerified,
        signedUpWithGoogle,
        firstName,
        lastName,
        gender,
        dateOfBirth,
        heightFeet,
        heightInches,
        maritalStatus,
        relationshipGoal,
        country,
        province,
        district,
        municipality,
        currentLocation,
        gpsEnabled,
        educationLevel,
        fieldOfStudy,
        employment,
        occupation,
        company,
        monthlyIncome,
        religion,
        caste,
        gotra,
        horoscope,
        birthTime,
        birthPlace,
        personality,
        lifestyle,
        smoking,
        drinking,
        exercise,
        interests,
        lookingFor,
        prefAgeMin,
        prefAgeMax,
        distancePreference,
        preferredReligion,
        interCaste,
        interReligion,
        bio,
        lookingForText,
        futureGoals,
        photos,
      ];
}

class RegistrationState extends Equatable {
  const RegistrationState({
    this.step = 1,
    this.accountSubStep = AccountSubStep.form,
    this.data = const RegistrationData(),
    this.isSubmitting = false,
    this.error,
    this.accountCreated = false,
  });

  final int step;
  final AccountSubStep accountSubStep;
  final RegistrationData data;
  final bool isSubmitting;
  final String? error;
  final bool accountCreated;

  int get progressPercent => ((step / totalRegistrationSteps) * 100).round();

  RegistrationState copyWith({
    int? step,
    AccountSubStep? accountSubStep,
    RegistrationData? data,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? accountCreated,
  }) {
    return RegistrationState(
      step: step ?? this.step,
      accountSubStep: accountSubStep ?? this.accountSubStep,
      data: data ?? this.data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      accountCreated: accountCreated ?? this.accountCreated,
    );
  }

  @override
  List<Object?> get props => [step, accountSubStep, data, isSubmitting, error, accountCreated];
}
