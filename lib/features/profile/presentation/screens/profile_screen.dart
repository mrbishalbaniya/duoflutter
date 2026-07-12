import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/profile_domain.dart';
import '../../providers/profile_providers.dart';
import '../widgets/profile_completeness_card.dart';
import '../widgets/profile_content_sections.dart';
import '../widgets/profile_edit_fab.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_photo_gallery.dart';
import '../widgets/profile_premium_card.dart';
import '../widgets/profile_responsive.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_verify_card.dart';
import 'profile_edit_screen.dart';

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
      PageRouteBuilder<bool>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: ProfileEditScreen(initialProfile: profile),
        ),
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
    final padding = ProfileResponsive.horizontalPadding(context);
    final avatarRadius = ProfileResponsive.avatarRadius(context);
    final headerOverlap = avatarRadius + 48;

    return Scaffold(
      floatingActionButton: screen.maybeWhen(
        data: (data) => ProfileEditFab(onPressed: () => _openEdit(data.profile)),
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ProfileResponsive.contentMaxWidth(context),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padding, headerOverlap, padding, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ProfileStatsRow(profile: profile),
                            const SizedBox(height: 14),
                            ProfileCompletenessCard(profile: profile),
                            const SizedBox(height: 12),
                            ProfileVerifyCard(
                              isVerified: profile.isVerified,
                              onVerify: () => context.push(AppRoutes.verify),
                            ),
                            if (profile.isPremium) ...[
                              const SizedBox(height: 12),
                              const ProfilePremiumCard(),
                            ],
                            if (sections.photos.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              ProfilePhotoGallery(
                                photos: sections.photos,
                                heroTagBuilder: (url, index) =>
                                    '${profileHeroTag(profile)}-photo-$index',
                              ),
                            ],
                            const SizedBox(height: 16),
                            ProfileContentSections(
                              user: user,
                              profile: profile,
                              sections: sections,
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
                          ],
                        ),
                      ),
                    ),
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
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
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
