import 'dart:math' as math;

/// Rechenkern für Taschenrechner und Rechenweg (FR-003 B, FR-005 A).
///
/// Zeile für Zeile aus der Web-App übernommen (`index.html`: `rwZahl`,
/// `rwTokens`, `rwFunktion`, `rwAuswerten`, `rwFmt`, `rwZahlText`, `rwSchoen`,
/// `rwZeileText`, `rkFmt`, `rkFmtZeit`, `parseCalcNum`). Kein `eval`:
/// rekursiver Abstieg mit Punkt vor Strich, Klammern, Potenz, Wurzel,
/// Winkeln in Grad, Zeitangaben und Prozent wie auf dem Tischrechner
/// („200 + 19 %“ = 238).
///
/// Ungültige Rechnungen ergeben `double.nan` – wie `NaN` im Web.

/// Ein Zeichen des Rechenkerns: Zahl (auch π und Zeit), Rechenzeichen,
/// Funktion, Klammer, nachgestelltes Prozent oder Hochzahl.
class RkZeichen {
  /// Zahl (auch π und Zeitangaben in Stunden).
  final double? n;

  /// Eingegebener Text der Zahl („4.400“, „π“, „6 h 45 min“).
  final String? roh;

  /// Zeitangabe: Stunden (Ziffern wie eingegeben) …
  final String? zeitStunden;

  /// … und Minuten (0–59).
  final int? zeitMinuten;

  /// Rechenzeichen: `+ - * / ^`.
  final String? o;

  /// Funktion: `sqrt sin cos tan asin acos atan`.
  final String? f;

  /// Klammer: `(` oder `)`.
  final String? p;

  /// Nachgestelltes Prozent.
  final bool pc;

  /// Nachgestellte Hochzahl (2 oder 3).
  final int? pw;

  const RkZeichen._({
    this.n,
    this.roh,
    this.zeitStunden,
    this.zeitMinuten,
    this.o,
    this.f,
    this.p,
    this.pc = false,
    this.pw,
  });

  const RkZeichen.zahl(double wert, {String? roh, String? stunden, int? minuten})
      : this._(n: wert, roh: roh, zeitStunden: stunden, zeitMinuten: minuten);
  const RkZeichen.op(String o) : this._(o: o);
  const RkZeichen.fn(String f) : this._(f: f);
  const RkZeichen.klammer(String p) : this._(p: p);
  const RkZeichen.prozent() : this._(pc: true);
  const RkZeichen.hoch(int pw) : this._(pw: pw);

  /// Leeres Zeichen – macht eine Rechnung ungültig (Minuten über 59 im Rechner).
  const RkZeichen.leer() : this._();

  bool get istZeit => zeitStunden != null;

  @override
  String toString() {
    if (n != null) return roh ?? '$n';
    return o ?? f ?? p ?? (pc ? '%' : (pw != null ? '^$pw' : '∅'));
  }
}

// ───────────────────────────── Zahlen lesen ──────────────────────────────────

final RegExp _tausender = RegExp(r'^\d{1,3}(\.\d{3})+$');
final RegExp _parseFloatRe = RegExp(r'^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?');

/// Wie JavaScripts `parseFloat`: liest die längste Zahl am Anfang.
double _parseFloat(String s) {
  final m = _parseFloatRe.firstMatch(s.trimLeft());
  if (m == null) return double.nan;
  return double.tryParse(m.group(0)!) ?? double.nan;
}

/// Zahl aus der Rechnung (Web `rwZahl`): „1.234,5“, „1234.5“ und „4.400“
/// (Tausenderpunkt) werden richtig gelesen; „,5“ ist 0,5.
double rkZahl(String t) {
  t = t.replaceFirst(RegExp(r'^,'), '0,');
  if (t.contains(',')) return _parseFloat(t.replaceAll('.', '').replaceFirst(',', '.'));
  if (_tausender.hasMatch(t)) return _parseFloat(t.replaceAll('.', ''));
  return _parseFloat(t);
}

/// Zahl aus einem Antwortfeld (Web `parseCalcNum`): „4.400“ = 4400,
/// „1.5“ = 1,5, „1.234,5“ = 1234,5; „−“ (U+2212) und „–“ zählen als Minus.
/// `null`, wenn keine Zahl darin steht.
double? leseZahl(String s) {
  var t = s.trim().replaceAll(RegExp('[−–]'), '-').replaceAll(RegExp(r'[^0-9.,\-]'), '');
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceFirst(',', '.');
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', '');
  }
  final v = _parseFloat(t);
  return v.isFinite ? v : null;
}

// ───────────────────────────── Zerlegen ──────────────────────────────────────

final RegExp _einheitenBruch = RegExp(r'[A-Za-zÄÖÜäöüß€$°]+\s*/\s*[A-Za-zÄÖÜäöüß€$°]+');
final RegExp _leer = RegExp(r'\s');
final RegExp _zeitRe = RegExp(r'(\d+)\s*h\s*(\d{1,2})(?![\d.,])(?:\s*min\b)?');
final RegExp _zahlRe = RegExp(r'(?:\d[\d.]*(?:,\d+)?|,\d+)');
final RegExp _malXRe = RegExp(r'[xX]\s*[\d(√π]');
final RegExp _umkehrRe = RegExp(r'(sin|cos|tan)\s*⁻¹', caseSensitive: false);
final RegExp _wortRe = RegExp(r'[A-Za-zÄÖÜäöüß€$°]+');

const Map<String, String> _funktionen = {
  'sin': 'sin',
  'cos': 'cos',
  'tan': 'tan',
  'arcsin': 'asin',
  'arccos': 'acos',
  'arctan': 'atan',
};

/// Zerlegt eine Rechnung in Zeichen (Web `rwTokens`): Zahlen, `+ − · × * ÷ /
/// : ^ ( ) % ² ³ √`, π, sin/cos/tan in Grad samt Umkehrung („sin⁻¹“,
/// „arcsin“), Zeitangaben („6 h 45“ = 6,75 Stunden) und „x“ als Mal zwischen
/// Zahlen. Vor π, √, einer Funktion und „(“ darf das Mal fehlen („2π“).
/// Einheiten („km/h“, „€“) werden überlesen; hinter „=“ steht schon das
/// Ergebnis. `null` bei unbekannten Zeichen oder Minuten über 59.
List<RkZeichen>? zerlege(String s) {
  s = s.replaceAll(_einheitenBruch, ' ');
  final t = <RkZeichen>[];
  void mal() {
    if (t.isEmpty) return;
    final v = t.last;
    if (v.n != null || v.p == ')' || v.pc || v.pw != null) t.add(const RkZeichen.op('*'));
  }

  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (_leer.hasMatch(c)) {
      i++;
      continue;
    }
    final zeit = _zeitRe.matchAsPrefix(s, i);
    if (zeit != null) {
      final minuten = int.parse(zeit.group(2)!);
      if (minuten > 59) return null;
      final stunden = zeit.group(1)!;
      t.add(RkZeichen.zahl(double.parse(stunden) + minuten / 60,
          roh: zeit.group(0), stunden: stunden, minuten: minuten));
      i = zeit.end;
      continue;
    }
    final zahl = _zahlRe.matchAsPrefix(s, i);
    if (zahl != null) {
      t.add(RkZeichen.zahl(rkZahl(zahl.group(0)!), roh: zahl.group(0)));
      i = zahl.end;
      continue;
    }
    if ((c == 'x' || c == 'X') &&
        t.isNotEmpty &&
        (t.last.n != null || t.last.p == ')') &&
        _malXRe.matchAsPrefix(s, i) != null) {
      t.add(const RkZeichen.op('*'));
      i++;
      continue;
    }
    final umkehr = _umkehrRe.matchAsPrefix(s, i);
    if (umkehr != null) {
      mal();
      t.add(RkZeichen.fn('a${umkehr.group(1)!.toLowerCase()}'));
      i = umkehr.end;
      continue;
    }
    final wort = _wortRe.matchAsPrefix(s, i);
    if (wort != null) {
      final w = wort.group(0)!.toLowerCase();
      if (w == 'pi') {
        mal();
        t.add(const RkZeichen.zahl(math.pi, roh: 'π'));
      } else if (_funktionen.containsKey(w)) {
        mal();
        t.add(RkZeichen.fn(_funktionen[w]!));
      }
      // Andere Wörter sind Einheiten und werden überlesen.
      i = wort.end;
      continue;
    }
    if (c == '=') break;
    switch (c) {
      case 'π':
        mal();
        t.add(const RkZeichen.zahl(math.pi, roh: 'π'));
      case '+':
        t.add(const RkZeichen.op('+'));
      case '-' || '−' || '–':
        t.add(const RkZeichen.op('-'));
      case '*' || '·' || '×' || '⋅' || '∙':
        t.add(const RkZeichen.op('*'));
      case '/' || '÷' || ':':
        t.add(const RkZeichen.op('/'));
      case '^':
        t.add(const RkZeichen.op('^'));
      case '(':
        mal();
        t.add(const RkZeichen.klammer('('));
      case ')':
        t.add(const RkZeichen.klammer(')'));
      case '%':
        t.add(const RkZeichen.prozent());
      case '²':
        t.add(const RkZeichen.hoch(2));
      case '³':
        t.add(const RkZeichen.hoch(3));
      case '√':
        mal();
        t.add(const RkZeichen.fn('sqrt'));
      default:
        return null;
    }
    i++;
  }
  return t;
}

// ───────────────────────────── Rechnen ───────────────────────────────────────

const double _grad = math.pi / 180;

double _glatt(double v) => v.abs() < 1e-12 ? 0 : v;

/// Winkelfunktionen rechnen in Grad, wie in den Prüfungen („cos 30°“)
/// (Web `rwFunktion`). `tan 90` ist ungültig, Werte unter 10⁻¹² werden 0.
double rkFunktion(String f, double x) {
  switch (f) {
    case 'sqrt':
      return math.sqrt(x);
    case 'sin':
      return _glatt(math.sin(x * _grad));
    case 'cos':
      return _glatt(math.cos(x * _grad));
    case 'tan':
      // JavaScript-Rest: Vorzeichen folgt dem Dividenden.
      final r = ((x - 90).remainder(180) + 180).remainder(180);
      return r.abs() < 1e-9 ? double.nan : _glatt(math.tan(x * _grad));
    case 'asin':
      return math.asin(x) / _grad;
    case 'acos':
      return math.acos(x) / _grad;
    case 'atan':
      return math.atan(x) / _grad;
  }
  return double.nan;
}

/// Potenz wie `Math.pow` in JavaScript (±1 hoch ∞ und x hoch NaN sind NaN).
double _hoch(double a, double b) {
  if (b.isNaN || (b.isInfinite && a.abs() == 1)) return double.nan;
  return math.pow(a, b).toDouble();
}

class _Abbruch implements Exception {
  const _Abbruch();
}

class _Auswerter {
  final List<RkZeichen> t;
  int i = 0;
  _Auswerter(this.t);

  RkZeichen? get k => i < t.length ? t[i] : null;

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

  /// Steht rechts von + oder − nur ein Prozentsatz (Zahl oder Klammer, direkt
  /// gefolgt von %)?
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
      v = _hoch(v, vorzeichen());
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
        v = _hoch(v, x.pw!.toDouble());
      } else {
        return v;
      }
    }
  }

  double grund() {
    if (i >= t.length) throw const _Abbruch();
    final x = t[i++];
    if (x.n != null) return x.n!;
    if (x.f != null) return rkFunktion(x.f!, nachsatz());
    if (x.p == '(') {
      final v = summe();
      if (k == null || k!.p != ')') throw const _Abbruch();
      i++;
      return v;
    }
    throw const _Abbruch();
  }
}

/// Rechnet zerlegte Zeichen aus (Web `rwAuswerten`): Punkt vor Strich,
/// Klammern, Potenz, Wurzel, Winkel, Prozent. Prozent wie auf dem
/// Tischrechner: Steht rechts von Plus oder Minus nur ein Prozentsatz, ist er
/// ein Anteil des Werts davor – „200 + 19 %“ = 238, „1.000 − 10 % − 2 %“ =
/// 882. Sonst ist 19 % = 0,19 („30.250 · 6 %“ = 1.815).
/// Ungültig (unvollständig, nicht endlich) → `double.nan`.
double auswerten(List<RkZeichen>? t) {
  if (t == null || t.isEmpty) return double.nan;
  final a = _Auswerter(t);
  try {
    final v = a.summe();
    return (a.i == t.length && v.isFinite) ? v : double.nan;
  } on _Abbruch {
    return double.nan;
  } on StackOverflowError {
    return double.nan;
  }
}

/// Rechnet eine Rechnung als Text aus (Web `rwRechne`); `double.nan`, wenn sie
/// ungültig ist.
double rechne(String s) => auswerten(zerlege(s));

// ───────────────────────────── Zahlen zeigen ─────────────────────────────────

/// Rundung wie `Math.round` in JavaScript (halbe Werte Richtung +∞).
double jsRunden(double x) {
  final f = x.floorToDouble();
  return (x - f >= 0.5) ? f + 1 : f;
}

final RegExp _gruppenRe = RegExp(r'\B(?=(\d{3})+(?!\d))');

String _gruppiere(String ziffern) => ziffern.replaceAllMapped(_gruppenRe, (_) => '.');

String _ganzText(double a) => a < 1e18 ? a.toInt().toString() : BigInt.from(a).toString();

/// Wie `toLocaleString('de-DE', {minimumFractionDigits, maximumFractionDigits})`:
/// Komma, Tausenderpunkte, Minus als „-“ (Aufrufer tauschen es gegen „−“).
String _deFest(double x, {int min = 0, required int max, bool gruppen = true}) {
  final neg = x.isNegative;
  final a = x.abs();
  max = max.clamp(0, 20);
  min = min.clamp(0, max);
  var ganz = '';
  var bruch = '';
  if (a >= 1e21) {
    ganz = _ganzText(a);
    bruch = '0' * max;
  } else {
    final s = a.toStringAsFixed(max);
    final p = s.indexOf('.');
    ganz = p < 0 ? s : s.substring(0, p);
    bruch = p < 0 ? '' : s.substring(p + 1);
  }
  while (bruch.length > min && bruch.endsWith('0')) {
    bruch = bruch.substring(0, bruch.length - 1);
  }
  if (gruppen) ganz = _gruppiere(ganz);
  final out = bruch.isEmpty ? ganz : '$ganz,$bruch';
  return neg ? '-$out' : out;
}

/// Wie `toLocaleString('de-DE', {maximumSignificantDigits})`: gerundet auf
/// [stellen] gültige Ziffern, ohne Exponent, ohne Nullen am Ende.
String _deSignifikant(double x, int stellen, {bool gruppen = true}) {
  final neg = x.isNegative;
  final e = x.abs().toStringAsExponential(stellen - 1);
  final teile = e.split('e');
  final ziffern = teile[0].replaceAll('.', '');
  final exp = int.parse(teile[1]);
  String ganz;
  String bruch;
  if (exp >= 0) {
    if (exp + 1 >= ziffern.length) {
      ganz = ziffern + '0' * (exp + 1 - ziffern.length);
      bruch = '';
    } else {
      ganz = ziffern.substring(0, exp + 1);
      bruch = ziffern.substring(exp + 1);
    }
  } else {
    ganz = '0';
    bruch = '0' * (-exp - 1) + ziffern;
  }
  bruch = bruch.replaceFirst(RegExp(r'0+$'), '');
  if (gruppen) ganz = _gruppiere(ganz);
  final out = bruch.isEmpty ? ganz : '$ganz,$bruch';
  return neg ? '-$out' : out;
}

String _minus(String s) => s.startsWith('-') ? '−${s.substring(1)}' : s;

/// Ergebnis im Rechenweg (Web `rwFmt`): deutsch, höchstens 4 Nachkommastellen,
/// Minus als „−“; mit Einheit „€“ genau 2 Nachkommastellen, sobald Cent
/// anfallen. Leer, wenn [v] nicht endlich ist.
String fmtErgebnis(double v, [String einheit = '']) {
  if (!v.isFinite) return '';
  final r = jsRunden(v * 1e6) / 1e6;
  final cent = einheit.contains('€') && jsRunden(r * 100) != jsRunden(r) * 100;
  return _minus(cent ? _deFest(r, min: 2, max: 2) : _deFest(r, max: 4));
}

/// Zahl so, wie sie eingegeben wurde, aber mit Tausenderpunkt und Komma
/// (Web `rwZahlText`): „7000“ → „7.000“, „1.5“ → „1,5“, „0,14“ bleibt.
String zahlText(String roh) {
  final v = rkZahl(roh);
  if (!v.isFinite) return roh;
  final m = RegExp(r',(\d+)$').firstMatch(roh) ??
      (!_tausender.hasMatch(roh) ? RegExp(r'\.(\d+)$').firstMatch(roh) : null);
  final d = m == null ? 0 : m.group(1)!.length;
  return _deFest(v, min: d, max: d);
}

const Map<String, String> _opText = {'+': '+', '-': '−', '*': '·', '/': '÷'};
const Set<String> _winkel = {'sin', 'cos', 'tan'};

/// Rechnung so, wie sie auf dem Prüfungsbogen stünde (Web `rwSchoen`):
/// „4.400 ÷ 22“, „cos 30° · 2.500“, „10 − 6 h 45 min“.
String schoen(String s) {
  final t = zerlege(s);
  if (t == null) return s.trim();
  final o = StringBuffer();
  RkZeichen? vor;
  for (var j = 0; j < t.length; j++) {
    final x = t[j];
    if (x.istZeit) {
      final m = x.zeitMinuten!;
      o.write('${int.tryParse(x.zeitStunden!) ?? x.zeitStunden} h ${m < 10 ? '0' : ''}$m min');
    } else if (x.roh == 'π') {
      o.write('π');
    } else if (x.n != null) {
      o.write(zahlText(x.roh ?? '${x.n}'));
      if (vor != null && _winkel.contains(vor.f)) o.write('°');
    } else if (x.f != null && x.f != 'sqrt') {
      o.write(x.f!.startsWith('a') ? '${x.f!.substring(1)}⁻¹' : x.f!);
      if (!(j + 1 < t.length && t[j + 1].p == '(')) o.write(' ');
    } else if (x.o != null) {
      final unaer = (x.o == '-' || x.o == '+') &&
          (vor == null || vor.o != null || vor.p == '(' || vor.f != null);
      if (unaer) {
        o.write(x.o == '-' ? '−' : '+');
      } else if (x.o == '^') {
        o.write('^');
      } else {
        o.write(' ${_opText[x.o]} ');
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

final RegExp _rechnetRe = RegExp(r'[-+−–·*×xX÷/:^%²³√(π]|sin|cos|tan|\d\s*h\s*\d', caseSensitive: false);

/// Eine Rechenweg-Zeile als Text (Web `rwZeileText`):
/// `Bezeichnung: Rechnung = Ergebnis Einheit`. Ist die Rechnung nur eine
/// Zahl, fehlt „Rechnung =“; ist sie ungültig, bleibt sie unverändert.
String zeileText({String l = '', String f = '', String u = ''}) {
  l = l.trim();
  f = f.trim();
  u = u.trim();
  if (f.isEmpty) return l;
  final v = rechne(f);
  final rechnet = _rechnetRe.hasMatch(f.replaceFirst(RegExp(r'^\s*[−–-]'), ''));
  final erg = v.isFinite ? '${fmtErgebnis(v, u)}${u.isNotEmpty ? ' $u' : ''}' : '';
  final s = erg.isNotEmpty ? (rechnet ? '${schoen(f)} = $erg' : erg) : f;
  return l.isNotEmpty ? '${l.replaceFirst(RegExp(r'\s*:?$'), ':')} $s' : s;
}

/// Zahl im Taschenrechner (Web `rkFmt`): deutsch, bis zu 12 gültige
/// Stellen, ganze Zahlen bis 10¹⁵ vollständig, Minus als „−“. Mit
/// [ohnePunkte] ohne Tausenderpunkte („1234,5“ fürs Ergebnisfeld).
String fmtRechner(double v, {bool ohnePunkte = false}) {
  if (!v.isFinite) return '–';
  if (v.abs() < 1e-12) v = 0;
  final ganz = v == v.truncateToDouble() && v.abs() < 1e15;
  return _minus(ganz
      ? _deFest(v, max: 0, gruppen: !ohnePunkte)
      : _deSignifikant(v, 12, gruppen: !ohnePunkte));
}

/// Stunden als „3 h 15 min“ (Web `rkFmtZeit`), Minuten gerundet – nie „3:15“,
/// denn im Rechenweg ist „:“ ein Geteilt-Zeichen.
String fmtZeit(double v) {
  final neg = v < 0;
  final a = v.abs();
  var h = (a + 1e-9).floorToDouble();
  var m = jsRunden((a - h) * 60).abs().toInt();
  if (m == 60) {
    h++;
    m = 0;
  }
  return '${neg ? '−' : ''}${_ganzText(h)} h ${m < 10 ? '0' : ''}$m min';
}
