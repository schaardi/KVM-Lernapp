import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Fächer-Auswahl (FR-001): Industriemeister-Basisqualifikationen sind fix,
/// Fachrichtungen (z. B. Kraftverkehr = Fach 5) sind abwählbar. Generisch über
/// Listen, nicht auf ein bestimmtes Fach hartcodiert.
class SelectionService {
  static final SelectionService instance = SelectionService._();
  SelectionService._();

  /// Immer aktiv – nicht abwählbar.
  static const List<int> baseFacher = [1, 2, 3, 4];

  /// Abwählbare Fachrichtungen (standardmäßig an).
  static const List<int> zusatzFacher = [5];

  static const _key = 'kvm_zusatz_v1';

  /// Fach -> aktiv. Fehlender Eintrag = aktiv (nur explizites false schaltet ab).
  final Map<int, bool> _active = {};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        (json.decode(raw) as Map<String, dynamic>).forEach((k, v) {
          final f = int.tryParse(k);
          if (f != null) _active[f] = v == true;
        });
      } catch (_) {}
    }
  }

  bool isFachActive(int f) =>
      baseFacher.contains(f) ? true : (_active[f] != false);

  bool isZusatz(int f) => zusatzFacher.contains(f);

  /// Schaltet eine Fachrichtung an/aus. Basisfächer bleiben unberührt.
  void toggle(int f) {
    if (baseFacher.contains(f)) return;
    _active[f] = !isFachActive(f);
    _save();
  }

  void _save() {
    final o = <String, dynamic>{};
    _active.forEach((k, v) => o['$k'] = v);
    _prefs?.setString(_key, json.encode(o));
  }
}
