import 'package:flutter/material.dart';

import '../../../../core/models/user_models.dart';
import '../../domain/profile_domain.dart';
import 'profile_lifestyle_card.dart';
import 'profile_section_card.dart';

class ProfileContentSections extends StatelessWidget {
  const ProfileContentSections({
    super.key,
    required this.user,
    required this.profile,
    required this.sections,
  });

  final DuoUser user;
  final DuoProfile profile;
  final ProfileSections sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final cards = <Widget>[
          if (sections.about.any((f) => f.value != 'Not set' && f.value != 'No bio yet'))
            ProfileSectionCard(
              title: 'About me',
              icon: Icons.format_quote_outlined,
              fields: sections.about,
              initiallyExpanded: true,
              animationIndex: 0,
            ),
          ProfileSectionCard(
            title: 'Personal',
            icon: Icons.person_outline,
            fields: sections.personal,
            animationIndex: 1,
          ),
          ProfileSectionCard(
            title: 'Education & career',
            icon: Icons.school_outlined,
            fields: sections.education,
            animationIndex: 2,
          ),
          ProfileSectionCard(
            title: 'Religion & background',
            icon: Icons.temple_hindu_outlined,
            fields: sections.background,
            animationIndex: 3,
          ),
          ProfileLifestyleCard(tags: sections.lifestyleTags, animationIndex: 4),
          ProfileSectionCard(
            title: 'Partner preferences',
            icon: Icons.favorite_outline,
            fields: sections.preferences,
            animationIndex: 5,
          ),
          ProfileSectionCard(
            title: 'Account',
            icon: Icons.account_circle_outlined,
            fields: sections.account,
            animationIndex: 6,
          ),
          ProfileSectionCard(
            title: 'Profile status',
            icon: Icons.verified_outlined,
            fields: sections.status,
            animationIndex: 7,
          ),
        ];

        if (!wide) {
          return Column(children: cards);
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
