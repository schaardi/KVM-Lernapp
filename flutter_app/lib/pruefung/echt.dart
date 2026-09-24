import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// Prüfung unter Echtbedingungen (FR-007): mit Uhr über die echte
/// Bearbeitungszeit, Lösungen erst nach der Abgabe.
///
/// Der Durchgang steht in `kvm_echt` (`{id, start, min, ende?, zeitUm?}`). Die
/// Uhr rechnet ab der Startzeit – sie läuft also weiter, wenn man die Prüfung
/// verlässt oder die App neu startet, wie in der echten Prüfung. Es gibt immer
/// nur einen Durchgang.
class EchtLauf {
  final String id;
  final int start; // ms
  final int min; // Bearbeitungszeit in Minuten
  final int? ende; // ms, gesetzt nach der Abgabe
  final bool zeitUm;
  const EchtLauf({required this.id, required this.start, required this.min, this.ende, this.zeitUm = false});

  bool get abgegeben => ende != null;
  int get frist => start + min * 60000;

  /// Restzeit in ms (negativ nach Ablauf).
  int rest([int? jetzt]) => frist - (jetzt ?? DateTime.now().millisecondsSinceEpoch);

  /// Bearbeitungszeit nach der Abgabe.
  int get dauer => math.max(0, (ende ?? start) - start);

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'min': min,
        if (ende != null) 'ende': ende,
        if (zeitUm) 'zeitUm': true,
      };

  static EchtLauf? fromJson(dynamic j) {
    if (j is! Map) return null;
    final id = j['id'], start = j['start'], min = j['min'];
    if (id is! String || id.isEmpty || start is! num || start == 0 || min is! num || min == 0) return null;
    final ende = j['ende'];
    return EchtLauf(
      id: id,
      start: start.toInt(),
      min: min.toInt(),
      ende: ende is num ? ende.toInt() : null,
      zeitUm: j['zeitUm'] == true,
    );
  }
}

/// Benachrichtigt sofort – oder nach dem Frame, wenn gerade gebaut wird (etwa
/// aus `initState` heraus); sonst meldete Flutter „setState() called during
/// build“ bei den Zuhörern auf anderen Seiten.
void nachDemBauen(VoidCallback f) {
  if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
    SchedulerBinding.instance.addPostFrameCallback((_) => f());
  } else {
    f();
  }
}

class Echtbedingungen extends ChangeNotifier {
  Echtbedingungen._();
  static final Echtbedingungen instance = Echtbedingungen._();

  static const _key = 'kvm_echt';
  SharedPreferences? _prefs;
  EchtLauf? _lauf;

  /// Der laufende oder abgegebene Durchgang (null = keiner).
  EchtLauf? get lauf => _lauf;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    EchtLauf? e;
    if (raw != null && raw.isNotEmpty) {
      try {
        e = EchtLauf.fromJson(json.decode(raw));
      } catch (_) {}
    }
    _lauf = e;
    nachDemBauen(notifyListeners);
  }

  void setzen(EchtLauf? e) {
    _lauf = e;
    if (e == null) {
      _prefs?.remove(_key);
    } else {
      _prefs?.setString(_key, json.encode(e.toJson()));
    }
    nachDemBauen(notifyListeners);
  }

  /// Der Durchgang dieser Prüfung, falls einer besteht.
  EchtLauf? von(String fallId) {
    final e = _lauf;
    return (e != null && e.id == fallId) ? e : null;
  }

  /// Läuft für diese Prüfung gerade ein Durchgang (noch nicht abgegeben)?
  bool laeuft(String fallId) {
    final e = von(fallId);
    return e != null && !e.abgegeben;
  }

  /// Abgeben: `ende` = min(jetzt, start + min); bei Ablauf `zeitUm`.
  EchtLauf? abgeben(String fallId, {bool zeitUm = false, int? jetzt}) {
    final e = von(fallId);
    if (e == null || e.abgegeben) return e;
    final t = jetzt ?? DateTime.now().millisecondsSinceEpoch;
    final neu = EchtLauf(id: e.id, start: e.start, min: e.min, ende: math.min(t, e.frist), zeitUm: zeitUm);
    setzen(neu);
    return neu;
  }
}

/// Bearbeitungszeit: steht im Text „Bearbeitungszeit N Minuten“, gilt N
/// (Kraftverkehr 180); sonst Basisqualifikationen 90, Naturwissenschaften 60.
int echtMinuten(CaseStudy fall) {
  final m = RegExp(r'Bearbeitungszeit\s+(\d+)\s*Minuten').firstMatch(fall.context);
  if (m != null) return int.parse(m.group(1)!);
  return fall.id.startsWith('P-NT-') ? 60 : 90;
}

/// Uhr: „1:29:45“, unter einer Stunde „29:45“.
String uhrText(int ms) {
  final s = math.max(0, (ms / 1000).ceil());
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, x = s % 60;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
  return '${h > 0 ? '$h:' : ''}$mm:${x.toString().padLeft(2, '0')}';
}

/// Dauer: „1 h 12 min“, „1 h“, „45 min“.
String dauerText(int ms) {
  var m = math.max(0, (ms / 60000).round());
  final h = m ~/ 60;
  m %= 60;
  return h > 0 ? '$h h${m > 0 ? ' $m min' : ''}' : '$m min';
}
