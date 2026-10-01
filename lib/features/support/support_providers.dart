import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(dioClientProvider));
});

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  return ref.watch(supportRepositoryProvider).getBlockedUsers();
});
