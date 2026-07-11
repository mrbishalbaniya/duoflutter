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

  String get themeMode => settings.get('theme_mode', defaultValue: 'system') as String;

  set themeMode(String value) => settings.put('theme_mode', value);
}
