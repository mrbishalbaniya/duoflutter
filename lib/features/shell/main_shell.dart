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
    return Scaffold(
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
    );
  }
}
