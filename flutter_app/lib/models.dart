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

  /// Hat die Anlage leere Felder? Dann wird sie im Original ausgefüllt und
  /// bekommt im Aufgabenblatt Eingabefelder.
  bool get hatLeere =>
      zeilen.any((r) => r.any((z) => z.trim().isEmpty));

  /// Passt eine Lösungstabelle zu dieser Anlage? Nur dann werden die eigenen
  /// Eintragungen darin verglichen – sonst steht sie für sich im Lösungsblock.
  bool passtZu(Anlage? sol) {
    if (sol == null || !hatLeere || zeilen.length != sol.zeilen.length) {
      return false;
    }
    for (var i = 0; i < zeilen.length; i++) {
      if (zeilen[i].length != sol.zeilen[i].length) return false;
    }
    return true;
  }

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

/// Anlagen eines Schritts oder einer Aufgabe. Eine Aufgabe kann mehrere
/// tragen (BWL H2020 A5: Verteilungsschlüssel und auszufüllender
/// Betriebsabrechnungsbogen) – im JSON steht dann eine Liste, ältere Einträge
/// tragen die Tabelle direkt.
List<Anlage> anlagenAus(dynamic j) {
  if (j is Map<String, dynamic>) return [Anlage.fromJson(j)];
  if (j is List) {
    return j
        .whereType<Map<String, dynamic>>()
        .map(Anlage.fromJson)
        .toList();
  }
  return const [];
}

/// Eine Prüfungsaufgabe besteht aus Kopf ("Aufgabe 1 a) · 8 Punkte"), der für
/// mehrere Teilaufgaben gemeinsamen Ausgangslage und der Fragestellung selbst.
///
/// Prüfungen liefern die drei Teile getrennt (`nr`, `teil`, `pts` am Schritt,
/// die Ausgangslage an der Aufgabe). Fremde Inhalte tragen den Kopf weiter im
/// Fragetext – [TaskParts.ausText] zerlegt ihn wie bisher.
class TaskParts {
  final String nr;
  final String pts;
  final String sit;
  final String frage;
  const TaskParts(this.nr, this.pts, this.sit, this.frage);

  static final _kopf = RegExp(r'^(Aufgabe\s.+?)\s*·\s*(\d+\s*Punkte?)$');

  factory TaskParts.of(Question q) {
    if (q.nr > 0) {
      // Fallaufgaben ohne IHK-Bezug sind nur der Form halber in eine Aufgabe 1
      // gruppiert – sie tragen keine Punkte und bekommen auch keinen Kopf.
      final hatKopf = q.pts > 0;
      return TaskParts(
        hatKopf ? 'Aufgabe ${q.nr} ${q.teil})' : '',
        hatKopf ? '${q.pts} ${q.pts == 1 ? 'Punkt' : 'Punkte'}' : '',
        q.aufgabe?.sit ?? '',
        q.q,
      );
    }
    return TaskParts.ausText(q.q);
  }

  factory TaskParts.ausText(String text) {
    final p = text.split('\n\n');
    final m = p.isEmpty ? null : _kopf.firstMatch(p.first.trim());
    if (m == null || p.length < 2) return TaskParts('', '', '', text);
    return TaskParts(m.group(1)!, m.group(2)!,
        p.sublist(1, p.length - 1).join('\n\n'), p.last);
  }

  /// Der zusammengesetzte Aufgabentext, wie er im Original auf dem Blatt steht.
  /// Die Exporte geben ihn unverändert weiter.
  String get volltext {
    final teile = <String>[];
    if (nr.isNotEmpty && pts.isNotEmpty) teile.add('$nr · $pts');
    if (sit.isNotEmpty) teile.add(sit);
    teile.add(frage);
    return teile.join('\n\n');
  }
}

/// Eine Aufgabe des Prüfungsblatts: Ausgangslage, Anlagen und Punkte, die für
/// alle ihre Teilaufgaben a–x gelten.
class Aufgabe {
  final int nr;
  final int pts; // Summe der Punkte aller Teile
  final String sit; // Ausgangslage – steht einmal, nicht je Teil
  final List<Anlage> tabs;
  final String? bild;
  const Aufgabe({required this.nr, this.pts = 0, this.sit = '',
      this.tabs = const [], this.bild});

  factory Aufgabe.fromJson(Map<String, dynamic> j) => Aufgabe(
        nr: (j['nr'] as num?)?.toInt() ?? 0,
        pts: (j['pts'] as num?)?.toInt() ?? 0,
        sit: (j['sit'] ?? '').toString(),
        tabs: anlagenAus(j['tab']),
        bild: j['bild']?.toString(),
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
  final List<Anlage> tabs; // Anlagen (Tabellen) zur Aufgabe
  final Anlage? tabL; // ausgefüllte Anlage als Lösung dieser Teilaufgabe
  final String? bild; // Bildanlage zur Aufgabe: Schlüssel in anlagen.json oder Data-URI
  final String? bildL; // Bildanlage zur Lösung (z. B. eine Lösungsskizze)
  final String? vo; // VO-Bezug der amtlichen Lösung (z. B. "§ 5 Absatz 6 Nr. 1")
  final List<int> bewertung; // amtliche Punkteverteilung je Teilelement
  final bool amtlich; // Lösung ist amtlicher IHK-Lösungshinweis

  // Aufgabenblatt: zu welcher Aufgabe dieser Teil gehört.
  final int nr; // Nummer der Aufgabe (0 = keine Zuordnung)
  final String teil; // Buchstabe der Teilaufgabe, z. B. "c"
  final int pts; // Punkte dieser Teilaufgabe (0 = ohne Punktangabe)
  final List<String> braucht; // Teile, auf deren Ergebnis diese Aufgabe aufbaut

  // Kontext für Fallaufgaben (nicht Teil des JSON, zur Laufzeit gesetzt)
  final CaseContext? caseCtx;
  final Aufgabe? aufgabe; // Ausgangslage und Anlagen der Aufgabe

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
    this.tabs = const [],
    this.tabL,
    this.bild,
    this.bildL,
    this.vo,
    this.bewertung = const [],
    this.amtlich = false,
    this.nr = 0,
    this.teil = '',
    this.pts = 0,
    this.braucht = const [],
    this.caseCtx,
    this.aufgabe,
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
        tabs: anlagenAus(j['tab']),
        tabL: j['tabL'] is Map<String, dynamic>
            ? Anlage.fromJson(j['tabL'] as Map<String, dynamic>)
            : null,
        bild: j['bild']?.toString(),
        bildL: j['bildL']?.toString(),
        vo: j['vo']?.toString(),
        bewertung: (j['bewertung'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        amtlich: j['amtlich'] == 1 || j['amtlich'] == true,
        nr: (j['nr'] as num?)?.toInt() ?? 0,
        teil: (j['teil'] ?? '').toString(),
        pts: (j['pts'] as num?)?.toInt() ?? 0,
        braucht: (j['braucht'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Question withCase(CaseContext ctx, [Aufgabe? auf]) => Question(
        id: id, f: f, sub: sub, type: type, q: q, o: o, e: e, a: a,
        ans: ans, unit: unit, tabs: tabs, tabL: tabL, bild: bild,
        bildL: bildL, vo: vo,
        bewertung: bewertung, amtlich: amtlich, nr: nr, teil: teil, pts: pts,
        braucht: braucht, caseCtx: ctx, aufgabe: auf,
      );

  /// Höchstpunktzahl dieser Teilaufgabe; 0 ohne Angabe.
  int get maxPoints {
    if (pts > 0) return pts;
    final m = RegExp(r'(\d+)').firstMatch(TaskParts.of(this).pts);
    return m == null ? 0 : int.parse(m.group(1)!);
  }

  /// Abbildung dieser Teilaufgabe – oder die der ganzen Aufgabe.
  String? get bildEffektiv => bild ?? aufgabe?.bild;

  /// Tabellenanlagen dieser Teilaufgabe – oder die der ganzen Aufgabe.
  List<Anlage> get tabsEffektiv => tabs.isNotEmpty ? tabs : (aufgabe?.tabs ?? const []);
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
  /// Hinweis über der Prüfung, z. B. "Prüfung von 2016 – Rechtsstand beachten".
  final String hinweis;
  final List<Aufgabe> aufgaben; // Aufgabenblatt: Aufgabe 1..n mit Ausgangslage
  final List<Question> steps; // die Teilaufgaben a–x aller Aufgaben
  const CaseStudy({
    required this.id,
    required this.f,
    required this.sub,
    required this.title,
    required this.context,
    this.termin = '',
    this.hinweis = '',
    this.aufgaben = const [],
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
      hinweis: (j['hinweis'] ?? '').toString(),
      aufgaben: (j['aufgaben'] as List<dynamic>? ?? [])
          .map((e) => Aufgabe.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: steps,
    );
  }

  /// Schritte als eigenständige Fragen mit Kontext-Banner und ihrer Aufgabe.
  List<Question> asPool() {
    return List.generate(steps.length, (i) {
      return steps[i].withCase(
          CaseContext(title, context, i + 1, steps.length), aufgabeVon(steps[i].nr));
    });
  }

  /// Die Aufgabe, zu der eine Teilaufgabe gehört.
  Aufgabe? aufgabeVon(int nr) {
    for (final a in aufgaben) {
      if (a.nr == nr) return a;
    }
    return null;
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
  /// Dateiname im Bündel, z. B. `nt25-rampe.jpg` (leer bei einer Data-URI).
  final String datei;
  final String titel; // Bildunterschrift, ggf. leer
  final int breite; // Originalmaße in Pixeln – 0, wenn unbekannt
  final int hoehe;
  final String uri; // nur noch für Alt-Einträge mit eingebetteter Data-URI
  const Anlagenbild(this.datei, this.titel,
      {this.breite = 0, this.hoehe = 0, this.uri = ''});

  factory Anlagenbild.fromJson(Map<String, dynamic> j) => Anlagenbild(
        (j['f'] ?? '').toString(),
        (j['t'] ?? '').toString(),
        breite: (j['w'] as num?)?.toInt() ?? 0,
        hoehe: (j['h'] as num?)?.toInt() ?? 0,
        uri: (j['u'] ?? '').toString(),
      );

  /// Pfad im Asset-Bündel der App.
  String get asset => 'assets/anlagen/$datei';

  /// Seitenverhältnis für den Platzhalter beim Laden.
  double? get verhaeltnis =>
      (breite > 0 && hoehe > 0) ? breite / hoehe : null;
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
