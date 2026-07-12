import 'package:flutter/material.dart';

import '../../core/theme/duo_theme.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.id,
    required this.title,
    required this.headline,
    required this.body,
    required this.icon,
    required this.accent,
    required this.heroTag,
    this.statLabel,
    this.statValue,
  });

  final String id;
  final String title;
  final String headline;
  final String body;
  final IconData icon;
  final Color accent;
  final String heroTag;
  final String? statLabel;
  final String? statValue;
}

const introOnboardingPages = [
  OnboardingPageData(
    id: 'welcome',
    title: 'Welcome to Duo',
    headline: 'Find your life partner',
    body:
        'Duo blends deep-rooted tradition with intelligent matching for meaningful, lasting connections across Nepal.',
    icon: Icons.favorite_rounded,
    accent: DuoColors.primary,
    heroTag: 'duo_brand_hero',
    statLabel: 'Made in Nepal',
    statValue: 'Kathmandu',
  ),
  OnboardingPageData(
    id: 'discover',
    title: 'Swipe discovery',
    headline: 'Browse with intention',
    body:
        'Experience a fluid, respectful swipe experience designed to make finding matches engaging yet mindful.',
    icon: Icons.swipe_rounded,
    accent: DuoColors.love,
    heroTag: 'onboarding_hero_discover',
    statLabel: 'Verified profiles',
    statValue: '10k+',
  ),
  OnboardingPageData(
    id: 'match',
    title: 'Smart matching',
    headline: 'Compatibility that counts',
    body:
        'Our algorithm weighs cultural, professional, and personal signals so you meet people who truly fit.',
    icon: Icons.auto_awesome_rounded,
    accent: DuoColors.tertiary,
    heroTag: 'onboarding_hero_match',
    statLabel: 'Success rate',
    statValue: '85%',
  ),
  OnboardingPageData(
    id: 'chat',
    title: 'Secure chat',
    headline: 'Connect with confidence',
    body:
        'Private messaging with safety controls, read receipts, and a premium chat experience built for trust.',
    icon: Icons.forum_rounded,
    accent: DuoColors.accent,
    heroTag: 'onboarding_hero_chat',
    statLabel: 'End-to-end',
    statValue: 'Protected',
  ),
];
