import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/providers/chat_providers.dart';
import '../../widgets/duo_bottom_nav.dart';
import '../../widgets/duo_ui.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(chatUnreadTotalProvider);
    // Android back on another tab's root returns to Match (home) first instead
    // of closing the app; back on Match exits as usual.
    final onHome = navigationShell.currentIndex == _matchBranchIndex;
    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(_matchBranchIndex);
      },
      child: Scaffold(
        extendBody: true,
        body: DuoAmbientBackground(child: navigationShell),
        bottomNavigationBar: DuoBottomNav(
          currentIndex: navigationShell.currentIndex,
          unreadCount: unread,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

/// Branch order in app_router: discover, chat, match, map, profile.
const _matchBranchIndex = 2;
