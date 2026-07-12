import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const _settingsBox = 'settings';
  static const _cacheBox = 'cache';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<dynamic>(_cacheBox);
  }

  Box<dynamic> get settings => Hive.box<dynamic>(_settingsBox);
  Box<dynamic> get cache => Hive.box<dynamic>(_cacheBox);

  static const _themeKey = 'duo_theme';
  static const _pushEnabledKey = 'duo_push_enabled';
  static const _pushTokenKey = 'duo_push_token';

  String get themeMode {
    final stored = settings.get(_themeKey) ?? settings.get('theme_mode');
    if (stored == 'light' || stored == 'dark' || stored == 'system') {
      return stored as String;
    }
    return 'dark';
  }

  set themeMode(String value) => settings.put(_themeKey, value);

  bool get pushEnabled => settings.get(_pushEnabledKey) == true;

  set pushEnabled(bool value) => settings.put(_pushEnabledKey, value);

  String? get pushToken => settings.get(_pushTokenKey) as String?;

  set pushToken(String? value) {
    if (value == null || value.isEmpty) {
      settings.delete(_pushTokenKey);
    } else {
      settings.put(_pushTokenKey, value);
    }
  }
}
