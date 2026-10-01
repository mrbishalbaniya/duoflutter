import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../auth/auth_controller.dart';

/// Web `DashboardMenuSheet`: account header, app sections and log out.
Future<void> showMatchMenuSheet(
  BuildContext context, {
  required VoidCallback onOpenFilters,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _MatchMenuSheet(onOpenFilters: onOpenFilters),
  );
}

class _MatchMenuSheet extends ConsumerWidget {
  const _MatchMenuSheet({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;
    final router = GoRouter.of(context);

    void go(String route) {
      Navigator.pop(context);
      router.go(route);
    }

    final items = <(IconData, String, String, VoidCallback)>[
      (Icons.favorite_rounded, 'Match', 'Swipe and like profiles', () => go(AppRoutes.match)),
      (Icons.group_rounded, 'Discover', 'Profile visitors and likes', () => go(AppRoutes.discover)),
      (Icons.chat_bubble_rounded, 'Messages', 'Chat with matches', () => go(AppRoutes.chat)),
      (Icons.map_rounded, 'Map', 'Find people nearby', () => go(AppRoutes.map)),
      (Icons.person_rounded, 'My profile', 'View and edit profile', () => go(AppRoutes.profile)),
      (
        Icons.tune_rounded,
        'Discovery filters',
        'Age, distance, preferences',
        () {
          Navigator.pop(context);
          onOpenFilters();
        },
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.78),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                const Expanded(
                  child: Text(
                    'Menu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.profile.fullName.isNotEmpty ? user.profile.fullName : user.username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (user.email != null)
                          Text(user.email!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Material(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, (icon, label, description, onTap)) in items.indexed) ...[
                        if (i > 0) Divider(height: 1, indent: 52, color: scheme.outlineVariant.withValues(alpha: 0.3)),
                        ListTile(
                          leading: Icon(icon, color: scheme.primary),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(description),
                          trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          onTap: onTap,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authControllerProvider.notifier).logout();
                    router.go(AppRoutes.login);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    backgroundColor: scheme.error.withValues(alpha: 0.1),
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
