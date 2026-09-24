import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lerntage wie im Web (`kvm_tage`): je Kalendertag die Zahl beantworteter
/// Fragen. Daraus entstehen „Tage in Folge“, die Aktivität der letzten 14 Tage
/// und die Antworten dieser Woche (Rangliste).
class LerntageService {
  LerntageService._();
  static final LerntageService instance = LerntageService._();

  static const _key = 'kvm_tage';
  static const _aufbewahren = 120; // Tage

  final Map<int, int> _tage = {};
  SharedPreferences? _prefs;

  /// Tagesindex in lokaler Zeit (wie Web `todayIdx`).
  static int heute([DateTime? jetzt]) {
    final t = jetzt ?? DateTime.now();
    return (t.millisecondsSinceEpoch + t.timeZoneOffset.inMilliseconds) ~/ 86400000;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _tage.clear();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      (json.decode(raw) as Map<String, dynamic>).forEach((k, v) {
        final i = int.tryParse(k);
        if (i != null && v is num && v > 0) _tage[i] = v.toInt();
      });
    } catch (_) {}
  }

  /// Eine beantwortete Frage zählen (aus `ProgressService.record`).
  void zaehlen() {
    final h = heute();
    _tage[h] = (_tage[h] ?? 0) + 1;
    _tage.removeWhere((k, _) => k < h - _aufbewahren);
    _prefs?.setString(_key, json.encode(_tage.map((k, v) => MapEntry('$k', v))));
  }

  void reset() {
    _tage.clear();
    _prefs?.remove(_key);
  }

  int anTag(int idx) => _tage[idx] ?? 0;

  /// Tage in Folge bis heute; ist heute noch nichts gelernt, bis gestern.
  int serie() {
    var d = heute();
    if (anTag(d) == 0) d--;
    var n = 0;
    while (anTag(d) > 0) {
      n++;
      d--;
    }
    return n;
  }

  /// Die letzten [n] Tage, ältester zuerst (heute zuletzt).
  List<({int tag, int anzahl})> letzte(int n) {
    final h = heute();
    return [for (var i = n - 1; i >= 0; i--) (tag: h - i, anzahl: anTag(h - i))];
  }

  /// Antworten der laufenden Kalenderwoche (Montag bis heute).
  int dieseWoche() {
    final jetzt = DateTime.now();
    final mo = (jetzt.weekday + 6) % 7; // Montag = 0
    final h = heute(jetzt);
    var s = 0;
    for (var i = 0; i <= mo; i++) {
      s += anTag(h - i);
    }
    return s;
  }

  /// Anzahl Tage mit mindestens einer Antwort (gesamt, im Aufbewahrungsfenster).
  int lerntage() => _tage.values.where((v) => v > 0).length;
}
