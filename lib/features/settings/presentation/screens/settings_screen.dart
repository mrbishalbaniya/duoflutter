import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../widgets/duo_ui.dart';
import '../../../auth/auth_controller.dart';
import '../../../profile/profile_edit_screen.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../domain/settings_domain.dart';
import '../../models/settings_search.dart';
import '../../providers/settings_providers.dart';
import '../../utils/settings_layout.dart';
import '../dialogs/settings_dialogs.dart';
import '../../../update/presentation/sections/settings_update_section.dart';
import '../sections/settings_about_section.dart';
import '../sections/settings_account_section.dart';
import '../sections/settings_appearance_section.dart';
import '../sections/settings_danger_zone_section.dart';
import '../sections/settings_help_section.dart';
import '../sections/settings_language_section.dart';
import '../sections/settings_notifications_section.dart';
import '../sections/settings_privacy_section.dart';
import '../sections/settings_security_section.dart';
import '../sections/settings_storage_section.dart';
import '../widgets/settings_app_bar.dart';
import '../widgets/settings_profile_header.dart';
import '../widgets/settings_search_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  Set<SettingsSectionId> _visibleSections = SettingsSectionId.values.toSet();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visibleSections = SettingsSearchRegistry.matchingSections(query);
    });
  }

  bool _shows(SettingsSectionId id) => _visibleSections.contains(id);

  Future<void> _openEditProfile() async {
    try {
      final loaded = await ref.read(myProfileProvider.future);
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ProfileEditScreen(initialProfile: loaded),
        ),
      );
      if (saved == true) {
        ref.invalidate(myProfileProvider);
      }
    } catch (e) {
      if (!mounted) return;
      final fallback = ref.read(authControllerProvider).user?.profile;
      if (fallback != null) {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => ProfileEditScreen(initialProfile: fallback),
          ),
        );
        if (saved == true) {
          ref.invalidate(myProfileProvider);
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open profile editor: $e')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showLogoutDialog(context);
    if (confirmed != true || !mounted) return;
    HapticFeedback.mediumImpact();
    await ref.read(settingsControllerProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final profile = user?.profile;
    final padding = SettingsLayout.horizontalPadding(context);
    final spacing = SettingsLayout.sectionSpacing(context);
    final twoColumns = SettingsLayout.useTwoColumns(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const SettingsAppBar(),
      body: DuoAmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = _SettingsContent(
                email: user?.email ?? '—',
                balanceLabel: formatWalletBalance(profile?.walletBalance),
                phoneLabel: formatPhoneLabel(profile?.phoneCountryCode, profile?.phoneNumber),
                username: profile?.username,
                isVerified: profile?.isVerified ?? false,
                spacing: spacing,
                shows: _shows,
                onEditProfile: _openEditProfile,
                onLogout: _confirmLogout,
              );

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 8, padding, SettingsLayout.bottomPadding(context)),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: SettingsLayout.maxContentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (profile != null) ...[
                                SettingsProfileHeader(
                                  profile: profile,
                                  email: user?.email ?? '—',
                                  onTap: () => context.push(AppRoutes.profile),
                                ),
                                SizedBox(height: spacing),
                              ],
                              SettingsSearchBar(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                              ),
                              SizedBox(height: spacing),
                              if (_visibleSections.isEmpty)
                                _EmptySearchState(query: _searchController.text)
                              else if (twoColumns)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: content.leftColumn),
                                    SizedBox(width: SettingsLayout.columnGap(context)),
                                    Expanded(child: content.rightColumn),
                                  ],
                                )
                              else
                                content.singleColumn,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingsContent {
  const _SettingsContent({
    required this.email,
    required this.balanceLabel,
    required this.phoneLabel,
    required this.username,
    required this.isVerified,
    required this.spacing,
    required this.shows,
    required this.onEditProfile,
    required this.onLogout,
  });

  final String email;
  final String balanceLabel;
  final String phoneLabel;
  final String? username;
  final bool isVerified;
  final double spacing;
  final bool Function(SettingsSectionId id) shows;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  Widget _gap() => SizedBox(height: spacing);

  Widget get leftColumn => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shows(SettingsSectionId.account))
            SettingsAccountSection(
              email: email,
              username: username,
              phoneLabel: phoneLabel,
              balanceLabel: balanceLabel,
              isVerified: isVerified,
              onEditProfile: onEditProfile,
              animationIndex: 0,
            ),
          if (shows(SettingsSectionId.account)) _gap(),
          SettingsAppearanceSection(animationIndex: 1, visible: shows(SettingsSectionId.appearance)),
          if (shows(SettingsSectionId.appearance)) _gap(),
          SettingsNotificationsSection(animationIndex: 2, visible: shows(SettingsSectionId.notifications)),
          if (shows(SettingsSectionId.notifications)) _gap(),
          SettingsPrivacySection(
            onEditProfile: onEditProfile,
            animationIndex: 3,
            visible: shows(SettingsSectionId.privacy),
          ),
        ],
      );

  Widget get rightColumn => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSecuritySection(animationIndex: 4, visible: shows(SettingsSectionId.security)),
          if (shows(SettingsSectionId.security)) _gap(),
          SettingsStorageSection(animationIndex: 5, visible: shows(SettingsSectionId.storage)),
          if (shows(SettingsSectionId.storage)) _gap(),
          SettingsLanguageSection(animationIndex: 6, visible: shows(SettingsSectionId.language)),
          if (shows(SettingsSectionId.language)) _gap(),
          SettingsHelpSection(animationIndex: 7, visible: shows(SettingsSectionId.help)),
          if (shows(SettingsSectionId.help)) _gap(),
          const SettingsUpdateSection(animationIndex: 8),
          _gap(),
          SettingsAboutSection(animationIndex: 9, visible: shows(SettingsSectionId.about)),
          if (shows(SettingsSectionId.about)) _gap(),
          SettingsDangerZoneSection(
            onLogout: onLogout,
            animationIndex: 10,
            visible: shows(SettingsSectionId.danger),
          ),
        ],
      );

  Widget get singleColumn => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          _gap(),
          rightColumn,
        ],
      );
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No settings match "$query"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for theme, notifications, password, or wallet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
