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

/// Anlage einer Prüfungsaufgabe – im Original eine Tabelle im Anhang.
class Anlage {
  final String titel;
  final List<String> kopf;
  final List<List<String>> zeilen;
  final String hinweis;
  const Anlage({this.titel = '', this.kopf = const [], this.zeilen = const [], this.hinweis = ''});

  factory Anlage.fromJson(Map<String, dynamic> j) => Anlage(
        titel: (j['titel'] ?? '').toString(),
        kopf: (j['kopf'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        zeilen: (j['zeilen'] as List<dynamic>? ?? [])
            .map((r) => (r as List<dynamic>).map((e) => e.toString()).toList())
            .toList(),
        hinweis: (j['hinweis'] ?? '').toString(),
      );

  /// Für die Zwischenablage (KI-Export).
  String asText() {
    final out = <String>['$titel:'];
    if (kopf.isNotEmpty) out.add(kopf.join(' | '));
    for (final r in zeilen) {
      out.add(r.join(' | '));
    }
    if (hinweis.isNotEmpty) out.add(hinweis);
    return out.join('\n');
  }
}

/// Eine Prüfungsaufgabe besteht aus Kopf ("Aufgabe 1 a) · 8 Punkte"), der für
/// mehrere Teilaufgaben gemeinsamen Ausgangslage und der Fragestellung selbst.
class TaskParts {
  final String nr;
  final String pts;
  final String sit;
  final String frage;
  const TaskParts(this.nr, this.pts, this.sit, this.frage);

  static final _kopf = RegExp(r'^(Aufgabe\s.+?)\s*·\s*(\d+\s*Punkte?)$');

  factory TaskParts.of(String text) {
    final p = text.split('\n\n');
    final m = p.isEmpty ? null : _kopf.firstMatch(p.first.trim());
    if (m == null || p.length < 2) return TaskParts('', '', '', text);
    return TaskParts(m.group(1)!, m.group(2)!,
        p.sublist(1, p.length - 1).join('\n\n'), p.last);
  }
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
  final Anlage? tab; // Anlage (Tabelle) zur Aufgabe
  final String? bild; // Anlage als Bild (data-URI, z. B. ein Diagramm)

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
    this.tab,
    this.bild,
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
        tab: j['tab'] is Map<String, dynamic>
            ? Anlage.fromJson(j['tab'] as Map<String, dynamic>)
            : null,
        bild: j['bild']?.toString(),
      );

  Question withCase(CaseContext ctx) => Question(
        id: id, f: f, sub: sub, type: type, q: q, o: o, e: e, a: a,
        ans: ans, unit: unit, tab: tab, bild: bild, caseCtx: ctx,
      );

  /// Höchstpunktzahl aus dem Aufgabenkopf ("… · 8 Punkte"); 0 ohne Angabe.
  int get maxPoints {
    final m = RegExp(r'(\d+)').firstMatch(TaskParts.of(q).pts);
    return m == null ? 0 : int.parse(m.group(1)!);
  }
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
