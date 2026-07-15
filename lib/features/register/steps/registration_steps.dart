import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/core_providers.dart';
import '../../../repositories/photo_repository.dart';
import '../../match/services/match_location_service.dart';
import '../about/about_quality.dart';
import '../about/about_widgets.dart';
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
  final _locationService = MatchLocationService();
  bool _gpsLoading = false;
  String? _error;
  String? _gpsError;
  DetectedLocation? _detected;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    if (d.gpsEnabled &&
        d.country.isNotEmpty &&
        d.province.isNotEmpty &&
        d.district.isNotEmpty &&
        d.municipality.isNotEmpty) {
      _detected = DetectedLocation(
        label: d.currentLocation.isNotEmpty ? d.currentLocation : '${d.municipality}, ${d.country}',
        city: d.municipality,
        latitude: 0,
        longitude: 0,
        country: d.country,
        province: d.province,
        district: d.district,
        municipality: d.municipality,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _detect());
    }
  }

  Future<void> _detect() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
      _error = null;
    });
    try {
      final detected = await _locationService.detectUserLocation();
      if (!mounted) return;
      setState(() => _detected = detected);
      ref.read(registrationControllerProvider.notifier).patchData(
            (d) => d.copyWith(
              gpsEnabled: true,
              currentLocation: detected.label,
              country: detected.country,
              province: detected.province,
              district: detected.district,
              municipality: detected.municipality,
            ),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _gpsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _submit() async {
    final detected = _detected;
    if (detected == null) {
      setState(() => _error = 'We need your GPS location to continue. Tap detect and allow permission.');
      return;
    }
    final data = ref.read(registrationControllerProvider).data.copyWith(
          country: detected.country,
          province: detected.province,
          district: detected.district,
          municipality: detected.municipality,
          currentLocation: detected.label,
          gpsEnabled: true,
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
    final scheme = Theme.of(context).colorScheme;
    final detected = _detected;
    final statusLabel = _gpsLoading
        ? 'Detecting…'
        : detected != null
            ? 'Detected location'
            : 'Location needed';
    final headline = _gpsLoading
        ? 'Finding your precise position'
        : detected?.label ?? 'Allow location access to continue';

    return RegistrationStepCard(
      title: 'Location',
      subtitle:
          'We’ll detect your place with GPS and save country, province, district, and city for matching.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: scheme.primary.withValues(alpha: 0.15),
                      ),
                      child: Icon(Icons.my_location_rounded, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headline,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                          ),
                          if (detected != null && detected.latitude != 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${detected.latitude.toStringAsFixed(5)}, ${detected.longitude.toStringAsFixed(5)}'
                              '${detected.accuracyMeters != null && detected.accuracyMeters! > 0 ? ' · ±${detected.accuracyMeters!.round()}m' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (detected != null) ...[
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _AdminCell(label: 'Country', value: detected.country)),
                          const SizedBox(width: 10),
                          Expanded(child: _AdminCell(label: 'Province', value: detected.province)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _AdminCell(label: 'District', value: detected.district)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _AdminCell(
                              label: 'Municipality / City',
                              value: detected.municipality,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _gpsLoading ? null : _detect,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  icon: _gpsLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(detected != null ? Icons.refresh_rounded : Icons.my_location_rounded),
                  label: Text(
                    _gpsLoading
                        ? 'Detecting precise location...'
                        : detected != null
                            ? 'Detect again'
                            : 'Detect my location',
                  ),
                ),
                if (_gpsError != null) ...[
                  const SizedBox(height: 10),
                  Text(_gpsError!, style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
              ],
            ),
          ),
          RegistrationStepNavigation(
            onBack: widget.onBack,
            onNext: _submit,
            loading: _gpsLoading,
            disableNext: detected == null || _gpsLoading,
          ),
        ],
      ),
    );
  }
}

class _AdminCell extends StatelessWidget {
  const _AdminCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.25),
          ),
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
      onSkip: () => widget.onContinue(),
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
      onSkip: () => widget.onContinue(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationChipSelect(
            label: 'Religion',
            value: _religion.isEmpty ? null : _religion,
            options: religionOptions,
            onChanged: (v) => setState(() => _religion = v),
          ),
          const SizedBox(height: 18),
          RegistrationSelectField(
            label: 'Caste',
            value: _caste,
            options: casteOptions,
            onChanged: (v) => setState(() => _caste = v ?? ''),
          ),
          const SizedBox(height: 14),
          RegistrationSelectField(
            label: 'Gotra',
            value: _gotra,
            options: gotraOptions,
            onChanged: (v) => setState(() => _gotra = v ?? ''),
          ),
          const SizedBox(height: 18),
          RegistrationChipSelect(
            label: 'Horoscope preference',
            value: _horoscope.isEmpty ? null : _horoscope,
            options: horoscopeOptions,
            onChanged: (v) => setState(() => _horoscope = v),
            columns: 2,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _birthTime,
            decoration: const InputDecoration(labelText: 'Birth time (optional)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthPlace,
            decoration: const InputDecoration(labelText: 'Birth place (optional)'),
          ),
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
      onSkip: () => widget.onContinue(),
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
      onSkip: () => widget.onContinue(),
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
      onSkip: () => widget.onContinue(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationChipSelect(
            label: 'Looking for',
            value: _lookingFor.isEmpty ? null : _lookingFor,
            options: lookingForOptions,
            onChanged: (v) => setState(() => _lookingFor = v),
          ),
          const SizedBox(height: 18),
          RegistrationAgeRangeSlider(
            minAge: _prefAgeMin,
            maxAge: _prefAgeMax,
            onChanged: (range) {
              setState(() {
                _prefAgeMin = range.start.round();
                _prefAgeMax = range.end.round();
              });
            },
          ),
          const SizedBox(height: 18),
          RegistrationChipSelect(
            label: 'Distance',
            value: _distancePreference.isEmpty ? null : _distancePreference,
            options: distanceOptions,
            onChanged: (v) => setState(() => _distancePreference = v),
            columns: 1,
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Preferred religion',
            value: _preferredReligion.isEmpty ? null : _preferredReligion,
            options: religionOptions,
            onChanged: (v) => setState(() => _preferredReligion = v),
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Open to inter-caste?',
            value: _interCaste.isEmpty ? null : _interCaste,
            options: marriagePrefOptions,
            onChanged: (v) => setState(() => _interCaste = v),
          ),
          const SizedBox(height: 16),
          RegistrationChipSelect(
            label: 'Open to inter-religion?',
            value: _interReligion.isEmpty ? null : _interReligion,
            options: marriagePrefOptions,
            onChanged: (v) => setState(() => _interReligion = v),
          ),
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
  String? _toast;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    _bio = TextEditingController(text: d.bio);
    _lookingForText = TextEditingController(text: d.lookingForText);
    _futureGoals = TextEditingController(text: d.futureGoals);
    _bio.addListener(_onChanged);
    _lookingForText.addListener(_onChanged);
    _futureGoals.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bio.removeListener(_onChanged);
    _lookingForText.removeListener(_onChanged);
    _futureGoals.removeListener(_onChanged);
    _bio.dispose();
    _lookingForText.dispose();
    _futureGoals.dispose();
    super.dispose();
  }

  void _persistDraft({bool aboutStepSkipped = false}) {
    ref.read(registrationControllerProvider.notifier).patchData(
          (d) => d.copyWith(
            bio: _bio.text,
            lookingForText: _lookingForText.text,
            futureGoals: _futureGoals.text,
            aboutStepSkipped: aboutStepSkipped,
          ),
        );
  }

  Future<void> _generate() async {
    final hasExisting = _bio.text.trim().isNotEmpty ||
        _lookingForText.text.trim().isNotEmpty ||
        _futureGoals.text.trim().isNotEmpty;
    if (hasExisting) {
      final ok = await confirmReplaceAboutCopy(context);
      if (!ok || !mounted) return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _toast = null;
    });
    try {
      final copy = await ref.read(profileRepositoryProvider).generateProfileCopy(
            style: 'friendly',
            language: 'en',
            force: true,
            apply: false,
          );
      if (!mounted) return;
      final bio = truncateAtSentence(copy.bio, AboutLimits.bio.max);
      final looking = truncateAtSentence(copy.lookingFor, AboutLimits.lookingFor.max);
      final goals = truncateAtSentence(copy.futureGoals, AboutLimits.futureGoals.max);
      setState(() {
        _bio.text = bio;
        _lookingForText.text = looking;
        _futureGoals.text = goals;
        _toast = 'Generated from your profile';
      });
      _persistDraft(aboutStepSkipped: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _toast = 'Unable to generate profile. Please try again.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _skip() async {
    _persistDraft(aboutStepSkipped: true);
    await widget.onContinue();
  }

  Future<void> _submit() async {
    final data = ref.read(registrationControllerProvider).data.copyWith(
          bio: _bio.text.trim(),
          lookingForText: _lookingForText.text.trim(),
          futureGoals: _futureGoals.text.trim(),
          aboutStepSkipped: false,
        );
    final error = validateAbout(data);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required AboutFieldLimits limits,
    required String placeholder,
    required int maxLines,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = controller.text;
    final quality = assessWritingQuality(text, limits);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: limits.max + 40,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              const SizedBox.shrink(),
          decoration: InputDecoration(
            alignLabelWithHint: true,
            hintText: placeholder,
            hintMaxLines: 3,
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: AboutQualityMeter(quality: quality)),
            const SizedBox(width: 12),
            AboutCharCounter(length: text.trim().length, min: limits.min, max: limits.max),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RegistrationStepCard(
      title: 'About you',
      subtitle: 'Write in your voice. Authentic profiles get better matches.',
      onSkip: _skip,
      skipDisabled: _generating,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 18),
            label: Text(_generating ? 'Generating...' : 'Generate from My Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (_toast != null) ...[
            const SizedBox(height: 10),
            Text(
              _toast!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _toast!.startsWith('Unable') ? scheme.error : scheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _field(
            label: 'Bio',
            controller: _bio,
            limits: AboutLimits.bio,
            placeholder: AboutPlaceholders.bio,
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          _field(
            label: 'What are you looking for?',
            controller: _lookingForText,
            limits: AboutLimits.lookingFor,
            placeholder: AboutPlaceholders.lookingFor,
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          _field(
            label: 'Future goals',
            controller: _futureGoals,
            limits: AboutLimits.futureGoals,
            placeholder: AboutPlaceholders.futureGoals,
            maxLines: 4,
          ),
          RegistrationFieldError(message: _error),
          RegistrationStepNavigation(
            onBack: widget.onBack,
            onNext: _submit,
            loading: _generating,
            disableNext: _generating,
          ),
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
