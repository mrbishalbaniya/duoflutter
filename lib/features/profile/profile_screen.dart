import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/duo_gradients.dart';
import '../../core/theme/duo_theme.dart';
import '../../widgets/duo_ui.dart';
import 'domain/profile_domain.dart';
import 'profile_edit_screen.dart';
import 'providers/profile_providers.dart';
import 'widgets/profile_completeness_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_lifestyle_card.dart';
import 'widgets/profile_photo_gallery.dart';
import 'widgets/profile_section_card.dart';
import 'widgets/profile_skeleton.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _refresh() async {
    ref.invalidate(profileScreenProvider);
    await ref.read(profileScreenProvider.future);
  }

  Future<void> _openEdit(DuoProfile profile) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProfileEditScreen(initialProfile: profile),
      ),
    );
    if (saved == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = ref.watch(profileScreenProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: screen.when(
        loading: () => const ProfileSkeleton(),
        error: (error, _) => _ProfileErrorState(
          message: error is ApiException ? error.message : '$error',
          onRetry: _refresh,
        ),
        data: (data) {
          final profile = data.profile;
          final user = data.user;
          final sections = buildProfileSections(user, profile);

          return RefreshIndicator(
            onRefresh: _refresh,
            edgeOffset: MediaQuery.paddingOf(context).top,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: profile,
                    onSettings: () {
                      HapticFeedback.selectionClick();
                      context.push(AppRoutes.settings);
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ProfileCompletenessCard(profile: profile),
                      const SizedBox(height: 12),
                      _ProfileVerifyCard(
                        isVerified: profile.isVerified,
                        onVerify: () => context.push(AppRoutes.verify),
                      ),
                      if (profile.isPremium) ...[
                        const SizedBox(height: 12),
                        _PremiumCard(),
                      ],
                      const SizedBox(height: 16),
                      DuoGradientButton(
                        label: 'Edit profile',
                        icon: Icons.edit_outlined,
                        onPressed: () => _openEdit(profile),
                      ),
                      if (sections.photos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ProfilePhotoGallery(
                          photos: sections.photos,
                          heroTagBuilder: (url, index) =>
                              '${profileHeroTag(profile)}-photo-$index',
                        ),
                      ],
                      const SizedBox(height: 16),
                      ProfileSectionCard(
                        title: 'Account',
                        icon: Icons.account_circle_outlined,
                        fields: sections.account,
                      ),
                      ProfileSectionCard(
                        title: 'Personal',
                        icon: Icons.person_outline,
                        fields: sections.personal,
                      ),
                      ProfileSectionCard(
                        title: 'About me',
                        icon: Icons.format_quote_outlined,
                        fields: sections.about,
                      ),
                      ProfileSectionCard(
                        title: 'Education & career',
                        icon: Icons.school_outlined,
                        fields: sections.education,
                      ),
                      ProfileSectionCard(
                        title: 'Religion & background',
                        icon: Icons.temple_hindu_outlined,
                        fields: sections.background,
                      ),
                      ProfileLifestyleCard(tags: sections.lifestyleTags),
                      ProfileSectionCard(
                        title: 'Partner preferences',
                        icon: Icons.favorite_outline,
                        fields: sections.preferences,
                      ),
                      ProfileSectionCard(
                        title: 'Profile status',
                        icon: Icons.verified_outlined,
                        fields: sections.status,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to refresh your profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: DuoColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileVerifyCard extends StatelessWidget {
  const _ProfileVerifyCard({required this.isVerified, required this.onVerify});

  final bool isVerified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: DuoColors.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: DuoGradients.brandBr,
              ),
              child: const Icon(Icons.verified_user, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified profile',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Selfie verification completed',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: DuoColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onVerify,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DuoColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DuoColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera_front_outlined, color: DuoColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your profile',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      'Take a selfie to earn a verified badge',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
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

class _PremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DuoGradients.brandBr,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Duo Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Premium is active on your account',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: scheme.surface),
        ],
      ),
    );
  }
}
