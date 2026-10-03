import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../auth/auth_controller.dart';
import '../domain/map_domain.dart';
import '../map_models.dart';
import '../providers/map_providers.dart';
import '../../../core/media/media_url.dart';
import 'friend_picker_screen.dart';

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
    if (_saving) return;
    final previous = _settings;
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
          _settings = previous; // undo: nothing was saved
          _error = 'Could not save. Check your connection and try again.';
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickFriends(
    LocationVisibilityMode mode,
    List<MapProfile> matches, {
    required List<int> initial,
  }) async {
    final except = mode == LocationVisibilityMode.friendsExcept;
    final picked = await showFriendPicker(
      context,
      title: except ? 'Hide my location from' : 'Share my location with',
      subtitle: except
          ? 'Everyone except the people you pick can see your location.'
          : 'Only the people you pick can see your location.',
      friends: matches,
      initialSelected: initial,
    );
    if (picked == null || !mounted) return; // closed: keep the current setting
    await _persist(_settings.copyWith(visibility: mode, visibilityFriendIds: picked));
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
        _GhostModeCard(
          enabled: ghostMode,
          saving: _saving,
          onChanged: (v) {
            HapticFeedback.mediumImpact();
            _persist(_settings.copyWith(ghostMode: v));
          },
        ),
        const SizedBox(height: 12),
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
                    if (v == null || v == _settings.visibility) return;
                    if (v == LocationVisibilityMode.friends) {
                      _persist(_settings.copyWith(visibility: v, visibilityFriendIds: const []));
                    } else {
                      // Switching mode starts a fresh selection.
                      _pickFriends(v, matches, initial: const []);
                    }
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
                  _SelectedFriendsSummary(
                    friends: matches,
                    selectedIds: _settings.visibilityFriendIds,
                    onEdit: () => _pickFriends(
                      _settings.visibility,
                      matches,
                      initial: _settings.visibilityFriendIds,
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

/// Ghost mode toggle: whole card is tappable, state is obvious at a glance,
/// and a spinner replaces the switch while saving.
class _GhostModeCard extends StatelessWidget {
  const _GhostModeCard({required this.enabled, required this.saving, required this.onChanged});

  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: enabled
            ? DuoColors.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? DuoColors.primary.withValues(alpha: 0.45) : scheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: saving ? null : () => onChanged(!enabled),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: enabled ? DuoColors.primary : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    enabled ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: enabled ? Colors.white : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enabled ? 'Ghost mode is on' : 'Ghost mode',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled
                            ? "You're hidden. No one can see your location."
                            : 'Hide your location from everyone on the map.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Switch(
                            value: enabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: DuoColors.primary,
                            onChanged: onChanged,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact summary under the visibility options: overlapping photos, count, Edit.
class _SelectedFriendsSummary extends StatelessWidget {
  const _SelectedFriendsSummary({required this.friends, required this.selectedIds, required this.onEdit});

  final List<MapProfile> friends;
  final List<int> selectedIds;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = [
      for (final f in friends)
        if (f.profile.userId != null && selectedIds.contains(f.profile.userId)) f,
    ];
    final shown = chosen.take(4).toList();
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              if (shown.isEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Icon(Icons.person_add_alt_rounded, size: 18, color: scheme.onSurfaceVariant),
                )
              else
                SizedBox(
                  width: 36.0 + (shown.length - 1) * 22,
                  height: 36,
                  child: Stack(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        Positioned(
                          left: i * 22.0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: scheme.surface,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: scheme.surfaceContainerHighest,
                              foregroundImage: NetworkImage(resolveProfilePhotoUrl(shown[i].profile)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chosen.isEmpty
                      ? 'No one selected yet'
                      : chosen.length == 1
                          ? chosen.first.profile.displayName
                          : '${chosen.first.profile.displayName} and ${chosen.length - 1} more',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(chosen.isEmpty ? 'Choose' : 'Edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
