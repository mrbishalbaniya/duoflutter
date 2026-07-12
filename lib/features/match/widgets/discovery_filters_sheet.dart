import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../../auth/auth_controller.dart';
import '../domain/match_domain.dart';
import '../providers/match_providers.dart';

Future<void> showDiscoveryFiltersSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final profile = ref.read(authControllerProvider).user?.profile;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DiscoveryFiltersSheet(initialProfile: profile),
  );
}

class DiscoveryFiltersSheet extends ConsumerStatefulWidget {
  const DiscoveryFiltersSheet({super.key, this.initialProfile});

  final DuoProfile? initialProfile;

  @override
  ConsumerState<DiscoveryFiltersSheet> createState() =>
      _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends ConsumerState<DiscoveryFiltersSheet> {
  late int _ageMin;
  late int _ageMax;
  late String _location;
  late int _maxDistance;
  late String _gender;
  late String _relationshipGoal;
  late bool _verifiedOnly;
  bool _saving = false;
  bool _detecting = false;
  String? _saveError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadFromProfile(widget.initialProfile);
  }

  void _loadFromProfile(DuoProfile? profile) {
    final filters = profile != null
        ? DiscoveryFilters.fromProfile(profile)
        : DiscoveryFilters.defaults;
    _ageMin = filters.prefAgeMin;
    _ageMax = filters.prefAgeMax;
    _location = filters.prefLocation;
    _maxDistance = filters.prefMaxDistanceKm;
    _gender = filters.prefGender;
    _relationshipGoal = filters.prefRelationshipGoal;
    _verifiedOnly = filters.prefVerifiedOnly;
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _locationError = null;
    });
    try {
      final detected = await ref.read(matchLocationServiceProvider).detectUserLocation();
      setState(() => _location = detected.city);
    } catch (e) {
      setState(() => _locationError = e.toString());
    } finally {
      setState(() => _detecting = false);
    }
  }

  Future<void> _apply() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final min = _ageMin < _ageMax ? _ageMin : _ageMax;
      final max = _ageMin > _ageMax ? _ageMin : _ageMax;
      await ref.read(matchDeckControllerProvider.notifier).applyFilters(
            DiscoveryFilters(
              prefAgeMin: min,
              prefAgeMax: max,
              prefLocation: _location,
              prefMaxDistanceKm: _maxDistance,
              prefGender: _gender,
              prefRelationshipGoal: _relationshipGoal,
              prefVerifiedOnly: _verifiedOnly,
            ),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    const d = DiscoveryFilters.defaults;
    setState(() {
      _ageMin = d.prefAgeMin;
      _ageMax = d.prefAgeMax;
      _location = d.prefLocation;
      _maxDistance = d.prefMaxDistanceKm;
      _gender = d.prefGender;
      _relationshipGoal = d.prefRelationshipGoal;
      _verifiedOnly = d.prefVerifiedOnly;
      _saveError = null;
      _locationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ageMin = _ageMin < _ageMax ? _ageMin : _ageMax;
    final ageMax = _ageMin > _ageMax ? _ageMin : _ageMax;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Expanded(
                      child: Text(
                        'Filters',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _apply,
                      child: Text(_saving ? 'Saving…' : 'Apply'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (_saveError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_saveError!, style: TextStyle(color: scheme.error)),
                      ),
                    _Section(
                      title: 'LOCATION',
                      child: ListTile(
                        onTap: _detecting ? null : _detectLocation,
                        leading: Icon(
                          Icons.my_location_rounded,
                          color: DuoColors.primary,
                        ),
                        title: Text(_detecting ? 'Detecting location…' : 'Use current location'),
                        subtitle: Text(
                          _location.isNotEmpty
                              ? 'Near ${formatLocationLabel(_location)}'
                              : 'Auto-fill city from GPS',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_locationError!, style: TextStyle(color: scheme.error)),
                      ),
                    _Section(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Age'),
                            trailing: Text(
                              '$ageMin – $ageMax',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: DuoColors.primary,
                              ),
                            ),
                          ),
                          RangeSlider(
                            values: RangeValues(ageMin.toDouble(), ageMax.toDouble()),
                            min: 18,
                            max: 60,
                            divisions: 42,
                            onChanged: (v) => setState(() {
                              _ageMin = v.start.round();
                              _ageMax = v.end.round();
                            }),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Distance'),
                            trailing: Text(
                              '$_maxDistance km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: DuoColors.primary,
                              ),
                            ),
                          ),
                          Slider(
                            value: _maxDistance.toDouble(),
                            min: 5,
                            max: 500,
                            divisions: 99,
                            label: '$_maxDistance km',
                            onChanged: (v) => setState(() => _maxDistance = v.round()),
                          ),
                        ],
                      ),
                    ),
                    _Section(
                      title: 'SHOW ME',
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'women', label: Text('Women')),
                            ButtonSegment(value: 'men', label: Text('Men')),
                            ButtonSegment(value: 'everyone', label: Text('Everyone')),
                          ],
                          selected: {_gender},
                          onSelectionChanged: (s) => setState(() => _gender = s.first),
                        ),
                      ),
                    ),
                    _Section(
                      title: 'RELATIONSHIP GOALS',
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in const [
                              ('serious', 'Serious'),
                              ('casual', 'Casual'),
                              ('dating', 'Dating'),
                              ('everyone', 'Everyone'),
                            ])
                              FilterChip(
                                label: Text(entry.$2),
                                selected: _relationshipGoal == entry.$1,
                                onSelected: (_) =>
                                    setState(() => _relationshipGoal = entry.$1),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _Section(
                      child: SwitchListTile(
                        title: const Text('Verified profiles only'),
                        subtitle: const Text('Show people with verified IDs'),
                        value: _verifiedOnly,
                        onChanged: (v) => setState(() => _verifiedOnly = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Reset to recommended defaults'),
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

class _Section extends StatelessWidget {
  const _Section({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
