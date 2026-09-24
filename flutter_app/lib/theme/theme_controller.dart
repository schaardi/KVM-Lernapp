import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Darstellung „Automatisch / Hell / Dunkel“ – gespeichert wie im Web unter
/// `kvm_theme` (`light` | `dark`, fehlend = System).
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'kvm_theme';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    switch (_prefs!.getString(_key)) {
      case 'light':
        mode.value = ThemeMode.light;
      case 'dark':
        mode.value = ThemeMode.dark;
      default:
        mode.value = ThemeMode.system;
    }
  }

  void set(ThemeMode m) {
    mode.value = m;
    if (m == ThemeMode.system) {
      _prefs?.remove(_key);
    } else {
      _prefs?.setString(_key, m == ThemeMode.dark ? 'dark' : 'light');
    }
  }
}
