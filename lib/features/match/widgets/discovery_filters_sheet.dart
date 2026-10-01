import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_models.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_controller.dart';
import '../../map/providers/map_providers.dart';
import '../domain/match_domain.dart';
import '../providers/match_providers.dart';
import '../services/match_location_service.dart';

/// Same limits as web `lib/discoveryFilters.ts`.
const _ageMin = 18;
const _ageMax = 80;
const _distanceMin = 5;
const _distanceMax = 500;
const _distanceStep = 5;

const _genderOptions = [('women', 'Women'), ('men', 'Men'), ('everyone', 'Everyone')];
const _goalOptions = [('everyone', 'Any'), ('serious', 'Serious'), ('dating', 'Dating'), ('casual', 'Casual')];

String _formatDistance(int km) => km >= _distanceMax ? '$_distanceMax+ km' : '$km km';

Future<void> showDiscoveryFiltersSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(authControllerProvider).user?.profile;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DiscoveryFiltersSheet(initialProfile: profile),
  );
}

/// Web `DiscoveryFiltersSheet`: location, distance, age, show me, looking for,
/// verified only, link to all match preferences and "run out" expansions.
class DiscoveryFiltersSheet extends ConsumerStatefulWidget {
  const DiscoveryFiltersSheet({super.key, this.initialProfile});

  final DuoProfile? initialProfile;

  @override
  ConsumerState<DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends ConsumerState<DiscoveryFiltersSheet> {
  late DiscoveryFilters _saved;
  late DiscoveryFilters _draft;
  DetectedLocation? _detected;
  bool _detecting = false;
  bool _saving = false;
  String? _saveError;
  String? _locationError;

  static DiscoveryFilters _clamped(DiscoveryFilters f) {
    final lo = f.prefAgeMin.clamp(_ageMin, _ageMax);
    final hi = f.prefAgeMax.clamp(_ageMin, _ageMax);
    return _copy(
      f,
      prefAgeMin: lo < hi ? lo : hi,
      prefAgeMax: lo < hi ? hi : lo,
      prefMaxDistanceKm: f.prefMaxDistanceKm.clamp(_distanceMin, _distanceMax),
    );
  }

  static DiscoveryFilters _copy(
    DiscoveryFilters f, {
    int? prefAgeMin,
    int? prefAgeMax,
    String? prefLocation,
    int? prefMaxDistanceKm,
    String? prefGender,
    String? prefRelationshipGoal,
    bool? prefVerifiedOnly,
    bool? prefExpandDistance,
    bool? prefExpandAge,
  }) =>
      DiscoveryFilters(
        prefAgeMin: prefAgeMin ?? f.prefAgeMin,
        prefAgeMax: prefAgeMax ?? f.prefAgeMax,
        prefLocation: prefLocation ?? f.prefLocation,
        prefMaxDistanceKm: prefMaxDistanceKm ?? f.prefMaxDistanceKm,
        prefGender: prefGender ?? f.prefGender,
        prefRelationshipGoal: prefRelationshipGoal ?? f.prefRelationshipGoal,
        prefVerifiedOnly: prefVerifiedOnly ?? f.prefVerifiedOnly,
        prefExpandDistance: prefExpandDistance ?? f.prefExpandDistance,
        prefExpandAge: prefExpandAge ?? f.prefExpandAge,
      );

  static bool _equal(DiscoveryFilters a, DiscoveryFilters b) =>
      a.prefAgeMin == b.prefAgeMin &&
      a.prefAgeMax == b.prefAgeMax &&
      a.prefLocation.trim().toLowerCase() == b.prefLocation.trim().toLowerCase() &&
      a.prefMaxDistanceKm == b.prefMaxDistanceKm &&
      a.prefGender == b.prefGender &&
      a.prefRelationshipGoal == b.prefRelationshipGoal &&
      a.prefVerifiedOnly == b.prefVerifiedOnly &&
      a.prefExpandDistance == b.prefExpandDistance &&
      a.prefExpandAge == b.prefExpandAge;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    final base = _clamped(profile != null ? DiscoveryFilters.fromProfile(profile) : DiscoveryFilters.defaults);
    // Distance is always measured from the viewer's own position, so a leftover
    // search city counts as a change and is cleared on apply (same as web).
    _saved = _copy(base, prefLocation: normalizeCityPref(profile?.prefLocation ?? ''));
    _draft = _copy(base, prefLocation: '');
  }

  bool get _dirty => !_equal(_draft, _saved) || _detected != null;

  bool get _atDefaults => _equal(_copy(_draft, prefLocation: ''), DiscoveryFilters.defaults);

  void _update(DiscoveryFilters next) => setState(() {
        _draft = next;
        _saveError = null;
      });

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _locationError = null;
    });
    try {
      final detected = await ref.read(matchLocationServiceProvider).detectUserLocation();
      if (mounted) setState(() => _detected = detected);
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _apply() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final detected = _detected;
      if (detected != null) {
        try {
          await ref.read(mapRepositoryProvider).updateLiveLocation(detected.latitude, detected.longitude);
        } catch (_) {
          // e.g. ghost mode: keep the filters, but say the position wasn't saved.
          messenger.showSnackBar(const SnackBar(content: Text('Could not save your current location.')));
        }
      }
      await ref.read(matchDeckControllerProvider.notifier).applyFilters(_copy(_draft, prefLocation: ''));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      final message = e.toString().isEmpty ? 'Could not save filters. Please try again.' : e.toString();
      if (mounted) setState(() => _saveError = message);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ownCity = normalizeCityPref(widget.initialProfile?.location ?? '');
    final detected = _detected;
    final detectedPlace =
        detected == null ? '' : normalizeCityPref(detected.city.isNotEmpty ? detected.city : detected.label);
    final locationValue = _detecting
        ? 'Locating…'
        : detected != null
            ? (detectedPlace.isNotEmpty ? detectedPlace : 'Current location')
            : (ownCity.isNotEmpty ? ownCity : 'Not set');
    const located = Color(0xFF34C759);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 17)),
                    ),
                    const Expanded(
                      child: Text(
                        'Filters',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _apply,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_dirty ? 'Apply' : 'Done',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    if (_saveError != null) _Note(_saveError!),
                    _Group(children: [
                      _Row(
                        onTap: _detecting ? null : _detectLocation,
                        child: Row(
                          children: [
                            const Expanded(child: _Title('Location')),
                            Flexible(
                              child: Text(
                                locationValue,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: (detected != null ? located : scheme.primary).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: _detecting
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Icon(
                                      detected != null ? Icons.check_rounded : Icons.near_me_rounded,
                                      size: 16,
                                      color: detected != null ? located : scheme.primary,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    if (_locationError != null) _Note(_locationError!),
                    const SizedBox(height: 20),
                    _Group(children: [
                      _Row(
                        child: Column(
                          children: [
                            _Head('Distance', _formatDistance(_draft.prefMaxDistanceKm)),
                            Slider(
                              value: _draft.prefMaxDistanceKm.toDouble(),
                              min: _distanceMin.toDouble(),
                              max: _distanceMax.toDouble(),
                              divisions: (_distanceMax - _distanceMin) ~/ _distanceStep,
                              onChanged: (v) => _update(_copy(_draft, prefMaxDistanceKm: v.round())),
                            ),
                          ],
                        ),
                      ),
                      _Row(
                        child: Column(
                          children: [
                            _Head('Age', '${_draft.prefAgeMin} – ${_draft.prefAgeMax}'),
                            RangeSlider(
                              values: RangeValues(_draft.prefAgeMin.toDouble(), _draft.prefAgeMax.toDouble()),
                              min: _ageMin.toDouble(),
                              max: _ageMax.toDouble(),
                              divisions: _ageMax - _ageMin,
                              onChanged: (v) => _update(
                                _copy(_draft, prefAgeMin: v.start.round(), prefAgeMax: v.end.round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _Group(children: [
                      _Row(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Title('Show me'),
                            const SizedBox(height: 10),
                            _Segmented(
                              options: _genderOptions,
                              value: _draft.prefGender,
                              onChanged: (v) => _update(_copy(_draft, prefGender: v)),
                            ),
                          ],
                        ),
                      ),
                      _Row(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Title('Looking for'),
                            const SizedBox(height: 10),
                            _Segmented(
                              options: _goalOptions,
                              value: _draft.prefRelationshipGoal,
                              onChanged: (v) => _update(_copy(_draft, prefRelationshipGoal: v)),
                            ),
                          ],
                        ),
                      ),
                      _ToggleRow(
                        label: 'Verified profiles only',
                        value: _draft.prefVerifiedOnly,
                        onChanged: (v) => _update(_copy(_draft, prefVerifiedOnly: v)),
                      ),
                    ]),
                    const _Caption('More preferences'),
                    _Group(children: [
                      _Row(
                        onTap: () {
                          final router = GoRouter.of(context);
                          Navigator.pop(context);
                          router.push(AppRoutes.matchPreferences);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _Title('Religion, caste, rashi, height, occupation'),
                                  Text(
                                    'Open all match preferences',
                                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.65)),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ]),
                    const _Caption('If you run out of people nearby'),
                    _Group(children: [
                      _ToggleRow(
                        label: 'Expand distance',
                        value: _draft.prefExpandDistance,
                        onChanged: (v) => _update(_copy(_draft, prefExpandDistance: v)),
                      ),
                      _ToggleRow(
                        label: 'Expand age range',
                        value: _draft.prefExpandAge,
                        onChanged: (v) => _update(_copy(_draft, prefExpandAge: v)),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _atDefaults || _saving
                          ? null
                          : () => _update(_copy(DiscoveryFilters.defaults, prefLocation: '')),
                      child: const Text('Reset to recommended', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// iOS-style inset group (web `dfs-group`).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 1, indent: 16, color: scheme.outlineVariant.withValues(alpha: 0.25)),
            c,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child);
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 16));
}

class _Head extends StatelessWidget {
  const _Head(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Title(title)),
        Text(value, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.error)),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Row(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(child: _Title(label)),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Segmented control with a sliding selection pill (web `Segmented`).
class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.value, required this.onChanged});

  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final index = options.indexWhere((o) => o.$1 == value).clamp(0, options.length - 1);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (v, label) in options)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(v),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: v == value ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
