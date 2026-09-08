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
  final String? bild; // Bildanlage zur Aufgabe: Schlüssel in anlagen.json oder Data-URI
  final String? bildL; // Bildanlage zur Lösung (z. B. eine Lösungsskizze)
  final String? vo; // VO-Bezug der amtlichen Lösung (z. B. "§ 5 Absatz 6 Nr. 1")
  final List<int> bewertung; // amtliche Punkteverteilung je Teilelement
  final bool amtlich; // Lösung ist amtlicher IHK-Lösungshinweis

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
    this.bildL,
    this.vo,
    this.bewertung = const [],
    this.amtlich = false,
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
        bildL: j['bildL']?.toString(),
        vo: j['vo']?.toString(),
        bewertung: (j['bewertung'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        amtlich: j['amtlich'] == 1 || j['amtlich'] == true,
      );

  Question withCase(CaseContext ctx) => Question(
        id: id, f: f, sub: sub, type: type, q: q, o: o, e: e, a: a,
        ans: ans, unit: unit, tab: tab, bild: bild, bildL: bildL, vo: vo,
        bewertung: bewertung, amtlich: amtlich, caseCtx: ctx,
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
  final String termin; // z. B. "Frühjahr 2025" (Gruppierung im Picker)
  final List<Question> steps;
  const CaseStudy({
    required this.id,
    required this.f,
    required this.sub,
    required this.title,
    required this.context,
    this.termin = '',
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
      termin: (j['termin'] ?? '').toString(),
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

/// Eingabefeld einer rechenbaren Formel.
class FormulaVar {
  final String k; // Kürzel im Ausdruck
  final String n; // Beschriftung
  final String u; // Einheit
  final double? d; // Vorbelegung
  const FormulaVar(this.k, this.n, this.u, this.d);
  factory FormulaVar.fromJson(Map<String, dynamic> j) => FormulaVar(
        (j['k'] ?? '').toString(),
        (j['n'] ?? '').toString(),
        (j['u'] ?? '').toString(),
        j['d'] is num ? (j['d'] as num).toDouble() : null,
      );
}

class FormulaItem {
  final String name;
  final String eq;
  final String? note;

  /// Rechenweg – nur gesetzt, wenn sich die Formel ausrechnen lässt.
  final List<FormulaVar> vars;
  final String? expr;
  final String resultName;
  final String resultUnit;
  final int dec;

  const FormulaItem(this.name, this.eq, this.note,
      {this.vars = const [],
      this.expr,
      this.resultName = '',
      this.resultUnit = '',
      this.dec = 2});

  bool get computable => expr != null && vars.isNotEmpty;

  /// Für die Suche: alles, was der Nutzer eintippen könnte.
  String get haystack =>
      '$name $eq ${note ?? ''} $resultName ${vars.map((v) => v.n).join(' ')}';

  factory FormulaItem.fromJson(Map<String, dynamic> j) {
    final r = j['r'] as Map<String, dynamic>?;
    return FormulaItem(
      (j['n'] ?? '').toString(),
      (j['e'] ?? '').toString(),
      j['d']?.toString(),
      vars: (j['v'] as List<dynamic>? ?? [])
          .map((e) => FormulaVar.fromJson(e as Map<String, dynamic>))
          .toList(),
      expr: j['f']?.toString(),
      resultName: (r?['n'] ?? '').toString(),
      resultUnit: (r?['u'] ?? '').toString(),
      dec: (j['dec'] as num?)?.toInt() ?? 2,
    );
  }
}

/// Kalkulationsschema zum Ausfüllen (Zuschlags-/Handelskalkulation).
class CalcSchema {
  final String id;
  final String name;
  final String note;

  /// Zeilen bleiben als Rohdaten – der Löser in formula_calc.dart liest sie.
  final List<Map<String, dynamic>> rows;
  const CalcSchema(this.id, this.name, this.note, this.rows);

  String get haystack =>
      '$name $note ${rows.map((r) => r['n']).join(' ')}';

  factory CalcSchema.fromJson(Map<String, dynamic> j) => CalcSchema(
        (j['id'] ?? '').toString(),
        (j['n'] ?? '').toString(),
        (j['d'] ?? '').toString(),
        (j['rows'] as List<dynamic>? ?? [])
            .map((e) => (e as Map<String, dynamic>))
            .toList(),
      );
}

class FormulaGroup {
  final String group;
  final List<FormulaItem> items;
  final List<CalcSchema> schemas;
  const FormulaGroup(this.group, this.items, {this.schemas = const []});
  factory FormulaGroup.fromJson(Map<String, dynamic> j) => FormulaGroup(
        (j['g'] ?? '').toString(),
        (j['items'] as List<dynamic>? ?? [])
            .map((e) => FormulaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        schemas: (j['s'] as List<dynamic>? ?? [])
            .map((e) => CalcSchema.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Bildanlage aus assets/data/anlagen.json – einmal abgelegt, von den
/// Teilaufgaben über den Schlüssel referenziert.
class Anlagenbild {
  final String uri; // Data-URI
  final String titel; // Bildunterschrift, ggf. leer
  const Anlagenbild(this.uri, this.titel);
  factory Anlagenbild.fromJson(Map<String, dynamic> j) => Anlagenbild(
        (j['u'] ?? '').toString(),
        (j['t'] ?? '').toString(),
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
