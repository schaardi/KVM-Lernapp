import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../constants.dart';
import 'data_service.dart';

/// Lernfortschritt: Leitner-Boxen + Spaced Repetition, persistent gespeichert.
class ProgressService {
  static final ProgressService instance = ProgressService._();
  ProgressService._();

  static const _key = 'kvm_progress_v1';
  final Map<String, Progress> _map = {};
  SharedPreferences? _prefs;

  /// Wird nach jeder Änderung aufgerufen (z. B. Cloud-Push durch SyncService).
  void Function()? onChanged;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final obj = json.decode(raw) as Map<String, dynamic>;
        obj.forEach((k, v) {
          _map[k] = Progress.fromJson(v as Map<String, dynamic>);
        });
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final obj = <String, dynamic>{};
    _map.forEach((k, v) => obj[k] = v.toJson());
    await _prefs?.setString(_key, json.encode(obj));
    onChanged?.call();
  }

  /// Gesamter Fortschritt als JSON – für den Cloud-Upload.
  Map<String, dynamic> exportJson() {
    final o = <String, dynamic>{};
    _map.forEach((k, v) => o[k] = v.toJson());
    return o;
  }

  /// Führt einen fremden (Cloud-)Stand herein: je Frage wird der weiter
  /// fortgeschrittene Datensatz behalten (höhere Box, dann mehr gesehen/richtig).
  /// Speichert lokal, wenn sich etwas geändert hat.
  void mergeRemote(Map<String, dynamic> remote) {
    var changed = false;
    remote.forEach((k, v) {
      if (v is! Map) return;
      final incoming = Progress.fromJson(Map<String, dynamic>.from(v));
      final cur = _map[k];
      if (cur == null || _moreAdvanced(incoming, cur)) {
        _map[k] = incoming;
        changed = true;
      }
    });
    if (changed) {
      final obj = <String, dynamic>{};
      _map.forEach((k, val) => obj[k] = val.toJson());
      _prefs?.setString(_key, json.encode(obj)); // ohne onChanged -> keine Push-Schleife
    }
  }

  bool _moreAdvanced(Progress a, Progress b) {
    if (a.box != b.box) return a.box > b.box;
    if (a.seen != b.seen) return a.seen > b.seen;
    return a.correct > b.correct;
  }

  Progress? get(String id) => _map[id];

  int _todayIdx() =>
      (DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24));

  void record(String id, bool correct) {
    final p = _map[id] ?? Progress();
    p.seen++;
    if (correct) {
      p.correct++;
      p.box = (p.box + 1) > kMaxBox ? kMaxBox : (p.box + 1);
    } else {
      p.wrong++;
      p.box = 0;
    }
    p.last = correct ? 1 : 0;
    final bi = p.box < 0 ? 0 : (p.box > 5 ? 5 : p.box);
    p.due = _todayIdx() + kSrIntervals[bi];
    _map[id] = p;
    _save();
  }

  bool isDue(String id) {
    final p = _map[id];
    if (p == null || p.seen == 0) return false;
    final d = p.due ?? 0;
    return d <= _todayIdx();
  }

  void reset() {
    _map.clear();
    _save();
  }

  // ---- Kennzahlen (nur über die aktiven Fächer: Basis + gewählte Fachrichtungen) ----
  int dueCount() {
    var n = 0;
    for (final q in DataService.instance.activeQuestions()) {
      if (isDue(q.id)) n++;
    }
    return n;
  }

  int freshCount() {
    var n = 0;
    for (final q in DataService.instance.activeQuestions()) {
      final p = _map[q.id];
      if (p == null || p.seen == 0) n++;
    }
    return n;
  }

  int masteredCount() {
    var n = 0;
    for (final q in DataService.instance.activeQuestions()) {
      final p = _map[q.id];
      if (p != null && p.seen > 0 && p.box >= kMasterBox) n++;
    }
    return n;
  }

  int seenCount() {
    var n = 0;
    for (final q in DataService.instance.activeQuestions()) {
      final p = _map[q.id];
      if (p != null && p.seen > 0) n++;
    }
    return n;
  }

  /// Prüfungsreife je Fach = Ø Anteil gemeisterter Box (0..1).
  double fachReife(int f) {
    final qs = DataService.instance.forFach(f);
    if (qs.isEmpty) return 0;
    var s = 0.0;
    for (final q in qs) {
      final p = _map[q.id];
      final box = p == null ? 0 : (p.box < kMasterBox ? p.box : kMasterBox);
      s += box / kMasterBox;
    }
    return s / qs.length;
  }

  double overallReife() {
    var tot = 0, acc = 0.0;
    for (final f in DataService.instance.activeFacher()) {
      final n = DataService.instance.forFach(f).length;
      if (n == 0) continue;
      tot += n;
      acc += fachReife(f) * n;
    }
    return tot == 0 ? 0 : acc / tot;
  }

  int fachMastered(int f) {
    var n = 0;
    for (final q in DataService.instance.forFach(f)) {
      final p = _map[q.id];
      if (p != null && p.box >= kMasterBox) n++;
    }
    return n;
  }
}
