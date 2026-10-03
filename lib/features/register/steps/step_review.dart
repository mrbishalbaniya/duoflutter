import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/media/media_url.dart';
import '../../../core/theme/duo_gradients.dart';
import '../../../core/widgets/osm_map_preview.dart';
import '../registration_constants.dart';
import '../registration_controller.dart';
import '../registration_models.dart';
import '../registration_validators.dart';
import '../widgets/registration_widgets.dart';

/// "Kathmandu Metropolitan City" -> "Kathmandu", "Bagamati Province" -> "Bagamati".
String _shortPlace(String value) => value
    .replaceAll(
      RegExp(r'\s+(Sub-?Metropolitan City|Metropolitan City|Rural Municipality|Municipality|Province|District)$',
          caseSensitive: false),
      '',
    )
    .trim();

String _shortAddress(RegistrationData d) {
  final parts = <String>[];
  for (final p in [d.municipality, d.province, d.country].map(_shortPlace)) {
    if (p.isNotEmpty && !parts.any((x) => x.toLowerCase() == p.toLowerCase())) parts.add(p);
  }
  if (parts.isNotEmpty) return parts.join(', ');
  return d.currentLocation.isEmpty ? '—' : d.currentLocation;
}

int _heightCm(RegistrationData d) {
  final feet = int.tryParse('${d.heightFeet}') ?? 0;
  final inches = int.tryParse('${d.heightInches}') ?? 0;
  return ((feet * 12 + inches) * 2.54).round();
}

/// Local file when it still exists (fast, offline), otherwise the uploaded URL.
Widget _photoImage(RegistrationPhoto photo, ColorScheme scheme) {
  final path = photo.localPath;
  if (path != null && File(path).existsSync()) return Image.file(File(path), fit: BoxFit.cover);
  final url = resolveMediaUrl(photo.imageUrl);
  if (url != null && url.isNotEmpty) {
    return Image.network(url, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surfaceContainerHighest));
  }
  return ColoredBox(color: scheme.surfaceContainerHighest);
}

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
    final photos = data.photos.where((p) => p.status == RegistrationPhotoStatus.approved).toList();
    final profilePhoto = photos.where((p) => p.isProfile).firstOrNull ?? photos.firstOrNull;
    final age = calculateAgeFromDob(data.dateOfBirth);
    final dob = DateTime.tryParse(data.dateOfBirth);
    final name = '${data.firstName} ${data.lastName}'.trim();

    return RegistrationStepCard(
      title: 'Review your profile',
      subtitle: 'This is how others will first see you. Check everything, then start matching.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfilePreview(
            photo: profilePhoto,
            name: name.isEmpty ? 'Your name' : name,
            age: age > 0 ? age : null,
            place: _shortAddress(data),
            goal: data.relationshipGoal.isEmpty ? null : labelForOption(relationshipGoalOptions, data.relationshipGoal),
            onEditPhotos: () => onEditStep(3),
          ),
          const SizedBox(height: 16),
          _ReviewSection(
            icon: Icons.person_outline_rounded,
            title: 'About you',
            onEdit: () => onEditStep(2),
            children: [
              _ReviewRow(icon: Icons.badge_outlined, label: 'Name', value: name),
              _ReviewRow(icon: Icons.wc_rounded, label: 'Gender', value: labelForOption(genderOptions, data.gender)),
              _ReviewRow(
                icon: Icons.cake_outlined,
                label: 'Birthday',
                value: dob == null ? '—' : '${DateFormat('MMM d, yyyy').format(dob)} · $age yrs',
              ),
              _ReviewRow(
                icon: Icons.height_rounded,
                label: 'Height',
                value: "${data.heightFeet}'${data.heightInches}\" (${_heightCm(data)} cm)",
              ),
              _ReviewRow(
                icon: Icons.favorite_border_rounded,
                label: 'Marital status',
                value: labelForOption(maritalStatusOptions, data.maritalStatus),
              ),
              _ReviewRow(
                icon: Icons.flag_outlined,
                label: 'Looking for',
                value: labelForOption(relationshipGoalOptions, data.relationshipGoal),
                last: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewSection(
            icon: Icons.place_outlined,
            title: 'Location',
            onEdit: () => onEditStep(2),
            children: [
              if (data.latitude != null && data.longitude != null && (data.latitude != 0 || data.longitude != 0)) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: OsmMapPreview(lat: data.latitude!, lng: data.longitude!, height: 120, zoom: 13),
                ),
                const SizedBox(height: 10),
              ],
              _ReviewRow(icon: Icons.location_city_rounded, label: 'Area', value: _shortAddress(data), last: true),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Only your area is shown to others, never your exact address.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewSection(
            icon: Icons.lock_outline_rounded,
            title: 'Account',
            onEdit: data.signedUpWithGoogle ? null : () => onEditStep(1),
            children: [
              _ReviewRow(
                icon: data.signedUpWithGoogle ? Icons.g_mobiledata_rounded : Icons.alternate_email_rounded,
                label: 'Email',
                value: data.email.isEmpty ? 'Not provided' : data.email,
                trailing: data.otpVerified || data.signedUpWithGoogle ? const _VerifiedChip() : null,
              ),
              _ReviewRow(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile',
                value: data.phone.isEmpty ? '—' : data.phone,
                last: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewSection(
            icon: Icons.photo_library_outlined,
            title: 'Photos',
            subtitle: '${photos.length} of $maxRegistrationPhotos verified',
            onEdit: () => onEditStep(3),
            children: [
              Row(
                children: [
                  for (var i = 0; i < maxRegistrationPhotos; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: i < photos.length
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _photoImage(photos[i], scheme),
                                    if (photos[i].isProfile)
                                      Positioned(
                                        left: 4,
                                        bottom: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: DuoGradients.brand,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text('Main',
                                              style: TextStyle(
                                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
                                  ),
                                  child: Icon(Icons.add_photo_alternate_outlined,
                                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.primary.withValues(alpha: 0.08),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next: complete your profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Add education, religion, lifestyle, interests, partner preferences and a bio '
                  'anytime from your profile. Fuller profiles get better matches.',
                  style: TextStyle(fontSize: 13, height: 1.35, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          RegistrationStepNavigation(
            onBack: onBack,
            onNext: () async {
              HapticFeedback.mediumImpact();
              await onSubmit();
            },
            nextLabel: 'Submit & Start Matching',
            loading: loading,
          ),
        ],
      ),
    );
  }
}

/// Mini version of the match card: main photo, name, age, area and goal.
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.photo,
    required this.name,
    required this.age,
    required this.place,
    required this.goal,
    required this.onEditPhotos,
  });

  final RegistrationPhoto? photo;
  final String name;
  final int? age;
  final String place;
  final String? goal;
  final VoidCallback onEditPhotos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo != null
                ? _photoImage(photo!, scheme)
                : InkWell(
                    onTap: onEditPhotos,
                    child: ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.add_a_photo_outlined, size: 40, color: scheme.onSurfaceVariant),
                    ),
                  ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Preview',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          age == null ? name : '$name, $age',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (photo != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    ],
                  ),
                  if (goal != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: DuoGradients.brand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(goal!,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.15)),
        color: scheme.surfaceContainer.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onEdit!();
                  },
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF22C55E));
  }
}
