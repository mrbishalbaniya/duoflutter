import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/core_providers.dart';
import '../../../repositories/photo_repository.dart';
import '../registration_constants.dart';
import '../registration_controller.dart';
import '../registration_models.dart';
import '../registration_validators.dart';
import '../widgets/registration_widgets.dart';

// --- Step 2: Basic Info ---

class StepBasicInfo extends ConsumerStatefulWidget {
  const StepBasicInfo({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends ConsumerState<StepBasicInfo> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  String _gender = '';
  String _dob = '';
  int _heightFeet = 5;
  int _heightInches = 6;
  String _maritalStatus = '';
  String _relationshipGoal = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _firstName = TextEditingController(text: d.firstName);
    _lastName = TextEditingController(text: d.lastName);
    _gender = d.gender;
    _dob = d.dateOfBirth;
    _heightFeet = d.heightFeet is int ? d.heightFeet as int : int.tryParse('${d.heightFeet}') ?? 5;
    _heightInches = d.heightInches is int ? d.heightInches as int : int.tryParse('${d.heightInches}') ?? 6;
    _maritalStatus = d.maritalStatus;
    _relationshipGoal = d.relationshipGoal;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob.isNotEmpty ? (DateTime.tryParse(_dob) ?? maxBirthDateForMinAge(18)) : maxBirthDateForMinAge(18),
      firstDate: minBirthDate(),
      lastDate: maxBirthDateForMinAge(18),
    );
    if (picked != null) setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          gender: _gender,
          dateOfBirth: _dob,
          heightFeet: _heightFeet,
          heightInches: _heightInches,
          maritalStatus: _maritalStatus,
          relationshipGoal: _relationshipGoal,
        );
    final error = validateBasicInfo(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Basic information',
      subtitle: 'Tell us who you are and what you are looking for.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name'))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name'))),
            ],
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Gender',
            value: _gender.isEmpty ? null : _gender,
            options: genderOptions,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of birth'),
            subtitle: Text(_dob.isEmpty ? 'Select date' : _dob),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDob,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RegistrationSelectField(
                  label: 'Height (feet)',
                  value: '$_heightFeet',
                  options: heightFeetOptions.map((e) => '$e').toList(),
                  onChanged: (v) => setState(() => _heightFeet = int.parse(v ?? '5')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RegistrationSelectField(
                  label: 'Height (inches)',
                  value: '$_heightInches',
                  options: heightInchesOptions.map((e) => '$e').toList(),
                  onChanged: (v) => setState(() => _heightInches = int.parse(v ?? '6')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Marital status',
            value: _maritalStatus.isEmpty ? null : _maritalStatus,
            options: maritalStatusOptions,
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Relationship goal',
            value: _relationshipGoal.isEmpty ? null : _relationshipGoal,
            options: relationshipGoalOptions,
            onChanged: (v) => setState(() => _relationshipGoal = v),
          ),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 3: Location ---

class StepLocation extends ConsumerStatefulWidget {
  const StepLocation({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepLocation> createState() => _StepLocationState();
}

class _StepLocationState extends ConsumerState<StepLocation> {
  late final TextEditingController _country;
  late final TextEditingController _district;
  late final TextEditingController _municipality;
  late final TextEditingController _currentLocation;
  String _province = '';
  bool _gpsLoading = false;
  String? _error;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _country = TextEditingController(text: d.country);
    _district = TextEditingController(text: d.district);
    _municipality = TextEditingController(text: d.municipality);
    _currentLocation = TextEditingController(text: d.currentLocation);
    _province = d.province;
  }

  @override
  void dispose() {
    _country.dispose();
    _district.dispose();
    _municipality.dispose();
    _currentLocation.dispose();
    super.dispose();
  }

  Future<void> _enableGps() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation.text =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
      ref.read(registrationControllerProvider.notifier).patchData(
            (d) => d.copyWith(gpsEnabled: true, currentLocation: _currentLocation.text),
          );
    } catch (e) {
      setState(() => _gpsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          country: _country.text.trim(),
          province: _province,
          district: _district.text.trim(),
          municipality: _municipality.text.trim(),
          currentLocation: _currentLocation.text.trim(),
        );
    final error = validateLocation(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Location',
      subtitle: 'Help us connect you with people nearby across Nepal.',
      child: Column(
        children: [
          TextFormField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
          const SizedBox(height: 12),
          RegistrationSelectField(
            label: 'Province',
            value: _province,
            options: nepalProvinces,
            onChanged: (v) => setState(() => _province = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _district, decoration: const InputDecoration(labelText: 'District', hintText: 'e.g. Kathmandu')),
          const SizedBox(height: 12),
          TextFormField(controller: _municipality, decoration: const InputDecoration(labelText: 'Municipality / City', hintText: 'e.g. Lalitpur')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _currentLocation,
                  decoration: const InputDecoration(labelText: 'Current location', hintText: 'Detected or manual location'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _gpsLoading ? null : _enableGps,
                  icon: _gpsLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_outlined),
                  label: Text(_gpsLoading ? 'Detecting...' : 'Use my location'),
                ),
                RegistrationFieldError(message: _gpsError),
              ],
            ),
          ),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 4: Education ---

class StepEducation extends ConsumerStatefulWidget {
  const StepEducation({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepEducation> createState() => _StepEducationState();
}

class _StepEducationState extends ConsumerState<StepEducation> {
  String _educationLevel = '';
  String _fieldOfStudy = '';
  String _employment = '';
  late final TextEditingController _occupation;
  late final TextEditingController _company;
  String _monthlyIncome = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _educationLevel = d.educationLevel;
    _fieldOfStudy = d.fieldOfStudy;
    _employment = d.employment;
    _occupation = TextEditingController(text: d.occupation);
    _company = TextEditingController(text: d.company);
    _monthlyIncome = d.monthlyIncome;
  }

  @override
  void dispose() {
    _occupation.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          educationLevel: _educationLevel,
          fieldOfStudy: _fieldOfStudy,
          employment: _employment,
          occupation: _occupation.text.trim(),
          company: _company.text.trim(),
          monthlyIncome: _monthlyIncome,
        );
    final error = validateEducation(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Education & career',
      subtitle: 'Share your education and what you do professionally.',
      child: Column(
        children: [
          RegistrationChipSelect(label: 'Education level', value: _educationLevel.isEmpty ? null : _educationLevel, options: educationLevelOptions, onChanged: (v) => setState(() => _educationLevel = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Field of study', value: _fieldOfStudy.isEmpty ? null : _fieldOfStudy, options: fieldOfStudyOptions, onChanged: (v) => setState(() => _fieldOfStudy = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Employment', value: _employment.isEmpty ? null : _employment, options: employmentOptions, onChanged: (v) => setState(() => _employment = v)),
          const SizedBox(height: 12),
          TextFormField(controller: _occupation, decoration: const InputDecoration(labelText: 'Occupation')),
          const SizedBox(height: 12),
          TextFormField(controller: _company, decoration: const InputDecoration(labelText: 'Company (optional)')),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Monthly income', value: _monthlyIncome.isEmpty ? null : _monthlyIncome, options: incomeOptions, onChanged: (v) => setState(() => _monthlyIncome = v), columns: 1),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 5: Religion ---

class StepReligion extends ConsumerStatefulWidget {
  const StepReligion({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepReligion> createState() => _StepReligionState();
}

class _StepReligionState extends ConsumerState<StepReligion> {
  String _religion = '';
  String _caste = '';
  String _gotra = '';
  String _horoscope = '';
  late final TextEditingController _birthTime;
  late final TextEditingController _birthPlace;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _religion = d.religion;
    _caste = d.caste;
    _gotra = d.gotra;
    _horoscope = d.horoscope;
    _birthTime = TextEditingController(text: d.birthTime);
    _birthPlace = TextEditingController(text: d.birthPlace);
  }

  @override
  void dispose() {
    _birthTime.dispose();
    _birthPlace.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          religion: _religion,
          caste: _caste,
          gotra: _gotra,
          horoscope: _horoscope,
          birthTime: _birthTime.text.trim(),
          birthPlace: _birthPlace.text.trim(),
        );
    final error = validateReligion(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Religion & culture',
      subtitle: 'Optional cultural details help with compatibility in Nepal.',
      child: Column(
        children: [
          RegistrationChipSelect(label: 'Religion', value: _religion.isEmpty ? null : _religion, options: religionOptions, onChanged: (v) => setState(() => _religion = v)),
          const SizedBox(height: 16),
          RegistrationSelectField(label: 'Caste', value: _caste, options: casteOptions, onChanged: (v) => setState(() => _caste = v ?? '')),
          const SizedBox(height: 12),
          RegistrationSelectField(label: 'Gotra', value: _gotra, options: gotraOptions, onChanged: (v) => setState(() => _gotra = v ?? '')),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Horoscope preference', value: _horoscope.isEmpty ? null : _horoscope, options: horoscopeOptions, onChanged: (v) => setState(() => _horoscope = v)),
          const SizedBox(height: 12),
          TextFormField(controller: _birthTime, decoration: const InputDecoration(labelText: 'Birth time (optional)')),
          const SizedBox(height: 12),
          TextFormField(controller: _birthPlace, decoration: const InputDecoration(labelText: 'Birth place (optional)')),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 6: Lifestyle ---

class StepLifestyle extends ConsumerStatefulWidget {
  const StepLifestyle({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepLifestyle> createState() => _StepLifestyleState();
}

class _StepLifestyleState extends ConsumerState<StepLifestyle> {
  String _personality = '';
  String _lifestyle = '';
  String _smoking = '';
  String _drinking = '';
  String _exercise = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _personality = d.personality;
    _lifestyle = d.lifestyle;
    _smoking = d.smoking;
    _drinking = d.drinking;
    _exercise = d.exercise;
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          personality: _personality,
          lifestyle: _lifestyle,
          smoking: _smoking,
          drinking: _drinking,
          exercise: _exercise,
        );
    final error = validateLifestyle(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Lifestyle',
      subtitle: 'Help matches understand your daily rhythm and habits.',
      child: Column(
        children: [
          RegistrationChipSelect(label: 'Personality', value: _personality.isEmpty ? null : _personality, options: personalityOptions, onChanged: (v) => setState(() => _personality = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Lifestyle pace', value: _lifestyle.isEmpty ? null : _lifestyle, options: lifestyleOptions, onChanged: (v) => setState(() => _lifestyle = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Smoking', value: _smoking.isEmpty ? null : _smoking, options: frequencyOptions, onChanged: (v) => setState(() => _smoking = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Drinking', value: _drinking.isEmpty ? null : _drinking, options: frequencyOptions, onChanged: (v) => setState(() => _drinking = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Exercise', value: _exercise.isEmpty ? null : _exercise, options: exerciseOptions, onChanged: (v) => setState(() => _exercise = v)),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 7: Interests ---

class StepInterests extends ConsumerStatefulWidget {
  const StepInterests({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepInterests> createState() => _StepInterestsState();
}

class _StepInterestsState extends ConsumerState<StepInterests> {
  late List<String> _interests;
  String? _error;

  @override
  void initState() {
    super.initState();
    _interests = List<String>.from(ref.read(registrationControllerProvider).data.interests);
  }

  Future<void> _submit() async {
    final error = validateInterests(_interests);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((d) => d.copyWith(interests: _interests));
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Interests',
      subtitle: 'Pick at least 5 interests to improve your matches.',
      child: Column(
        children: [
          RegistrationMultiChipSelect(
            label: 'What are you into?',
            values: _interests,
            options: interestOptions,
            min: 5,
            onChanged: (v) => setState(() => _interests = v),
            error: _error,
          ),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 8: Preferences ---

class StepPreferences extends ConsumerStatefulWidget {
  const StepPreferences({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepPreferences> createState() => _StepPreferencesState();
}

class _StepPreferencesState extends ConsumerState<StepPreferences> {
  String _lookingFor = '';
  int _prefAgeMin = 22;
  int _prefAgeMax = 35;
  String _distancePreference = '';
  String _preferredReligion = '';
  String _interCaste = '';
  String _interReligion = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _lookingFor = d.lookingFor;
    _prefAgeMin = d.prefAgeMin;
    _prefAgeMax = d.prefAgeMax;
    _distancePreference = d.distancePreference;
    _preferredReligion = d.preferredReligion;
    _interCaste = d.interCaste;
    _interReligion = d.interReligion;
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          lookingFor: _lookingFor,
          prefAgeMin: _prefAgeMin,
          prefAgeMax: _prefAgeMax,
          distancePreference: _distancePreference,
          preferredReligion: _preferredReligion,
          interCaste: _interCaste,
          interReligion: _interReligion,
        );
    final error = validatePreferences(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'Match preferences',
      subtitle: 'Tell us who you would like to meet.',
      child: Column(
        children: [
          RegistrationChipSelect(label: 'Looking for', value: _lookingFor.isEmpty ? null : _lookingFor, options: lookingForOptions, onChanged: (v) => setState(() => _lookingFor = v)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownMenuFormField<int>(
                  initialSelection: _prefAgeMin,
                  label: const Text('Min age'),
                  dropdownMenuEntries: List.generate(63, (i) => DropdownMenuEntry(value: i + 18, label: '${i + 18}')),
                  onSelected: (v) => setState(() => _prefAgeMin = v ?? _prefAgeMin),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownMenuFormField<int>(
                  initialSelection: _prefAgeMax,
                  label: const Text('Max age'),
                  dropdownMenuEntries: List.generate(63, (i) => DropdownMenuEntry(value: i + 18, label: '${i + 18}')),
                  onSelected: (v) => setState(() => _prefAgeMax = v ?? _prefAgeMax),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Distance', value: _distancePreference.isEmpty ? null : _distancePreference, options: distanceOptions, onChanged: (v) => setState(() => _distancePreference = v), columns: 1),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Preferred religion', value: _preferredReligion.isEmpty ? null : _preferredReligion, options: religionOptions, onChanged: (v) => setState(() => _preferredReligion = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Open to inter-caste?', value: _interCaste.isEmpty ? null : _interCaste, options: marriagePrefOptions, onChanged: (v) => setState(() => _interCaste = v)),
          const SizedBox(height: 16),
          RegistrationChipSelect(label: 'Open to inter-religion?', value: _interReligion.isEmpty ? null : _interReligion, options: marriagePrefOptions, onChanged: (v) => setState(() => _interReligion = v)),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 9: About ---

class StepAbout extends ConsumerStatefulWidget {
  const StepAbout({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepAbout> createState() => _StepAboutState();
}

class _StepAboutState extends ConsumerState<StepAbout> {
  late final TextEditingController _bio;
  late final TextEditingController _lookingForText;
  late final TextEditingController _futureGoals;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _bio = TextEditingController(text: d.bio);
    _lookingForText = TextEditingController(text: d.lookingForText);
    _futureGoals = TextEditingController(text: d.futureGoals);
  }

  @override
  void dispose() {
    _bio.dispose();
    _lookingForText.dispose();
    _futureGoals.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          bio: _bio.text.trim(),
          lookingForText: _lookingForText.text.trim(),
          futureGoals: _futureGoals.text.trim(),
        );
    final error = validateAbout(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationStepCard(
      title: 'About you',
      subtitle: 'Write a compelling bio so great matches can find you.',
      child: Column(
        children: [
          TextFormField(controller: _bio, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _lookingForText, maxLines: 3, decoration: const InputDecoration(labelText: 'What are you looking for?', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          TextFormField(controller: _futureGoals, maxLines: 3, decoration: const InputDecoration(labelText: 'Future goals', alignLabelWithHint: true)),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit),
        ],
      ),
    );
  }
}

// --- Step 10: Photos ---

class StepPhotos extends ConsumerStatefulWidget {
  const StepPhotos({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends ConsumerState<StepPhotos> {
  late List<RegistrationPhoto> _photos;
  bool _analyzing = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List<RegistrationPhoto>.from(ref.read(registrationControllerProvider).data.photos);
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 9) return;
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    final reg = ref.read(registrationControllerProvider);
    if (!reg.accountCreated && !reg.data.signedUpWithGoogle) {
      setState(() => _error = 'Complete account setup (steps 1–2) before uploading photos.');
      return;
    }

    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final repo = ref.read(photoRepositoryProvider);
      var uploaded = List<RegistrationPhoto>.from(_photos);
      final isFirst = uploaded.isEmpty;

      for (var i = 0; i < files.length && uploaded.length < 9; i++) {
        final file = files[i];
        final isPrimary = isFirst && i == 0 && !uploaded.any((p) => p.isProfile);
        final result = await repo.uploadAndAnalyzePhoto(File(file.path), isPrimary: isPrimary);
        final uploadError = getPhotoUploadError(result, fileName: file.name);
        if (uploadError != null) throw Exception(uploadError);

        uploaded.add(RegistrationPhoto(
          id: '${DateTime.now().millisecondsSinceEpoch}-${file.name}-$i',
          fileName: file.name,
          localPath: file.path,
          isProfile: isPrimary,
          imageUrl: result.imageUrl,
          status: RegistrationPhotoStatus.approved,
        ));
      }

      if (uploaded.isNotEmpty && !uploaded.any((p) => p.isProfile)) {
        uploaded[0] = uploaded[0].copyWith(isProfile: true);
      }

      setState(() => _photos = uploaded);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _removePhoto(String id) {
    setState(() {
      var next = _photos.where((p) => p.id != id).toList();
      if (next.isNotEmpty && !next.any((p) => p.isProfile)) {
        next[0] = next[0].copyWith(isProfile: true);
      }
      _photos = next;
      _error = null;
    });
  }

  void _setProfile(String id) {
    setState(() {
      _photos = _photos.map((p) => p.copyWith(isProfile: p.id == id)).toList();
    });
  }

  Future<void> _submit() async {
    final error = validatePhotos(_photos);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((d) => d.copyWith(photos: _photos));
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final approvedCount = _photos.where((p) => p.status == RegistrationPhotoStatus.approved).length;

    return RegistrationStepCard(
      title: 'Photos',
      subtitle: 'Upload at least 2 photos. Each photo is checked with AI for face, quality, and safety.',
      child: Column(
        children: [
          InkWell(
            onTap: _analyzing ? null : _pickPhotos,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.3), style: BorderStyle.solid),
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: scheme.primary),
                  const SizedBox(height: 8),
                  Text(_analyzing ? 'Analyzing photos...' : 'Tap to add photos'),
                  Text('$approvedCount verified · ${_photos.length}/9', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: photo.localPath != null
                          ? Image.file(File(photo.localPath!), fit: BoxFit.cover)
                          : ColoredBox(color: scheme.surfaceContainerHighest),
                    ),
                    if (photo.isProfile)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Main', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removePhoto(photo.id),
                      ),
                    ),
                    if (!photo.isProfile)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: TextButton(
                          onPressed: () => _setProfile(photo.id),
                          child: const Text('Set main', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(onBack: widget.onBack, onNext: _submit, loading: _analyzing),
        ],
      ),
    );
  }
}

// --- Step 11: Review ---

class StepReview extends ConsumerWidget {
  const StepReview({
    super.key,
    required this.onSubmit,
    required this.onBack,
    required this.onEditStep,
    this.loading = false,
  });

  final Future<void> Function() onSubmit;
  final VoidCallback onBack;
  final ValueChanged<int> onEditStep;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationControllerProvider).data;
    final scheme = Theme.of(context).colorScheme;
    RegistrationPhoto? profilePhoto;
    for (final photo in data.photos) {
      if (photo.isProfile) {
        profilePhoto = photo;
        break;
      }
    }
    profilePhoto ??= data.photos.isNotEmpty ? data.photos.first : null;

    return RegistrationStepCard(
      title: 'Review your profile',
      subtitle: 'Check everything before you start matching across Nepal.',
      child: Column(
        children: [
          if (profilePhoto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: profilePhoto.localPath != null
                    ? Image.file(File(profilePhoto.localPath!), fit: BoxFit.cover)
                    : ColoredBox(color: scheme.surfaceContainerHighest),
              ),
            ),
          const SizedBox(height: 16),
          _ReviewSection(title: 'Account', step: 1, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Email', value: data.email),
            _ReviewRow(label: 'Phone', value: data.phone),
          ]),
          const SizedBox(height: 12),
          _ReviewSection(title: 'Basic Info', step: 2, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Name', value: '${data.firstName} ${data.lastName}'.trim()),
            _ReviewRow(label: 'Gender', value: labelForOption(genderOptions, data.gender)),
            _ReviewRow(label: 'Age', value: '${calculateAgeFromDob(data.dateOfBirth)}'),
            _ReviewRow(label: 'Goal', value: labelForOption(relationshipGoalOptions, data.relationshipGoal)),
          ]),
          const SizedBox(height: 12),
          _ReviewSection(title: 'Location', step: 3, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Location', value: buildLocation(data)),
          ]),
          const SizedBox(height: 12),
          _ReviewSection(title: 'Education', step: 4, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Education', value: buildEducation(data)),
            _ReviewRow(label: 'Occupation', value: data.occupation),
          ]),
          const SizedBox(height: 12),
          _ReviewSection(title: 'Preferences', step: 8, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Looking for', value: labelForOption(lookingForOptions, data.lookingFor)),
            _ReviewRow(label: 'Age range', value: '${data.prefAgeMin}–${data.prefAgeMax}'),
            _ReviewRow(label: 'Distance', value: labelForOption(distanceOptions, data.distancePreference)),
          ]),
          const SizedBox(height: 12),
          _ReviewSection(title: 'Photos', step: 10, onEdit: onEditStep, children: [
            _ReviewRow(label: 'Verified photos', value: '${data.photos.length}'),
          ]),
          RegistrationStepNavigation(
            onBack: onBack,
            onNext: onSubmit,
            nextLabel: 'Complete registration',
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.step, required this.onEdit, required this.children});

  final String title;
  final int step;
  final ValueChanged<int> onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              OutlinedButton(onPressed: () => onEdit(step), child: const Text('Edit')),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}
