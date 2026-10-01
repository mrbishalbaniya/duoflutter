import 'package:flutter/material.dart';

/// Bottom navigation icon sets. Mirrors DuoFrontend `lib/iconSets.ts`
/// (same ids); order is Discover, Chat, Match, Map, Profile.
@immutable
class NavIconSet {
  const NavIconSet({
    required this.id,
    required this.name,
    required this.premium,
    required this.icons,
  });

  final String id;
  final String name;
  final bool premium;

  /// (outlined, selected) per tab.
  final List<(IconData, IconData)> icons;
}

const duoNavIconSets = <NavIconSet>[
  NavIconSet(
    id: 'classic',
    name: 'Classic',
    premium: false,
    icons: [
      (Icons.group_outlined, Icons.group),
      (Icons.chat_bubble_outline, Icons.chat_bubble),
      (Icons.favorite_border, Icons.favorite),
      (Icons.map_outlined, Icons.map),
      (Icons.person_outline, Icons.person),
    ],
  ),
  NavIconSet(
    id: 'romance',
    name: 'Romance',
    premium: true,
    icons: [
      (Icons.diversity_1_outlined, Icons.diversity_1),
      (Icons.forum_outlined, Icons.forum),
      (Icons.favorite_border, Icons.favorite),
      (Icons.explore_outlined, Icons.explore),
      (Icons.face_outlined, Icons.face),
    ],
  ),
  NavIconSet(
    id: 'cupid',
    name: 'Cupid',
    premium: true,
    icons: [
      (Icons.loyalty_outlined, Icons.loyalty),
      (Icons.sms_outlined, Icons.sms),
      (Icons.volunteer_activism_outlined, Icons.volunteer_activism),
      (Icons.location_on_outlined, Icons.location_on),
      (Icons.account_circle_outlined, Icons.account_circle),
    ],
  ),
  NavIconSet(
    id: 'cosmic',
    name: 'Cosmic',
    premium: true,
    icons: [
      (Icons.travel_explore, Icons.travel_explore),
      (Icons.chat_outlined, Icons.chat),
      (Icons.auto_awesome_outlined, Icons.auto_awesome),
      (Icons.public_outlined, Icons.public),
      (Icons.sentiment_satisfied_outlined, Icons.sentiment_satisfied),
    ],
  ),
  NavIconSet(
    id: 'royal',
    name: 'Royal',
    premium: true,
    icons: [
      (Icons.groups_outlined, Icons.groups),
      (Icons.mail_outline, Icons.mail),
      (Icons.diamond_outlined, Icons.diamond),
      (Icons.near_me_outlined, Icons.near_me),
      (Icons.badge_outlined, Icons.badge),
    ],
  ),
  NavIconSet(
    id: 'nature',
    name: 'Nature',
    premium: true,
    icons: [
      (Icons.forest_outlined, Icons.forest),
      (Icons.spa_outlined, Icons.spa),
      (Icons.local_florist_outlined, Icons.local_florist),
      (Icons.landscape_outlined, Icons.landscape),
      (Icons.emoji_nature_outlined, Icons.emoji_nature),
    ],
  ),
  NavIconSet(
    id: 'playful',
    name: 'Playful',
    premium: true,
    icons: [
      (Icons.celebration_outlined, Icons.celebration),
      (Icons.mood_outlined, Icons.mood),
      (Icons.cookie_outlined, Icons.cookie),
      (Icons.flag_outlined, Icons.flag),
      (Icons.pets_outlined, Icons.pets),
    ],
  ),
];

NavIconSet navIconSetById(String id) =>
    duoNavIconSets.firstWhere((s) => s.id == id, orElse: () => duoNavIconSets.first);
