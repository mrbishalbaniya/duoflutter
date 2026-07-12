import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/auth_controller.dart';

final myProfileProvider = FutureProvider.autoDispose<DuoProfile>((ref) async {
  try {
    return await ref.read(profileRepositoryProvider).getMyProfile();
  } catch (_) {
    final user = ref.read(authControllerProvider).user;
    if (user != null) return user.profile;
    rethrow;
  }
});

final profileScreenProvider = FutureProvider.autoDispose<({DuoUser user, DuoProfile profile})>((ref) async {
  final authUser = ref.watch(authControllerProvider).user;
  if (authUser == null) throw Exception('Not signed in');

  try {
    final profile = await ref.read(profileRepositoryProvider).getMyProfile();
    return (user: authUser, profile: profile);
  } catch (_) {
    return (user: authUser, profile: authUser.profile);
  }
});
