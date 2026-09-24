import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// „Zuletzt geöffnet“ auf der Startseite: die zuletzt geöffnete Original-
/// Prüfung und Aufgabe (Web `kvm_letzte_pruefung` = `{id, nr}`), gesetzt bei
/// jedem Öffnen einer Aufgabe im Aufgabenblatt.
class LetztePruefung {
  LetztePruefung._();
  static final LetztePruefung instance = LetztePruefung._();

  static const _key = 'kvm_letzte_pruefung';
  final ValueNotifier<({String id, int nr})?> stand = ValueNotifier(null);
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final j = json.decode(raw) as Map<String, dynamic>;
      final id = j['id'];
      final nr = j['nr'];
      if (id is String && id.startsWith('P-')) {
        stand.value = (id: id, nr: nr is num ? nr.toInt() : 1);
      }
    } catch (_) {}
  }

  void merken(String id, int nr) {
    if (!id.startsWith('P-')) return;
    stand.value = (id: id, nr: nr);
    _prefs?.setString(_key, json.encode({'id': id, 'nr': nr}));
  }
}
