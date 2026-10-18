/// Persisted light/dark/system preference.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _key = 'vouch_theme_mode';

  ThemeController([this._preferences]);

  SharedPreferences? _preferences;
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  String get label => switch (_mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final stored = _preferences?.getString(_key);
      _mode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // Preferences are a convenience; the app works without them.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
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
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    return setMode(next);
  }
}
