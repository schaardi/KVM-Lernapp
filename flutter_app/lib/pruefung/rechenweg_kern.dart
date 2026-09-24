import 'dart:math' as math;

// Übergangsweise der Rechenkern des Rechenwegs (FR-003 B). FR-005 A verlangt
// einen gemeinsamen Kern für Rechenweg und Taschenrechner: Beim Zusammenführen
// mit dem Werkzeug-Paket wird diese Datei gelöscht und der Rechenweg auf
// `lib/services/rechenkern.dart` umgestellt. Zuordnung: RwZeichen → RkZeichen,
// rwTokens → zerlege, rwAuswerten → auswerten, rechne → rechne,
// rwZahl → rkZahl, rwFunktion → rkFunktion, rwFmt → fmtErgebnis,
// rwZahlText → zahlText, rwSchoen → schoen,
// rwZeileText(l, f, u) → zeileText(l: l, f: f, u: u).
//
// Rechenaufgaben löst man in der Prüfung Zeile für Zeile: Bezeichnung,
// Rechnung, Ergebnis (FR-003 B). Gerechnet wird wie in der Web-Fassung
// (`rwTokens`, `rwAuswerten`, `rwFmt`, `rwSchoen`, `rwZeileText` in
// index.html). Kein eval: Zahlen deutsch oder englisch, Einheiten werden
// überlesen, Prozent wie auf dem Tischrechner, Winkel in Grad, Zeiten
// („6 h 45 min“).

/// Ein Zeichen einer Rechnung: Zahl (auch Zeit oder π), Rechenzeichen,
/// Klammer, Funktion, nachgestelltes Prozent oder Potenz.
class RwZeichen {
  /// Zahlenwert (Zahl, Zeit in Stunden oder π).
  final double? n;

  /// Die Zahl so, wie sie eingegeben wurde („4.400“); „π“ bei Pi.
  final String raw;

  /// Zeitangabe als [Stunden, Minuten].
  final List<int>? zeit;

  /// Rechenzeichen: `+ - * / ^`.
  final String? o;

  /// Klammer: `(` oder `)`.
  final String? p;

  /// Nachgestelltes Prozent.
  final bool pc;

  /// Nachgestellte Potenz (2 oder 3).
  final int? pw;

  /// Funktion: `sqrt sin cos tan asin acos atan`.
  final String? f;

  const RwZeichen._({this.n, this.raw = '', this.zeit, this.o, this.p, this.pc = false, this.pw, this.f});

  /// Zahl – [raw] bleibt leer, wenn der Wert nicht getippt wurde (etwa ein
  /// Ergebnis aus dem Verlauf des Rechners).
  const RwZeichen.zahl(double wert, [String raw = '']) : this._(n: wert, raw: raw);
  const RwZeichen.pi() : this._(n: math.pi, raw: 'π');
  RwZeichen.zeit(int h, int min, [String raw = ''])
      : this._(n: h + min / 60, raw: raw, zeit: [h, min]);
  const RwZeichen.op(String o) : this._(o: o);
  const RwZeichen.klammer(String p) : this._(p: p);
  const RwZeichen.prozent() : this._(pc: true);
  const RwZeichen.potenz(int pw) : this._(pw: pw);
  const RwZeichen.funktion(String f) : this._(f: f);

  @override
  String toString() => n != null ? (raw.isEmpty ? '$n' : raw) : (o ?? p ?? f ?? (pc ? '%' : '^$pw'));
}

const _rwFn = {'sin': 'sin', 'cos': 'cos', 'tan': 'tan', 'arcsin': 'asin', 'arccos': 'acos', 'arctan': 'atan'};
final _rwEinheitBruch = RegExp(r'[A-Za-zÄÖÜäöüß€$°]+\s*/\s*[A-Za-zÄÖÜäöüß€$°]+');
final _rwZeit = RegExp(r'^(\d+)\s*h\s*(\d{1,2})(?![\d.,])(?:\s*min\b)?');
final _rwZahlRe = RegExp(r'^(?:\d[\d.]*(?:,\d+)?|,\d+)');
final _rwMalX = RegExp(r'^[xX]\s*[\d(√π]');
final _rwUmkehr = RegExp(r'^(sin|cos|tan)\s*⁻¹', caseSensitive: false);
final _rwWort = RegExp(r'^[A-Za-zÄÖÜäöüß€$°]+');
final _rwTausender = RegExp(r'^\d{1,3}(\.\d{3})+$');

/// Wie `parseFloat` im Web: liest den Zahlanfang, der Rest zählt nicht.
double _parseFloat(String t) {
  final m = RegExp(r'^\s*[+-]?(?:\d+\.?\d*|\.\d+)').firstMatch(t);
  if (m == null) return double.nan;
  var s = m.group(0)!.trim();
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return double.tryParse(s) ?? double.nan;
}

/// „1.234,5“, „1234.5“ und „4.400“ (Tausenderpunkt) werden richtig gelesen.
double rwZahl(String t) {
  t = t.replaceFirst(RegExp(r'^,'), '0,');
  if (t.contains(',')) return _parseFloat(t.replaceAll('.', '').replaceFirst(',', '.'));
  if (_rwTausender.hasMatch(t)) return _parseFloat(t.replaceAll('.', ''));
  return _parseFloat(t);
}

/// Rechnung in Zeichen zerlegen: Zahlen, `+ − · × * ÷ / : ^ ( ) % ² ³ √`, π,
/// sin/cos/tan in Grad samt Umkehrung („sin⁻¹“, „arcsin“), Zeitangaben
/// („6 h 45“ = 6,75 Stunden) und „x“ als Mal zwischen Zahlen. Vor π, √ und
/// „(“ darf das Mal fehlen („2π“). Einheiten („km/h“, „€“) werden überlesen;
/// hinter einem „=“ steht schon das Ergebnis. `null` = unlesbar.
List<RwZeichen>? rwTokens(String? eingabe) {
  final s = (eingabe ?? '').replaceAll(_rwEinheitBruch, ' ');
  final t = <RwZeichen>[];
  void mal() {
    if (t.isEmpty) return;
    final v = t.last;
    if (v.n != null || v.p == ')' || v.pc || v.pw != null) t.add(const RwZeichen.op('*'));
  }

  var i = 0;
  while (i < s.length) {
    final c = s[i];
    final rest = s.substring(i);
    final vor = t.isEmpty ? null : t.last;
    if (c.trim().isEmpty) {
      i++;
      continue;
    }
    var m = _rwZeit.firstMatch(rest);
    if (m != null) {
      final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
      if (min > 59) return null;
      t.add(RwZeichen.zeit(h, min, m.group(0)!));
      i += m.group(0)!.length;
      continue;
    }
    m = _rwZahlRe.firstMatch(rest);
    if (m != null) {
      t.add(RwZeichen.zahl(rwZahl(m.group(0)!), m.group(0)!));
      i += m.group(0)!.length;
      continue;
    }
    if ((c == 'x' || c == 'X') && vor != null && (vor.n != null || vor.p == ')') && _rwMalX.hasMatch(rest)) {
      t.add(const RwZeichen.op('*'));
      i++;
      continue;
    }
    m = _rwUmkehr.firstMatch(rest);
    if (m != null) {
      mal();
      t.add(RwZeichen.funktion('a${m.group(1)!.toLowerCase()}'));
      i += m.group(0)!.length;
      continue;
    }
    m = _rwWort.firstMatch(rest);
    if (m != null) {
      final w = m.group(0)!.toLowerCase();
      if (w == 'pi') {
        mal();
        t.add(const RwZeichen.pi());
      } else if (_rwFn.containsKey(w)) {
        mal();
        t.add(RwZeichen.funktion(_rwFn[w]!));
      }
      i += m.group(0)!.length;
      continue;
    }
    if (c == '=') break;
    if (c == 'π') {
      mal();
      t.add(const RwZeichen.pi());
    } else if (c == '+') {
      t.add(const RwZeichen.op('+'));
    } else if ('-−–'.contains(c)) {
      t.add(const RwZeichen.op('-'));
    } else if ('*·×⋅∙'.contains(c)) {
      t.add(const RwZeichen.op('*'));
    } else if ('/÷:'.contains(c)) {
      t.add(const RwZeichen.op('/'));
    } else if (c == '^') {
      t.add(const RwZeichen.op('^'));
    } else if (c == '(') {
      mal();
      t.add(const RwZeichen.klammer('('));
    } else if (c == ')') {
      t.add(const RwZeichen.klammer(')'));
    } else if (c == '%') {
      t.add(const RwZeichen.prozent());
    } else if (c == '²') {
      t.add(const RwZeichen.potenz(2));
    } else if (c == '³') {
      t.add(const RwZeichen.potenz(3));
    } else if (c == '√') {
      mal();
      t.add(const RwZeichen.funktion('sqrt'));
    } else {
      return null;
    }
    i++;
  }
  return t;
}

/// Winkelfunktionen rechnen in Grad, wie in den Prüfungen („cos 30°“).
double rwFunktion(String f, double x) {
  const grad = math.pi / 180;
  double glatt(double v) => v.abs() < 1e-12 ? 0 : v;
  switch (f) {
    case 'sqrt':
      return math.sqrt(x);
    case 'sin':
      return glatt(math.sin(x * grad));
    case 'cos':
      return glatt(math.cos(x * grad));
    case 'tan':
      return ((((x - 90) % 180) + 180) % 180).abs() < 1e-9 ? double.nan : glatt(math.tan(x * grad));
    case 'asin':
      return math.asin(x) / grad;
    case 'acos':
      return math.acos(x) / grad;
    case 'atan':
      return math.atan(x) / grad;
  }
  return double.nan;
}

class _RwFehler implements Exception {
  const _RwFehler();
}

/// Rekursiver Abstieg: Summe → Produkt → Vorzeichen → Potenz → nachgestelltes
/// `%`/`²`/`³` → Zahl, Klammer oder Funktion.
class _RwParser {
  final List<RwZeichen> t;
  int i = 0;
  _RwParser(this.t);

  RwZeichen? get k => i < t.length ? t[i] : null;

  int _zu(int a) {
    var d = 0;
    for (var j = a; j < t.length; j++) {
      if (t[j].p == '(') {
        d++;
      } else if (t[j].p == ')' && --d == 0) {
        return j;
      }
    }
    return -1;
  }

  /// Steht zwischen [a] und [b] nur ein Prozentsatz (Zahl oder Klammer, direkt
  /// gefolgt von `%`)? Dann ist er ein Anteil des Werts davor.
  bool _nurProzent(int a, int b) {
    if (b - a < 2 || !t[b - 1].pc) return false;
    if (b - a == 2) return t[a].n != null;
    return t[a].p == '(' && _zu(a) == b - 2;
  }

  double summe() {
    var v = produkt();
    while (k != null && (k!.o == '+' || k!.o == '-')) {
      final o = t[i++].o;
      final a = i;
      var w = produkt();
      if (_nurProzent(a, i)) w = v * w;
      v = o == '+' ? v + w : v - w;
    }
    return v;
  }

  double produkt() {
    var v = vorzeichen();
    while (k != null && (k!.o == '*' || k!.o == '/')) {
      final o = t[i++].o;
      final w = vorzeichen();
      v = o == '*' ? v * w : v / w;
    }
    return v;
  }

  double vorzeichen() {
    final x = k;
    if (x != null && (x.o == '-' || x.o == '+')) {
      i++;
      final v = vorzeichen();
      return x.o == '-' ? -v : v;
    }
    return potenz();
  }

  double potenz() {
    var v = nachsatz();
    if (k != null && k!.o == '^') {
      i++;
      v = math.pow(v, vorzeichen()).toDouble();
    }
    return v;
  }

  double nachsatz() {
    var v = grund();
    for (;;) {
      final x = k;
      if (x != null && x.pc) {
        i++;
        v = v / 100;
      } else if (x != null && x.pw != null) {
        i++;
        v = math.pow(v, x.pw!).toDouble();
      } else {
        return v;
      }
    }
  }

  double grund() {
    if (i >= t.length) throw const _RwFehler();
    final x = t[i++];
    if (x.n != null) return x.n!;
    if (x.f != null) return rwFunktion(x.f!, nachsatz());
    if (x.p == '(') {
      final v = summe();
      if (k == null || k!.p != ')') throw const _RwFehler();
      i++;
      return v;
    }
    throw const _RwFehler();
  }
}

/// Rechnet zerlegte Zeichen aus: Punkt vor Strich, Klammern, Potenz, Wurzel,
/// Winkel, Prozent. Prozent wie auf dem Tischrechner: Steht rechts von Plus
/// oder Minus nur ein Prozentsatz, ist er ein Anteil des Werts davor –
/// „200 + 19 %“ = 238, „1.000 − 10 % − 2 %“ = 882. Sonst ist 19 % = 0,19
/// („30.250 · 6 %“ = 1.815). Ungültig oder unvollständig: `NaN`.
double rwAuswerten(List<RwZeichen>? t) {
  if (t == null || t.isEmpty) return double.nan;
  final p = _RwParser(t);
  try {
    final v = p.summe();
    return (p.i == t.length && v.isFinite) ? v : double.nan;
  } on _RwFehler {
    return double.nan;
  }
}

/// Text rechnen – `NaN`, wenn die Rechnung ungültig oder unvollständig ist.
double rechne(String s) => rwAuswerten(rwTokens(s));

/// `Math.round` wie im Web (halbe Werte aufwärts).
double _jsRunden(double x) => (x + 0.5).floorToDouble();

/// Zahl im deutschen Format mit Tausenderpunkt: mindestens [min], höchstens
/// [max] Nachkommastellen (wie `toLocaleString('de-DE')`).
String deZahl(double v, {int min = 0, int max = 4}) {
  if (!v.isFinite) return '';
  final s = v.abs().toStringAsFixed(max);
  final punkt = s.indexOf('.');
  final ganz = punkt < 0 ? s : s.substring(0, punkt);
  var nach = punkt < 0 ? '' : s.substring(punkt + 1);
  while (nach.length > min && nach.endsWith('0')) {
    nach = nach.substring(0, nach.length - 1);
  }
  final b = StringBuffer();
  for (var i = 0; i < ganz.length; i++) {
    if (i > 0 && (ganz.length - i) % 3 == 0) b.write('.');
    b.write(ganz[i]);
  }
  final out = nach.isEmpty ? b.toString() : '$b,$nach';
  return v < 0 ? '-$out' : out;
}

/// Ergebnis auf Deutsch, höchstens 4 Nachkommastellen, Minus als „−“; bei
/// Euro mit Cent, sobald Cent anfallen.
String rwFmt(double v, [String einheit = '']) {
  if (!v.isFinite) return '';
  final r = _jsRunden(v * 1e6) / 1e6;
  final cent = einheit.contains('€') && _jsRunden(r * 100) != _jsRunden(r) * 100;
  final s = cent ? deZahl(r, min: 2, max: 2) : deZahl(r, max: 4);
  return s.startsWith('-') ? '−${s.substring(1)}' : s;
}

/// Eine eingegebene Zahl mit Tausenderpunkt; die getippten Nachkommastellen
/// bleiben.
String rwZahlText(String raw) {
  final v = rwZahl(raw);
  if (!v.isFinite) return raw;
  var m = RegExp(r',(\d+)$').firstMatch(raw);
  if (m == null && !_rwTausender.hasMatch(raw)) m = RegExp(r'\.(\d+)$').firstMatch(raw);
  final d = m == null ? 0 : m.group(1)!.length;
  return deZahl(v, min: d, max: d);
}

const _rwZeichenText = {'+': '+', '-': '−', '*': '·', '/': '÷'};

/// Rechnung so, wie sie auf dem Prüfungsbogen stünde: „4.400 ÷ 22“.
String rwSchoen(String s) {
  final t = rwTokens(s);
  if (t == null) return s.trim();
  final o = StringBuffer();
  RwZeichen? vor;
  for (var j = 0; j < t.length; j++) {
    final x = t[j];
    if (x.zeit != null) {
      o.write('${x.zeit![0]} h ${x.zeit![1] < 10 ? '0' : ''}${x.zeit![1]} min');
    } else if (x.raw == 'π') {
      o.write('π');
    } else if (x.n != null) {
      final grad = vor != null && (vor.f == 'sin' || vor.f == 'cos' || vor.f == 'tan');
      o.write('${rwZahlText(x.raw)}${grad ? '°' : ''}');
    } else if (x.f != null && x.f != 'sqrt') {
      final name = x.f!.startsWith('a') ? '${x.f!.substring(1)}⁻¹' : x.f!;
      o.write('$name${(j + 1 < t.length && t[j + 1].p == '(') ? '' : ' '}');
    } else if (x.o != null) {
      final unaer = (x.o == '-' || x.o == '+') && (vor == null || vor.o != null || vor.p == '(' || vor.f != null);
      if (unaer) {
        o.write(x.o == '-' ? '−' : '+');
      } else if (x.o == '^') {
        o.write('^');
      } else {
        o.write(' ${_rwZeichenText[x.o]} ');
      }
    } else if (x.p != null) {
      o.write(x.p);
    } else if (x.pc) {
      o.write(' %');
    } else if (x.pw != null) {
      o.write(x.pw == 2 ? '²' : '³');
    } else if (x.f != null) {
      o.write('√');
    }
    vor = x;
  }
  return o
      .toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('( ', '(')
      .replaceAll(' )', ')')
      .trim();
}

final _rwRechnet = RegExp(r'[-+−–·*×xX÷/:^%²³√(π]|sin|cos|tan|\d\s*h\s*\d', caseSensitive: false);

/// Eine Zeile des Rechenwegs als Text: `Bezeichnung: Rechnung = Ergebnis
/// Einheit`, bei einer bloßen Zahl `Bezeichnung: Ergebnis Einheit`. Eine
/// ungültige Rechnung bleibt unverändert stehen.
String rwZeileText(String l, String f, String u) {
  l = l.trim();
  f = f.trim();
  u = u.trim();
  if (f.isEmpty) return l;
  final v = rechne(f);
  final rechnet = _rwRechnet.hasMatch(f.replaceFirst(RegExp(r'^\s*[−–-]'), ''));
  final erg = v.isFinite ? '${rwFmt(v, u)}${u.isNotEmpty ? ' $u' : ''}' : '';
  final s = erg.isNotEmpty ? (rechnet ? '${rwSchoen(f)} = $erg' : erg) : f;
  return l.isNotEmpty ? '${l.replaceFirst(RegExp(r'\s*:?$'), ':')} $s' : s;
}
