import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/profile_providers.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/profile_web_sections.dart';
import 'profile_edit_screen.dart';
import '../../../match/widgets/match_profile_detail_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _refresh() async {
    ref.invalidate(profileScreenProvider);
    try {
      await ref.read(profileScreenProvider.future);
    } catch (_) {
      // The error state (with Retry) is rendered by the provider's `.when`.
    }
  }

  /// Opens the editor; [section] edits just that part, like web per-section edit.
  Future<void> _openEdit(DuoProfile profile, {String? section}) async {
    HapticFeedback.lightImpact();
    final saved = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: ProfileEditScreen(initialProfile: profile, onlySection: section),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Same iOS grouped look as viewing someone else's profile.
    final pageBg = dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardBg = dark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      body: screen.when(
        loading: () => const ProfileSkeleton(),
        error: (error, _) => _ProfileErrorState(
          message: error is ApiException ? error.message : '$error',
          onRetry: _refresh,
        ),
        data: (data) {
          final profile = data.profile;
          final muted = scheme.onSurfaceVariant;

          Widget row(IconData icon, String label, VoidCallback onTap, {String? value}) => InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 18, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
                        if (value != null)
                          Text(value, style: TextStyle(fontSize: 15, color: muted)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: muted.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ),
              );
          Widget divider() => Padding(
                padding: const EdgeInsets.only(left: 58),
                child: Divider(height: 1, thickness: 0.5, color: muted.withValues(alpha: 0.25)),
              );
          Widget group(List<Widget> rows) => Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[if (i > 0) divider(), rows[i]],
                  ],
                ),
              );

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Navbar: Settings · First name · Edit
                SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.push(AppRoutes.settings);
                          },
                          icon: Icon(Icons.settings_outlined, color: muted),
                        ),
                        Expanded(
                          child: Text(
                            profile.displayName.split(' ').first,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openEdit(profile),
                          child: Text(
                            'Edit',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ProfileDetailList(
                      profile: profile,
                      bottomPadding: 110,
                      footer: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: ProfileCompletenessChecklist(
                            profile: profile,
                            onOpenSection: (section) => section == 'Verification'
                                ? context.push(AppRoutes.verify)
                                : _openEdit(profile, section: section),
                          ),
                        ),
                        group([
                          row(Icons.edit_outlined, 'Edit profile', () => _openEdit(profile)),
                          row(Icons.photo_library_outlined, 'Photos', () => _openEdit(profile, section: 'Photos')),
                          row(
                            profile.isVerified ? Icons.verified : Icons.verified_outlined,
                            'Verification',
                            () => context.push(AppRoutes.verify),
                            value: profile.isVerified ? 'Verified' : 'Not verified',
                          ),
                        ]),
                        group([
                          row(Icons.tune_rounded, 'Discovery preferences', () => context.push(AppRoutes.matchPreferences)),
                          row(Icons.person_outline, 'Account information', () => context.push(AppRoutes.account)),
                          row(Icons.settings_outlined, 'Settings', () => context.push(AppRoutes.settings)),
                        ]),
                      ],
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
