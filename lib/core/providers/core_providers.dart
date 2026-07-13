import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/google_auth_service.dart';
import '../cache/api_cache_store.dart';
import '../network/dio_client.dart';
import '../network/network_status.dart';
import '../storage/local_storage.dart';
import '../storage/token_storage.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../repositories/matching_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/wallet_repository.dart';
import '../../repositories/photo_repository.dart';
import '../../repositories/verification_repository.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(ref.watch(dioClientProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(dioClientProvider));
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => GoogleAuthService());

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

final apiCacheStoreProvider = Provider<ApiCacheStore>((ref) {
  return ApiCacheStore(ref.watch(localStorageProvider).cache);
});

final dioClientProvider = Provider<DioClient>((ref) {
  final network = ref.read(networkStatusProvider.notifier);
  return DioClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onNetworkOnline: network.markOnline,
    onNetworkOffline: network.markOffline,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioClientProvider));
});

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository(ref.watch(dioClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(dioClientProvider));
});
