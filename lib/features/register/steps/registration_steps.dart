import '../../../core/widgets/osm_map_preview.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/core_providers.dart';
import '../../match/services/match_location_service.dart';
import '../about/about_quality.dart';
import '../about/about_widgets.dart';
import '../registration_constants.dart';
import '../registration_controller.dart';
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

  // Location (web merges it into this step).
  final _locationService = MatchLocationService();
  bool _gpsLoading = false;
  String? _gpsError;
  DetectedLocation? _location;

  Future<void> _detect() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
      _error = null;
    });
    try {
      final detected = await _locationService.detectUserLocation();
      if (!mounted) return;
      setState(() => _location = detected);
      ref.read(registrationControllerProvider.notifier).patchData(
            (d) => d.copyWith(
              gpsEnabled: true,
              currentLocation: detected.label,
              latitude: detected.latitude,
              longitude: detected.longitude,
              country: detected.country,
              province: detected.province,
              district: detected.district,
              municipality: detected.municipality,
            ),
          );
    } catch (e) {
      if (mounted) setState(() => _gpsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final d = ref.read(registrationControllerProvider).data;
    if (d.gpsEnabled && d.country.isNotEmpty && d.municipality.isNotEmpty) {
      _location = DetectedLocation(
        label: d.currentLocation.isNotEmpty ? d.currentLocation : '${d.municipality}, ${d.country}',
        city: d.municipality,
        latitude: d.latitude ?? 0,
        longitude: d.longitude ?? 0,
        country: d.country,
        province: d.province,
        district: d.district,
        municipality: d.municipality,
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _detect());
    }
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
    if (_location == null) {
      setState(() => _error = 'We need your GPS location to continue. Tap detect and allow permission.');
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((_) => data);
    await widget.onContinue();
  }

  /// "Kathmandu Metropolitan City" -> "Kathmandu", "Bagamati Province" -> "Bagamati".
  static String _shortPlace(String value) {
    return value
        .replaceAll(
          RegExp(r'\s+(Sub-?Metropolitan City|Metropolitan City|Rural Municipality|Municipality|Province|District)$',
              caseSensitive: false),
          '',
        )
        .trim();
  }

  Widget _locationCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = _location;
    final hasCoords = loc != null && (loc.latitude != 0 || loc.longitude != 0);
    // Short address: "Kathmandu" + "Bagamati, Nepal" (no repeated names or admin suffixes).
    final city = loc == null
        ? ''
        : _shortPlace(loc.municipality.isNotEmpty
            ? loc.municipality
            : (loc.city.isNotEmpty ? loc.city : loc.district.isNotEmpty ? loc.district : loc.label.split(',').first));
    final title = loc != null
        ? city
        : _gpsLoading
            ? 'Detecting your location…'
            : 'Location not shared yet';
    final area = loc == null
        ? 'We show people near you. Only your area is visible, never your exact address.'
        : <String>{_shortPlace(loc.province), loc.country.trim()}
            .where((p) => p.isNotEmpty && p.toLowerCase() != city.toLowerCase())
            .join(', ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        color: scheme.surfaceContainer.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasCoords)
            OsmMapPreview(lat: loc.latitude, lng: loc.longitude, zoom: 14)
          else
            Container(
              height: 140,
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _gpsLoading
                      ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3))
                      : Icon(
                          loc != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                          size: 36,
                          color: loc != null ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                  const SizedBox(height: 10),
                  Text(
                    _gpsLoading
                        ? 'Finding your location…'
                        : (loc != null ? 'Tap "Detect again" to show the map' : 'Map appears once location is shared'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    loc != null ? Icons.location_on_rounded : Icons.location_searching_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      if (area.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, height: 1.35, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              height: 46,
              child: loc != null
                  ? OutlinedButton.icon(
                      onPressed: _gpsLoading ? null : _detect,
                      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                      icon: _gpsLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_gpsLoading ? 'Detecting…' : 'Detect again'),
                    )
                  : FilledButton.icon(
                      onPressed: _gpsLoading ? null : _detect,
                      style: FilledButton.styleFrom(shape: const StadiumBorder()),
                      icon: _gpsLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(_gpsLoading ? 'Detecting…' : 'Detect my location'),
                    ),
            ),
          ),
          if ((_error ?? _gpsError) != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.06),
                border: Border(top: BorderSide(color: scheme.error.withValues(alpha: 0.2))),
              ),
              child: Text(_error ?? _gpsError!, style: TextStyle(fontSize: 13, color: scheme.error)),
            ),
        ],
      ),
    );
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
          RegistrationOptionSelectField<String>(
            label: 'Gender',
            value: _gender,
            options: genderOptions,
            onChanged: (v) => setState(() => _gender = v ?? ''),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              isEmpty: _dob.isEmpty,
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                hintText: 'Select your date of birth',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _dob.isEmpty
                    ? ''
                    : DateFormat('MMM d, yyyy').format(DateTime.tryParse(_dob) ?? DateTime.now()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final inches = (_heightFeet * 12 + _heightInches).clamp(54, 84);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Height', style: TextStyle(fontWeight: FontWeight.w700))),
                    Text("${inches ~/ 12}'${inches % 12}\" (${(inches * 2.54).round()} cm)",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Slider(
                  value: inches.toDouble(),
                  min: 54,
                  max: 84,
                  divisions: 30,
                  label: "${inches ~/ 12}'${inches % 12}\"",
                  onChanged: (v) => setState(() {
                    _heightFeet = v.round() ~/ 12;
                    _heightInches = v.round() % 12;
                  }),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          RegistrationOptionSelectField<String>(
            label: 'Marital status',
            value: _maritalStatus,
            options: maritalStatusOptions,
            onChanged: (v) => setState(() => _maritalStatus = v ?? ''),
          ),
          const SizedBox(height: 16),
          RegistrationOptionSelectField<String>(
            label: 'Relationship goal',
            value: _relationshipGoal,
            options: relationshipGoalOptions,
            onChanged: (v) => setState(() => _relationshipGoal = v ?? ''),
          ),
          const SizedBox(height: 24),
          _locationCard(context),
          RegistrationStepNavigation(
            onBack: widget.onBack,
            onNext: _submit,
            loading: _gpsLoading,
            disableNext: _location == null || _gpsLoading,
          ),
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
