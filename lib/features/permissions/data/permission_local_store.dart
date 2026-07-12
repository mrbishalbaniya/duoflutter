import 'package:hive_flutter/hive_flutter.dart';

class PermissionLocalStore {
  PermissionLocalStore(this._box);

  final Box<dynamic> _box;

  static const setupCompleteKey = 'duo_permission_setup_complete';
  static const personalizationKey = 'duo_permission_personalization';

  bool get isSetupComplete => _box.get(setupCompleteKey) == true;

  Future<void> markSetupComplete() async {
    await _box.put(setupCompleteKey, true);
  }

  Future<void> resetSetup() async {
    await _box.delete(setupCompleteKey);
  }

  Map<String, dynamic> get personalizationPrefs {
    final raw = _box.get(personalizationKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<void> savePersonalizationPrefs(Map<String, dynamic> prefs) async {
    await _box.put(personalizationKey, prefs);
  }
}
