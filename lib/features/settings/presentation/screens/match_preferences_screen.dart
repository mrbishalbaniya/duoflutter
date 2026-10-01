import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/auth_controller.dart';
import '../../../match/domain/match_domain.dart';
import '../../../profile/domain/profile_edit_models.dart';
import '../../../profile/presentation/widgets/edit/profile_edit_preferences_section.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../../match/providers/match_providers.dart';

/// Profile keys the web "Match preferences" page saves.
const _prefKeys = {
  'pref_gender',
  'pref_age_min',
  'pref_age_max',
  'pref_min_height',
  'pref_occupation',
  'pref_location',
  'pref_max_distance_km',
  'pref_relationship_goal',
  'pref_verified_only',
  'pref_values',
};

/// Mirrors the web `/preferences` page: partner preferences that shape Match.
class MatchPreferencesScreen extends ConsumerStatefulWidget {
  const MatchPreferencesScreen({super.key});

  @override
  ConsumerState<MatchPreferencesScreen> createState() => _MatchPreferencesScreenState();
}

class _MatchPreferencesScreenState extends ConsumerState<MatchPreferencesScreen> {
  DuoProfile? _profile;
  ProfileEditFormData? _form;
  bool _dirty = false;
  bool _saving = false;
  bool _saved = false;
  // Bumped to rebuild the fields after discard/reset so text fields reseed.
  int _formVersion = 0;

  @override
  void initState() {
    super.initState();
    final seed = ref.read(authControllerProvider).user?.profile;
    if (seed != null) _setProfile(seed);
    ref.read(myProfileProvider.future).then((fresh) {
      if (mounted && !_dirty) setState(() => _setProfile(fresh));
    }).catchError((_) {
      // Keep the profile seeded from auth state.
    });
  }

  void _setProfile(DuoProfile profile) {
    _profile = profile;
    _form = profileToEditForm(profile);
    _formVersion++;
  }

  void _markDirty() => setState(() {
        _dirty = true;
        _saved = false;
      });

  Future<void> _save() async {
    final form = _form;
    final profile = _profile;
    if (form == null || profile == null) return;
    setState(() => _saving = true);
    try {
      final full = await buildProfileUpdatePayload(
        form: form,
        existing: profile,
        photoRepo: ref.read(photoRepositoryProvider),
      );
      final payload = {
        for (final e in full.entries)
          if (_prefKeys.contains(e.key)) e.key: e.value,
      };
      final updated = await ref.read(profileRepositoryProvider).updateProfile(payload);
      ref.invalidate(myProfileProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      // Apply the new preferences to the Match deck now, not on next refresh.
      unawaited(ref.read(matchDeckControllerProvider.notifier).reloadForNewPreferences());
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _setProfile(updated);
        _dirty = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : 'Could not save your preferences.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _discard() {
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _setProfile(profile);
      _dirty = false;
    });
  }

  /// Fills in the recommended defaults; nothing is saved until Save.
  void _resetToDefaults() {
    final form = _form;
    if (form == null) return;
    const d = DiscoveryFilters.defaults;
    setState(() {
      form
        ..prefGender = d.prefGender
        ..prefAgeMin = d.prefAgeMin
        ..prefAgeMax = d.prefAgeMax
        ..prefMaxDistanceKm = d.prefMaxDistanceKm
        ..prefRelationshipGoal = d.prefRelationshipGoal
        ..prefVerifiedOnly = d.prefVerifiedOnly
        ..prefLocation = ''
        ..prefMinHeight = ''
        ..prefOccupation = ''
        ..preferredReligion = ''
        ..interReligion = 'yes'
        ..preferredCaste = ''
        ..interCaste = 'yes'
        ..preferredRashi = '';
      _formVersion++;
      _dirty = true;
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved preferences. Leave without saving?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
            ],
          ),
        );
        if (leave == true) {
          setState(() => _dirty = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Match Preferences')),
        body: form == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text('Partner Preferences', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    "Tell us who you'd like to meet. These preferences shape who appears in Match.",
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: ValueKey(_formVersion),
                    child: ProfileEditPreferencesSection(form: form, onChanged: _markDirty),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: !_dirty || _saving ? null : _discard,
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: !_dirty || _saving ? null : _save,
                          child: Text(_saving
                              ? 'Saving…'
                              : _saved && !_dirty
                                  ? 'Saved'
                                  : 'Save preferences'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.match),
                      child: const Text('Back to Match'),
                    ),
                  ),
                  const Divider(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: _saving ? null : _resetToDefaults,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reset to recommended'),
                    ),
                  ),
                  Text(
                    'Fills in the default preferences. Press Save to keep them.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
      ),
    );
  }
}
