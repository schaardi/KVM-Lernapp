// Datenmodelle – gespiegelt aus der Web-App (questions.json / cases.json).

class Opt {
  final String t; // Antworttext
  final bool ok; // richtige Option?
  final String? w; // Begründung, warum diese (falsche) Option nicht stimmt
  const Opt({required this.t, this.ok = false, this.w});

  factory Opt.fromJson(Map<String, dynamic> j) => Opt(
        t: (j['t'] ?? '').toString(),
        ok: j['ok'] == 1 || j['ok'] == true,
        w: j['w']?.toString(),
      );
}

class Question {
  final String id;
  final int f; // Fach 1..5
  final String sub; // Themenbereich
  final String type; // 'mc' | 'calc' | 'open'
  final String q; // Fragetext
  final List<Opt> o; // MC-Optionen
  final String e; // Erklärung
  final String? a; // Musterantwort (open)
  final double? ans; // Ergebnis (calc)
  final String unit; // Einheit (calc)

  // Kontext für Fallaufgaben (nicht Teil des JSON, zur Laufzeit gesetzt)
  final CaseContext? caseCtx;

  const Question({
    required this.id,
    required this.f,
    required this.sub,
    required this.type,
    required this.q,
    this.o = const [],
    this.e = '',
    this.a,
    this.ans,
    this.unit = '',
    this.caseCtx,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: (j['id'] ?? '').toString(),
        f: (j['f'] as num?)?.toInt() ?? 0,
        sub: (j['sub'] ?? '').toString(),
        type: (j['t'] ?? 'open').toString(),
        q: (j['q'] ?? '').toString(),
        o: (j['o'] as List<dynamic>? ?? [])
            .map((e) => Opt.fromJson(e as Map<String, dynamic>))
            .toList(),
        e: (j['e'] ?? '').toString(),
        a: j['a']?.toString(),
        ans: (j['ans'] as num?)?.toDouble(),
        unit: (j['unit'] ?? '').toString(),
      );

  Question withCase(CaseContext ctx) => Question(
        id: id, f: f, sub: sub, type: type, q: q, o: o, e: e, a: a,
        ans: ans, unit: unit, caseCtx: ctx,
      );
}

class CaseContext {
  final String title;
  final String context;
  final int step; // 1-basiert
  final int total;
  const CaseContext(this.title, this.context, this.step, this.total);
}

class CaseStudy {
  final String id;
  final int f;
  final String sub;
  final String title;
  final String context;
  final List<Question> steps;
  const CaseStudy({
    required this.id,
    required this.f,
    required this.sub,
    required this.title,
    required this.context,
    required this.steps,
  });

  factory CaseStudy.fromJson(Map<String, dynamic> j) {
    final steps = (j['steps'] as List<dynamic>? ?? [])
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
    return CaseStudy(
      id: (j['id'] ?? '').toString(),
      f: (j['f'] as num?)?.toInt() ?? 0,
      sub: (j['sub'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      context: (j['context'] ?? '').toString(),
      steps: steps,
    );
  }

  /// Schritte als eigenständige Fragen mit Kontext-Banner.
  List<Question> asPool() {
    return List.generate(steps.length, (i) {
      return steps[i].withCase(CaseContext(title, context, i + 1, steps.length));
    });
  }
}

class FormulaItem {
  final String name;
  final String eq;
  final String? note;
  const FormulaItem(this.name, this.eq, this.note);
  factory FormulaItem.fromJson(Map<String, dynamic> j) =>
      FormulaItem((j['n'] ?? '').toString(), (j['e'] ?? '').toString(), j['d']?.toString());
}

class FormulaGroup {
  final String group;
  final List<FormulaItem> items;
  const FormulaGroup(this.group, this.items);
  factory FormulaGroup.fromJson(Map<String, dynamic> j) => FormulaGroup(
        (j['g'] ?? '').toString(),
        (j['items'] as List<dynamic>? ?? [])
            .map((e) => FormulaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Fortschritt je Frage (Leitner-Box + Spaced Repetition).
class Progress {
  int seen;
  int correct;
  int wrong;
  int box;
  int last; // 1 = zuletzt richtig, 0 = falsch
  int? due; // Tages-Index der nächsten Fälligkeit
  Progress({
    this.seen = 0,
    this.correct = 0,
    this.wrong = 0,
    this.box = 0,
    this.last = 0,
    this.due,
  });

  Map<String, dynamic> toJson() =>
      {'s': seen, 'c': correct, 'w': wrong, 'b': box, 'l': last, if (due != null) 'd': due};

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
        seen: (j['s'] as num?)?.toInt() ?? 0,
        correct: (j['c'] as num?)?.toInt() ?? 0,
        wrong: (j['w'] as num?)?.toInt() ?? 0,
        box: (j['b'] as num?)?.toInt() ?? 0,
        last: (j['l'] as num?)?.toInt() ?? 0,
        due: (j['d'] as num?)?.toInt(),
      );
}
