import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/duo_theme.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class DuoApp extends ConsumerWidget {
  const DuoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Duo',
      debugShowCheckedModeBanner: false,
      theme: DuoTheme.light(),
      darkTheme: DuoTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorage();
  await storage.init();
}
