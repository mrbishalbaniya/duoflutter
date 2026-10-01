import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/duo_network_image.dart';
import '../../../repositories/support_repository.dart';
import '../support_providers.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final Set<int> _pending = {};

  Future<void> _unblock(BlockedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${user.displayName}?'),
        content: const Text('They will be able to find you and message you again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unblock')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _pending.add(user.id));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(supportRepositoryProvider).unblockUser(user.id);
      ref.invalidate(blockedUsersProvider);
      messenger.showSnackBar(SnackBar(content: Text('${user.displayName} unblocked')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pending.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(blockedUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(blockedUsersProvider.future).then((_) {}, onError: (_) {}),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                e is ApiException ? e.message : 'Could not load blocked users.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  Icon(Icons.block_outlined, size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    "You haven't blocked anyone",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text('People you block will appear here.', textAlign: TextAlign.center),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) {
                final user = users[i];
                final busy = _pending.contains(user.id);
                final initial = user.displayName.isEmpty ? '?' : user.displayName.characters.first.toUpperCase();
                return ListTile(
                  leading: ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: user.photoUrl.isEmpty
                          ? CircleAvatar(child: Text(initial))
                          : DuoNetworkImage(url: user.photoUrl, width: 44, height: 44),
                    ),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text([
                    '@${user.username}',
                    if (user.blockedAt != null) 'Blocked ${DateFormat.yMMMd().format(user.blockedAt!)}',
                  ].join(' · ')),
                  trailing: busy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(onPressed: () => _unblock(user), child: const Text('Unblock')),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
