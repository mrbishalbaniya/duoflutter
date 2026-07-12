import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../storage/local_storage.dart';

ThemeMode themeModeFromStorage(String value) {
  return switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
}

String themeModeToStorage(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
  };
}

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._storage, {ThemeMode? initial})
      : super(initial ?? themeModeFromStorage(_storage!.themeMode));

  ThemeController.testing([ThemeMode mode = ThemeMode.dark])
      : _storage = null,
        super(mode);

  final LocalStorage? _storage;

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _storage?.themeMode = themeModeToStorage(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(localStorageProvider));
});
