import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../auth/auth_controller.dart';
import '../domain/map_domain.dart';
import '../map_models.dart';
import '../providers/map_providers.dart';

LocationPrivacySettings privacyFromProfile(DuoProfile profile) {
  return LocationPrivacySettings(
    ghostMode: profile.locationGhostMode,
    visibility: LocationVisibilityModeApi.fromApi(profile.locationVisibility),
    visibilityFriendIds: profile.locationVisibilityFriends,
  );
}

class LocationPrivacySection extends ConsumerStatefulWidget {
  const LocationPrivacySection({super.key});

  @override
  ConsumerState<LocationPrivacySection> createState() =>
      _LocationPrivacySectionState();
}

class _LocationPrivacySectionState extends ConsumerState<LocationPrivacySection> {
  bool _saving = false;
  late LocationPrivacySettings _settings;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).user?.profile;
    _settings = profile != null
        ? privacyFromProfile(profile)
        : const LocationPrivacySettings();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(mapRepositoryProvider).updateLocationPrivacy(_settings);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location privacy updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleFriend(int userId) {
    final ids = List<int>.from(_settings.visibilityFriendIds);
    if (ids.contains(userId)) {
      ids.remove(userId);
    } else {
      ids.add(userId);
    }
    setState(() => _settings = _settings.copyWith(visibilityFriendIds: ids));
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(mapMatchesProvider).valueOrNull ?? const <MapProfile>[];
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location privacy',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: DuoColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ghost mode', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Hide your location from everyone on the map'),
          value: _settings.ghostMode,
          activeThumbColor: DuoColors.primary,
          onChanged: (v) => setState(() => _settings = _settings.copyWith(ghostMode: v)),
        ),
        const SizedBox(height: 4),
        ...LocationVisibilityMode.values.map((mode) {
          final meta = _visibilityMeta(mode);
          return RadioListTile<LocationVisibilityMode>(
            contentPadding: EdgeInsets.zero,
            title: Text(meta.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(meta.$2),
            value: mode,
            groupValue: _settings.visibility,
            activeColor: DuoColors.primary,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _settings = _settings.copyWith(visibility: v));
            },
          );
        }),
        if (_settings.visibility != LocationVisibilityMode.friends) ...[
          const SizedBox(height: 4),
          Text(
            _settings.visibility == LocationVisibilityMode.friendsExcept
                ? 'Hidden from selected friends'
                : 'Visible only to selected friends',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in matches)
                  if (item.profile.userId != null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _settings.visibilityFriendIds
                          .contains(item.profile.userId),
                      onChanged: (_) => _toggleFriend(item.profile.userId!),
                      title: Text(item.profile.displayName),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save privacy settings'),
        ),
      ],
    );
  }

  (String, String) _visibilityMeta(LocationVisibilityMode mode) => switch (mode) {
        LocationVisibilityMode.friends => (
            'My friends',
            'All matches can see your location',
          ),
        LocationVisibilityMode.friendsExcept => (
            'My friends, except…',
            'Hide from selected matches',
          ),
        LocationVisibilityMode.onlyThese => (
            'Only these friends',
            'Only selected matches can see you',
          ),
      };
}
