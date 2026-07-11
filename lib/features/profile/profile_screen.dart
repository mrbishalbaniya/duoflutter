import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_controller.dart';

final myProfileProvider = FutureProvider.autoDispose<DuoProfile>((ref) async {
  return ref.read(profileRepositoryProvider).getMyProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (p) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x66E84A7A), Color(0x668B5CF6)],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: p.displayPhoto.isNotEmpty
                              ? CachedNetworkImageProvider(p.displayPhoto)
                              : null,
                          child: p.displayPhoto.isEmpty ? const Icon(Icons.person, size: 48) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (p.location != null)
                                Text(
                                  p.location!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoCard(
                      title: 'Profile completeness',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: p.profileCompleteness / 100),
                          const SizedBox(height: 8),
                          Text('${p.profileCompleteness}% complete'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (p.isPremium)
                      _InfoCard(
                        title: 'Premium',
                        child: const Text('Duo Premium is active'),
                      ),
                    if (!p.isVerified)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Verify your profile'),
                        subtitle: const Text('Earn a verified badge'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.verify),
                      ),
                    if (p.bio != null && p.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(title: 'About', child: Text(p.bio!)),
                    ],
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Account',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user?.email ?? p.email ?? '—'}'),
                          Text('Username: ${user?.username ?? p.username ?? '—'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
      });
      ref.invalidate(myProfileProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const Text('Saving…') : const Text('Save'),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) {
          if (_bioController.text.isEmpty && (p.bio?.isNotEmpty ?? false)) {
            _bioController.text = p.bio!;
          }
          if (_locationController.text.isEmpty && (p.location?.isNotEmpty ?? false)) {
            _locationController.text = p.location!;
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
