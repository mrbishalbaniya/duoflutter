import 'package:flutter/material.dart';

import '../../../core/models/user_models.dart';
import 'profile_domain.dart';

/// What another person sees on a profile.
typedef PublicProfile = ({
  String bio,
  String lookingFor,
  String futureGoals,
  List<String> interests,
  List<PublicProfileSection> sections,
});

// ---------------------------------------------------------------- public profile

typedef PublicProfileRow = ({String label, String value, IconData icon});
typedef PublicProfileSection = ({String title, List<PublicProfileRow> rows});

/// "value_like_this" -> "Value like this".
String _label(String? v) {
  final t = (v ?? '').replaceAll('_', ' ').trim();
  if (t.isEmpty) return '';
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

const _personality = {'introvert', 'extrovert', 'ambivert'};
const _lifestyle = {'traditional', 'modern', 'moderate', 'liberal', 'conservative'};
const _goals = {
  'serious': 'Long-term relationship',
  'casual': 'Something casual',
  'dating': 'Dating',
  'marriage': 'Marriage',
  'friendship': 'Friendship',
};

/// Port of web `lib/profile/publicProfile.ts` (what another person sees).
PublicProfile buildPublicProfile(DuoProfile p) {
  final extra = parsePrefValues(p.prefValues);
  final tags = p.lifestyleTags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  final lower = tags.map((t) => t.toLowerCase()).toList();
  String? prefixed(String prefix) =>
      lower.where((t) => t.startsWith('$prefix:')).map((t) => t.substring(prefix.length + 1)).firstOrNull;
  final exercise = lower.where((t) => t.startsWith('exercise:')).map((t) => _label(t.substring(9))).join(', ');
  final interests = tags
      .where((t) => !t.contains(':') && !_personality.contains(t.toLowerCase()) && !_lifestyle.contains(t.toLowerCase()))
      .toList();
  final heightMatch = RegExp(r"""\d'\s*\d{1,2}"?|\d{2,3}\s*cm""", caseSensitive: false).firstMatch(extra.height ?? '');
  final languages = extra.list('languages');

  final sections = <PublicProfileSection>[
    (
      title: 'Basics',
      rows: [
        (label: 'Height', value: heightMatch?.group(0) ?? (extra.height ?? ''), icon: Icons.height),
        (label: 'Marital status', value: _label(prefixed('marital')), icon: Icons.diversity_1),
        (label: 'Looking for', value: _goals[p.relationshipGoal] ?? _label(p.relationshipGoal), icon: Icons.favorite_border),
        (label: 'Languages', value: languages.join(', '), icon: Icons.translate),
      ],
    ),
    (
      title: 'Religion & Background',
      rows: [
        (label: 'Religion', value: _label(p.religion), icon: Icons.temple_hindu_outlined),
        (label: 'Community', value: extra.caste ?? '', icon: Icons.groups_outlined),
        (label: 'Horoscope', value: _label(extra.horoscope), icon: Icons.brightness_7_outlined),
      ],
    ),
    (
      title: 'Education & Career',
      rows: [
        (label: 'Education', value: _label(extra.educationLevel), icon: Icons.school_outlined),
        (label: 'Field of study', value: _label(extra.fieldOfStudy), icon: Icons.menu_book_outlined),
        (label: 'Occupation', value: p.occupation ?? '', icon: Icons.work_outline),
        (label: 'Company', value: extra.company ?? '', icon: Icons.apartment),
        (label: 'Works in', value: formatWorkPreference(p.workPreference) == 'Not set' ? '' : formatWorkPreference(p.workPreference), icon: Icons.business_center_outlined),
      ],
    ),
    (
      title: 'Lifestyle',
      rows: [
        (label: 'Personality', value: _label(lower.where(_personality.contains).firstOrNull), icon: Icons.psychology_outlined),
        (label: 'Lifestyle', value: _label(lower.where(_lifestyle.contains).firstOrNull), icon: Icons.self_improvement),
        (label: 'Smoking', value: _label(prefixed('smoking')), icon: Icons.smoke_free),
        (label: 'Drinking', value: _label(prefixed('drinking')), icon: Icons.local_bar_outlined),
        (label: 'Exercise', value: exercise, icon: Icons.fitness_center),
      ],
    ),
  ]
      .map((s) => (title: s.title, rows: s.rows.where((r) => r.value.trim().isNotEmpty).toList()))
      .where((s) => s.rows.isNotEmpty)
      .toList();

  return (
    bio: (p.bio ?? '').trim(),
    lookingFor: (extra.lookingForText ?? '').trim(),
    futureGoals: (extra.futureGoals ?? '').trim(),
    interests: interests,
    sections: sections,
  );
}
