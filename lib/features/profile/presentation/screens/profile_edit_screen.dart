import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../repositories/photo_repository.dart';
import '../../../auth/auth_controller.dart';
import '../../../match/domain/match_domain.dart';
import '../../../match/providers/match_providers.dart';
import '../../domain/profile_edit_models.dart';
import '../../providers/profile_providers.dart';
import '../profile_edit_validation.dart';
import '../widgets/edit/profile_edit_about_section.dart';
import '../widgets/edit/profile_edit_background_section.dart';
import '../widgets/edit/profile_edit_education_section.dart';
import '../widgets/edit/profile_edit_lifestyle_section.dart';
import '../widgets/edit/profile_edit_personal_section.dart';
import '../widgets/edit/profile_edit_photos_section.dart';
import '../widgets/edit/profile_edit_preferences_section.dart';
import '../widgets/edit/profile_edit_section_tile.dart';
import '../widgets/profile_responsive.dart';

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
  bool _dirty = false;
  double? _uploadProgress;

  String? _saveError;
  String? _locationError;
  String? _photoError;
  Map<String, String?> _fieldErrors = {};

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

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits. Leave without saving?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
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
        _dirty = true;
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
      _uploadProgress = 0;
    });

    try {
      final repo = ref.read(photoRepositoryProvider);
      final remaining = 9 - _form.photos.length;
      final selected = files.take(remaining).toList();
      final uploaded = <ProfileEditPhoto>[];
      final isFirst = _form.photos.isEmpty;

      for (var i = 0; i < selected.length; i++) {
        final file = selected[i];
        final local = File(file.path);
        final isPrimary = isFirst && i == 0;
        setState(() => _uploadProgress = (i / selected.length));
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

      setState(() {
        _form.photos = [..._form.photos, ...uploaded];
        _dirty = true;
        _uploadProgress = 1;
      });
    } catch (e) {
      setState(() => _photoError = e.toString());
    } finally {
      setState(() {
        _analyzingPhotos = false;
        _uploadProgress = null;
      });
    }
  }

  void _removePhoto(String id) {
    final next = _form.photos.where((p) => p.id != id).toList();
    if (next.isNotEmpty && !next.any((p) => p.isProfile)) {
      next[0] = next[0].copyWith(isProfile: true);
    }
    setState(() {
      _form.photos = next;
      _dirty = true;
    });
  }

  void _setProfilePhoto(String id) {
    setState(() {
      _form.photos = _form.photos.map((p) => p.copyWith(isProfile: p.id == id)).toList();
      _dirty = true;
    });
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final next = List<ProfileEditPhoto>.from(_form.photos);
      final item = next.removeAt(oldIndex);
      next.insert(newIndex, item);
      _form.photos = next;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final errors = validateProfileEditForm(_form);
    setState(() => _fieldErrors = errors);
    if (!profileEditFormIsValid(_form)) {
      setState(() => _saveError = 'Please fix the highlighted fields.');
      return;
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
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
    final scheme = Theme.of(context).colorScheme;
    final padding = ProfileResponsive.horizontalPadding(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit profile'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await _confirmDiscard() && mounted) navigator.pop();
            },
          ),
          actions: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _saving
                  ? const Padding(
                      key: ValueKey('saving'),
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('save'),
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 32),
          children: [
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_saveError!, style: TextStyle(color: scheme.error)),
              ),
            ProfileEditSectionTile(
              title: 'Photos',
              subtitle: '${_form.photos.length}/9 uploaded',
              icon: Icons.photo_library_outlined,
              initiallyExpanded: true,
              animationIndex: 0,
              child: ProfileEditPhotosSection(
                photos: _form.photos,
                photoError: _photoError,
                analyzingPhotos: _analyzingPhotos,
                uploadProgress: _uploadProgress,
                onPickPhotos: _pickPhotos,
                onRemovePhoto: _removePhoto,
                onSetPrimary: _setProfilePhoto,
                onReorder: _reorderPhotos,
              ),
            ),
            ProfileEditSectionTile(
              title: 'Basic information',
              icon: Icons.person_outline,
              initiallyExpanded: true,
              animationIndex: 1,
              child: ProfileEditPersonalSection(
                form: _form,
                locationController: _locationController,
                detectingLocation: _detectingLocation,
                locationError: _locationError,
                fieldErrors: _fieldErrors,
                onChanged: _markDirty,
                onDetectLocation: _detectLocation,
              ),
            ),
            ProfileEditSectionTile(
              title: 'About me',
              icon: Icons.format_quote_outlined,
              animationIndex: 2,
              child: ProfileEditAboutSection(form: _form, onChanged: _markDirty),
            ),
            ProfileEditSectionTile(
              title: 'Education & career',
              icon: Icons.school_outlined,
              animationIndex: 3,
              child: ProfileEditEducationSection(form: _form, onChanged: _markDirty),
            ),
            ProfileEditSectionTile(
              title: 'Religion & background',
              icon: Icons.temple_hindu_outlined,
              animationIndex: 4,
              child: ProfileEditBackgroundSection(form: _form, onChanged: _markDirty),
            ),
            ProfileEditSectionTile(
              title: 'Lifestyle & interests',
              icon: Icons.interests_outlined,
              animationIndex: 5,
              child: ProfileEditLifestyleSection(form: _form, onChanged: _markDirty),
            ),
            ProfileEditSectionTile(
              title: 'Discovery preferences',
              icon: Icons.tune_rounded,
              animationIndex: 6,
              child: ProfileEditPreferencesSection(form: _form, onChanged: _markDirty),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      if (await _confirmDiscard() && mounted) navigator.pop();
                    },
              child: const Text('Cancel'),
            ),
          ].animate(interval: 30.ms).fadeIn(duration: 260.ms).slideY(begin: 0.02, end: 0),
        ),
      ),
    );
  }
}
