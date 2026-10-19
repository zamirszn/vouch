/// Persisted light/dark/system preference. Material-free.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VouchThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  static const String _key = 'vouch_theme_mode';

  ThemeController([this._preferences]);

  SharedPreferences? _preferences;
  VouchThemeMode _mode = VouchThemeMode.system;

  VouchThemeMode get mode => _mode;

  String get label => switch (_mode) {
        VouchThemeMode.system => 'System',
        VouchThemeMode.light => 'Light',
        VouchThemeMode.dark => 'Dark',
      };

  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final stored = _preferences?.getString(_key);
      _mode = switch (stored) {
        'light' => VouchThemeMode.light,
        'dark' => VouchThemeMode.dark,
        _ => VouchThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // Preferences are a convenience; the app works without them.
    }
  }

  Future<void> setMode(VouchThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(_key, mode.name);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> cycle() {
    final next = switch (_mode) {
      VouchThemeMode.system => VouchThemeMode.light,
      VouchThemeMode.light => VouchThemeMode.dark,
      VouchThemeMode.dark => VouchThemeMode.system,
    };
    return setMode(next);
  }
}
