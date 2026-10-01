import 'package:flutter/material.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/profile_domain.dart';

/// Profile page pieces mirroring web `/profile`: completeness checklist,
/// verify / preferences / account cards and editable data sections.

const _sectionIcons = {
  'Photos': Icons.photo_library_outlined,
  'Personal': Icons.person_outline,
  'Religion & Background': Icons.temple_hindu_outlined,
  'Education & Career': Icons.school_outlined,
  'Lifestyle & Interests': Icons.style_outlined,
  'About': Icons.format_quote_outlined,
  'Verification': Icons.verified_user_outlined,
};

/// Web "Profile Completeness" card with the backend checklist grouped by section.
class ProfileCompletenessChecklist extends StatelessWidget {
  const ProfileCompletenessChecklist({super.key, required this.profile, required this.onOpenSection});

  final DuoProfile profile;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = <String, List<ProfileChecklistItem>>{};
    for (final item in profile.profileChecklist) {
      groups.putIfAbsent(item.section, () => []).add(item);
    }
    final percent = profile.profileCompleteness.clamp(0, 100);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Profile Completeness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Text('$percent%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: scheme.secondaryContainer)),
                  FractionallySizedBox(
                    widthFactor: percent / 100,
                    child: DecoratedBox(decoration: BoxDecoration(gradient: context.duo.brandGradient)),
                  ),
                ],
              ),
            ),
          ),
          if (groups.isNotEmpty) const SizedBox(height: 16),
          for (final MapEntry(key: name, value: items) in groups.entries)
            _ChecklistRow(name: name, items: items, onTap: () => onOpenSection(name)),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.name, required this.items, required this.onTap});

  final String name;
  final List<ProfileChecklistItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missing = items.where((i) => !i.done).map((i) => i.label).toList();
    final complete = missing.isEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: complete ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              complete ? Icons.check_circle_rounded : (_sectionIcons[name] ?? Icons.add_circle_outline),
              size: 20,
              color: complete ? context.duo.accent : scheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (!complete)
                    Text(
                      'Add ${missing.join(', ').toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            if (!complete) Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Verified badge, or a "Verify your profile" call to action.
class ProfileVerifiedCard extends StatelessWidget {
  const ProfileVerifiedCard({super.key, required this.isVerified, required this.onVerify});

  final bool isVerified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!isVerified) {
      return ProfileActionCard(
        icon: Icons.photo_camera_front_outlined,
        title: 'Verify your profile',
        subtitle: 'Take a selfie to earn a verified badge',
        onTap: onVerify,
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: context.duo.brandBrGradient),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verified Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Selfie verification completed',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable card like web "Discovery preferences" / "Account information".
class ProfileActionCard extends StatelessWidget {
  const ProfileActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web `ProfileDataSection`: title, edit button, and label/value rows or custom content.
class ProfileDataSection extends StatelessWidget {
  const ProfileDataSection({
    super.key,
    required this.title,
    required this.icon,
    required this.onEdit,
    this.fields = const [],
    this.child,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<ProfileField> fields;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (i, field) in fields.indexed) ...[
            if (i > 0) Divider(height: 20, color: scheme.outlineVariant.withValues(alpha: 0.2)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(field.label, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    field.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: field.value == 'Not set' ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}
