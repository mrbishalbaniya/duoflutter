import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/duo_theme.dart';
import '../../repositories/photo_repository.dart';
import '../auth/auth_controller.dart';
import '../match/domain/match_domain.dart';
import '../match/providers/match_providers.dart';
import '../register/registration_constants.dart';
import 'domain/profile_edit_models.dart';
import 'providers/profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.initialProfile});

  final DuoProfile initialProfile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late ProfileEditFormData _form;
  late final TextEditingController _locationController;
  bool _saving = false;
  bool _detectingLocation = false;
  bool _analyzingPhotos = false;
  String? _saveError;
  String? _locationError;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _form = profileToEditForm(widget.initialProfile);
    _locationController = TextEditingController(text: _form.location);
    if (isDefaultLocation(_form.location)) {
      Future.microtask(_detectLocation);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
    });
    try {
      final detected = await ref.read(matchLocationServiceProvider).detectUserLocation();
      setState(() {
        _form.location = detected.label;
        _locationController.text = detected.label;
      });
    } catch (e) {
      setState(() => _locationError = e.toString());
    } finally {
      setState(() => _detectingLocation = false);
    }
  }

  Future<void> _pickPhotos() async {
    if (_form.photos.length >= 9) return;
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    setState(() {
      _photoError = null;
      _analyzingPhotos = true;
    });

    try {
      final repo = ref.read(photoRepositoryProvider);
      final remaining = 9 - _form.photos.length;
      final selected = files.take(remaining);
      final uploaded = <ProfileEditPhoto>[];
      final isFirst = _form.photos.isEmpty;

      for (var i = 0; i < selected.length; i++) {
        final file = selected.elementAt(i);
        final local = File(file.path);
        final isPrimary = isFirst && i == 0;
        final result = await repo.uploadAndAnalyzePhoto(local, isPrimary: isPrimary);
        final error = getPhotoUploadError(result, fileName: file.name);
        if (error != null) throw Exception(error);
        uploaded.add(
          ProfileEditPhoto(
            id: '${DateTime.now().millisecondsSinceEpoch}-$i',
            url: result.imageUrl!,
            fileName: file.name,
            isProfile: isPrimary,
          ),
        );
      }

      setState(() => _form.photos = [..._form.photos, ...uploaded]);
    } catch (e) {
      setState(() => _photoError = e.toString());
    } finally {
      setState(() => _analyzingPhotos = false);
    }
  }

  void _removePhoto(String id) {
    final next = _form.photos.where((p) => p.id != id).toList();
    if (next.isNotEmpty && !next.any((p) => p.isProfile)) {
      next[0] = next[0].copyWith(isProfile: true);
    }
    setState(() => _form.photos = next);
  }

  void _setProfilePhoto(String id) {
    setState(() {
      _form.photos = _form.photos
          .map((p) => p.copyWith(isProfile: p.id == id))
          .toList();
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      _form.location = _locationController.text.trim();
      final payload = await buildProfileUpdatePayload(
        form: _form,
        existing: widget.initialProfile,
        photoRepo: ref.read(photoRepositoryProvider),
      );
      await ref.read(profileRepositoryProvider).updateProfile(payload);
      ref.invalidate(myProfileProvider);
      ref.invalidate(profileScreenProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      setState(() => _saveError = e.message);
    } catch (e) {
      setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _section('Photos', _photosSection()),
          _section('Personal', _personalSection()),
          _section('About', _aboutSection()),
          _section('Education & career', _educationSection()),
          _section('Background', _backgroundSection()),
          _section('Lifestyle', _lifestyleSection()),
          _section('Partner preferences', _preferencesSection()),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _photosSection() {
    return Column(
      children: [
        if (_photoError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_photoError!, style: const TextStyle(color: DuoColors.error)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final photo in _form.photos)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photo.url,
                      width: 88,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (photo.isProfile)
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removePhoto(photo.id),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: () => _setProfilePhoto(photo.id),
                      child: const Text('Main', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ],
              ),
            if (_form.photos.length < 9)
              OutlinedButton.icon(
                onPressed: _analyzingPhotos ? null : _pickPhotos,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_analyzingPhotos ? 'Analyzing…' : 'Add photos'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _personalSection() {
    return Column(
      children: [
        _field('Full name', _form.fullName, (v) => _form.fullName = v),
        _field('Age', _form.age, (v) => _form.age = v, keyboard: TextInputType.number),
        _dropdown(
          'Gender',
          _form.gender,
          profileGenderOptions,
          (v) => setState(() => _form.gender = v ?? ''),
        ),
        _field('Phone country code', _form.phoneCountryCode, (v) => _form.phoneCountryCode = v),
        _field('Phone number', _form.phoneNumber, (v) => _form.phoneNumber = v, keyboard: TextInputType.phone),
        _field('Height', _form.height, (v) => _form.height = v),
        _dropdown(
          'Religion',
          _form.religion,
          religionDropdownOptions(),
          (v) => setState(() => _form.religion = v ?? ''),
        ),
        _dropdown(
          'Relationship goal',
          _form.relationshipGoal,
          profileRelationshipGoalOptions,
          (v) => setState(() => _form.relationshipGoal = v ?? ''),
        ),
        _dropdown(
          'Work preference',
          _form.workPreference,
          profileWorkPreferenceOptions,
          (v) => setState(() => _form.workPreference = v ?? ''),
        ),
        TextField(
          controller: _locationController,
          onChanged: (v) => _form.location = v,
          decoration: InputDecoration(
            labelText: 'Location',
            suffixIcon: IconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: _detectingLocation ? null : DuoColors.primary,
              ),
              onPressed: _detectingLocation ? null : _detectLocation,
            ),
          ),
        ),
        if (_locationError != null)
          Text(_locationError!, style: const TextStyle(color: DuoColors.error, fontSize: 12)),
      ],
    );
  }

  Widget _aboutSection() {
    return Column(
      children: [
        _field('Bio', _form.bio, (v) => _form.bio = v, maxLines: 4),
        _field('Looking for', _form.lookingForText, (v) => _form.lookingForText = v, maxLines: 3),
        _field('Future goals', _form.futureGoals, (v) => _form.futureGoals = v, maxLines: 3),
      ],
    );
  }

  Widget _educationSection() {
    return Column(
      children: [
        _field('Education summary', _form.education, (v) => _form.education = v),
        _dropdown(
          'Education level',
          _form.educationLevel,
          enumDropdownOptions(educationLevelOptions),
          (v) => setState(() => _form.educationLevel = v ?? ''),
        ),
        _dropdown(
          'Field of study',
          _form.fieldOfStudy,
          enumDropdownOptions(fieldOfStudyOptions),
          (v) => setState(() => _form.fieldOfStudy = v ?? ''),
        ),
        _field('Occupation', _form.occupation, (v) => _form.occupation = v),
        _field('Company', _form.company, (v) => _form.company = v),
        _dropdown(
          'Monthly income',
          _form.monthlyIncome,
          enumDropdownOptions(incomeOptions),
          (v) => setState(() => _form.monthlyIncome = v ?? ''),
        ),
      ],
    );
  }

  Widget _backgroundSection() {
    return Column(
      children: [
        _dropdown(
          'Caste',
          _form.caste,
          casteOptions.map((e) => (e, e)).toList(),
          (v) => setState(() => _form.caste = v ?? ''),
        ),
        _dropdown(
          'Gotra',
          _form.gotra,
          gotraOptions.map((e) => (e, e)).toList(),
          (v) => setState(() => _form.gotra = v ?? ''),
        ),
        _dropdown(
          'Horoscope',
          _form.horoscope,
          enumDropdownOptions(horoscopeOptions),
          (v) => setState(() => _form.horoscope = v ?? ''),
        ),
        _field('Birth time', _form.birthTime, (v) => _form.birthTime = v),
        _field('Birth place', _form.birthPlace, (v) => _form.birthPlace = v),
      ],
    );
  }

  Widget _lifestyleSection() {
    return _field(
      'Lifestyle tags (comma separated)',
      _form.lifestyleTagsText,
      (v) => _form.lifestyleTagsText = v,
      maxLines: 2,
    );
  }

  Widget _preferencesSection() {
    return Column(
      children: [
        _dropdown(
          'Show me',
          _form.prefGender,
          profilePrefGenderOptions,
          (v) => setState(() => _form.prefGender = v ?? 'everyone'),
        ),
        Row(
          children: [
            Expanded(child: Text('Age ${_form.prefAgeMin} – ${_form.prefAgeMax}')),
          ],
        ),
        RangeSlider(
          values: RangeValues(_form.prefAgeMin.toDouble(), _form.prefAgeMax.toDouble()),
          min: 18,
          max: 60,
          divisions: 42,
          onChanged: (v) => setState(() {
            _form.prefAgeMin = v.start.round();
            _form.prefAgeMax = v.end.round();
          }),
        ),
        _field('Min height', _form.prefMinHeight, (v) => _form.prefMinHeight = v),
        _field('Preferred occupation', _form.prefOccupation, (v) => _form.prefOccupation = v),
        _field('Preferred location', _form.prefLocation, (v) => _form.prefLocation = v),
        Text('Max distance: ${_form.prefMaxDistanceKm} km'),
        Slider(
          value: _form.prefMaxDistanceKm.toDouble(),
          min: 5,
          max: 500,
          divisions: 99,
          onChanged: (v) => setState(() => _form.prefMaxDistanceKm = v.round()),
        ),
        _dropdown(
          'Relationship preference',
          _form.prefRelationshipGoal,
          profileRelationshipGoalOptions,
          (v) => setState(() => _form.prefRelationshipGoal = v ?? 'everyone'),
        ),
        _dropdown(
          'Preferred religion',
          _form.preferredReligion,
          enumDropdownOptions(religionOptions),
          (v) => setState(() => _form.preferredReligion = v ?? ''),
        ),
        _dropdown(
          'Inter-caste',
          _form.interCaste,
          enumDropdownOptions(marriagePrefOptions),
          (v) => setState(() => _form.interCaste = v ?? ''),
        ),
        _dropdown(
          'Inter-religion',
          _form.interReligion,
          enumDropdownOptions(marriagePrefOptions),
          (v) => setState(() => _form.interReligion = v ?? ''),
        ),
        SwitchListTile(
          title: const Text('Verified profiles only'),
          value: _form.prefVerifiedOnly,
          onChanged: (v) => setState(() => _form.prefVerifiedOnly = v),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<(String, String)> options,
    ValueChanged<String?> onChanged,
  ) {
    final resolved = resolveDropdownValue(value, options);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: resolved,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
