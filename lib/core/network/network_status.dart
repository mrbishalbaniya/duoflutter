import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks online/offline state from recent HTTP outcomes.
class NetworkStatusNotifier extends StateNotifier<bool> {
  NetworkStatusNotifier() : super(true);

  void markOnline() {
    if (!state) state = true;
  }

  void markOffline() {
    if (state) state = false;
  }
}

final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
  return NetworkStatusNotifier();
});
