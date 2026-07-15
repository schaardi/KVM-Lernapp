import 'dart:math';
import '../models.dart';
import '../constants.dart';
import 'data_service.dart';
import 'progress_service.dart';

enum RoundMode { train, all, weak, due, sim, cases, retry }

class RoundBuilder {
  static final _rng = Random();

  /// Gewichtete Auswahl: neue Fragen zuerst, dann zuletzt falsche, dann niedrige Box.
  static List<Question> _weightedPick(List<Question> cand, int n) {
    final prog = ProgressService.instance;
    final scored = cand.map((q) {
      final p = prog.get(q.id);
      final pr = p == null || p.seen == 0
          ? 0
          : (p.last == 0 ? 1 : 2 + p.box);
      return (q: q, pr: pr, r: _rng.nextDouble());
    }).toList();
    scored.sort((a, b) {
      final c = a.pr.compareTo(b.pr);
      return c != 0 ? c : a.r.compareTo(b.r);
    });
    return scored.take(n).map((e) => e.q).toList();
  }

  static List<T> _shuffle<T>(List<T> a) {
    final b = List<T>.from(a);
    b.shuffle(_rng);
    return b;
  }

  /// Baut den Fragen-Pool für einen Modus. Gibt leere Liste zurück, wenn nichts passt.
  static List<Question> build(RoundMode mode, int fach, String sub, List<Question> wrong) {
    final data = DataService.instance;
    final prog = ProgressService.instance;
    switch (mode) {
      case RoundMode.train:
        final cand = data.forScope(fach, sub);
        return _shuffle(_weightedPick(cand, min(kRoundLen, cand.length)));
      case RoundMode.all:
        return _shuffle(_weightedPick(data.questions, min(kRoundLen, data.questions.length)));
      case RoundMode.weak:
        final cw = data.forScope(fach, sub).where((q) {
          final p = prog.get(q.id);
          return p == null || p.seen == 0 || p.last == 0 || p.box < kMasterBox;
        }).toList();
        return _shuffle(_weightedPick(cw, min(kRoundLen, cw.length)));
      case RoundMode.due:
        var dl = data.questions.where((q) => prog.isDue(q.id)).toList();
        if (dl.length < kRoundLen) {
          final fresh = data.questions.where((q) {
            final p = prog.get(q.id);
            return p == null || p.seen == 0;
          }).toList();
          dl = [...dl, ..._weightedPick(fresh, kRoundLen - dl.length)];
        }
        return _shuffle(_weightedPick(dl, min(kRoundLen, dl.length)));
      case RoundMode.sim:
        final byFach = data.forFach(fach);
        return _shuffle(byFach).take(min(kSimLen, byFach.length)).toList();
      case RoundMode.cases:
        if (data.cases.isEmpty) return [];
        final c = data.cases[_rng.nextInt(data.cases.length)];
        return c.asPool();
      case RoundMode.retry:
        return _shuffle(wrong);
    }
  }
}
