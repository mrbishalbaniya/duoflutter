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
  String? _error;
  bool _savedFlash = false;
  late LocationPrivacySettings _settings;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).user?.profile;
    _settings = profile != null
        ? privacyFromProfile(profile)
        : const LocationPrivacySettings();
  }

  Future<void> _persist(LocationPrivacySettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
      _error = null;
      _savedFlash = false;
    });
    try {
      await ref.read(mapRepositoryProvider).updateLocationPrivacy(next);
      await ref.read(authControllerProvider.notifier).refreshUser();
      ref.invalidate(mapMatchesProvider);
      if (mounted) {
        setState(() {
          _savedFlash = true;
          _saving = false;
        });
        Future<void>.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => _savedFlash = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not save location privacy.';
          _saving = false;
        });
      }
    }
  }

  void _toggleFriend(int userId) {
    final ids = List<int>.from(_settings.visibilityFriendIds);
    if (ids.contains(userId)) {
      ids.remove(userId);
    } else {
      ids.add(userId);
    }
    _persist(_settings.copyWith(visibilityFriendIds: ids));
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(mapMatchesProvider).valueOrNull ?? const <MapProfile>[];
    final scheme = Theme.of(context).colorScheme;
    final ghostMode = _settings.ghostMode;

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
          subtitle: const Text('When enabled, your friends cannot see your location'),
          value: ghostMode,
          activeThumbColor: DuoColors.primary,
          onChanged: _saving
              ? null
              : (v) => _persist(_settings.copyWith(ghostMode: v)),
        ),
        AnimatedOpacity(
          opacity: ghostMode ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: ghostMode || _saving,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Who can see my location',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                RadioGroup<LocationVisibilityMode>(
                  groupValue: _settings.visibility,
                  onChanged: (v) {
                    if (v == null) return;
                    _persist(
                      _settings.copyWith(
                        visibility: v,
                        visibilityFriendIds:
                            v == LocationVisibilityMode.friends ? const [] : _settings.visibilityFriendIds,
                      ),
                    );
                  },
                  child: Column(
                    children: LocationVisibilityMode.values.map((mode) {
                      final meta = _visibilityMeta(mode);
                      return RadioListTile<LocationVisibilityMode>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(meta.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(meta.$2),
                        value: mode,
                        activeColor: DuoColors.primary,
                      );
                    }).toList(),
                  ),
                ),
                if (_settings.visibility != LocationVisibilityMode.friends) ...[
                  const SizedBox(height: 4),
                  Text(
                    _settings.visibility == LocationVisibilityMode.friendsExcept
                        ? 'Selected friends will not see your location'
                        : 'Only selected friends will see your location',
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
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12)),
          )
        else if (_savedFlash)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Saved',
              style: TextStyle(color: DuoColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          )
        else if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
