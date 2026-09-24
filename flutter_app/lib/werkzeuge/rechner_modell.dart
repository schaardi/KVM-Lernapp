import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rechenkern.dart';

/// Ein Zeichen der Eingabe (Web: Element von `T`).
///
/// | `t`  | Inhalt |
/// |------|--------|
/// | `n`  | getippte Ziffern [s] („12,5“) oder fester Wert [v] (Ergebnis, Verlauf) |
/// | `z`  | Zeit: Stunden [h], Minuten [m] (bis zu 2 Ziffern) |
/// | `k`  | π |
/// | `o`  | Rechenzeichen [s] (`+ − × ÷ ^`); [u] = Vorzeichen-Minus |
/// | `(` `)` | Klammer |
/// | `f`  | Funktion [s] (`√ sin cos tan sin⁻¹ cos⁻¹ tan⁻¹`), öffnet eine Klammer |
/// | `%` `²` | nachgestellt |
class RkEintrag {
  final String t;
  String s;
  double? v;
  bool z;
  String h;
  String m;
  bool u;

  RkEintrag(this.t, {this.s = '', this.v, this.z = false, this.h = '', this.m = '', this.u = false});

  RkEintrag.zahl(String ziffern) : this('n', s: ziffern);
  RkEintrag.wert(double wert, {bool zeit = false}) : this('n', v: wert, z: zeit);
  RkEintrag.op(String zeichen, {bool vorzeichen = false}) : this('o', s: zeichen, u: vorzeichen);
  RkEintrag.fn(String name) : this('f', s: name);

  static const _arten = {'n', 'z', 'k', 'o', '(', ')', 'f', '%', '²'};

  Map<String, dynamic> toJson() => {
        't': t,
        if (t == 'n' && v == null) 's': s,
        if (t == 'o' || t == 'f') 's': s,
        if (v != null) 'v': v,
        if (z) 'z': true,
        if (t == 'z') 'h': h,
        if (t == 'z') 'm': m,
        if (u) 'u': true,
      };

  /// Liest einen gespeicherten Eintrag; `null`, wenn er nicht passt.
  static RkEintrag? ausJson(Object? j) {
    if (j is! Map) return null;
    final t = j['t'];
    if (t is! String || !_arten.contains(t)) return null;
    final v = j['v'];
    final e = RkEintrag(
      t,
      s: (j['s'] ?? '').toString(),
      v: v is num ? v.toDouble() : null,
      z: j['z'] == true,
      h: (j['h'] ?? '').toString(),
      m: (j['m'] ?? '').toString(),
      u: j['u'] == true,
    );
    if (t == 'n' && e.v == null && !RegExp(r'^\d*,?\d*$').hasMatch(e.s)) return null;
    if (t == 'n' && e.v == null && e.s.isEmpty) return null;
    if (t == 'z' && (!RegExp(r'^\d+$').hasMatch(e.h) || !RegExp(r'^\d{0,2}$').hasMatch(e.m))) return null;
    if (t == 'o' && !RechnerModell._ops.containsKey(e.s)) return null;
    if (t == 'f' && !RechnerModell._fns.containsKey(e.s)) return null;
    return e;
  }
}

/// Eine Rechnung im Verlauf: „4.400 ÷ 22“ = 200.
class VerlaufEintrag {
  final String a;
  final double v;
  final bool z;
  const VerlaufEintrag(this.a, this.v, this.z);

  Map<String, dynamic> toJson() => {'a': a, 'v': v, 'z': z};

  static VerlaufEintrag? ausJson(Object? j) {
    if (j is! Map || j['v'] is! num) return null;
    final v = (j['v'] as num).toDouble();
    if (!v.isFinite) return null;
    return VerlaufEintrag((j['a'] ?? '').toString(), v, j['z'] == true);
  }

  /// „= 3,25 (3 h 15 min)“
  String get wertText => '= ${fmtRechner(v)}${z ? ' (${fmtZeit(v)})' : ''}';
}

/// Teil der angezeigten Rechnung; [blass] = von selbst ergänzt (fehlende
/// Klammern, noch leere Minuten).
class AusdruckTeil {
  final String text;
  final bool blass;
  const AusdruckTeil(this.text, {this.blass = false});
  @override
  String toString() => blass ? '[$text]' : text;
}

enum ErgebnisArt { normal, blass, fehler }

/// Taschenrechner wie ein zugelassener Prüfungsrechner (FR-005 B–C) –
/// 1:1 nach der Web-App (`rkTaste`, `rkZiffer` … in index.html).
///
/// Die Eingabe ist eine Zeichenliste: ⌫, ± und √ wirken auf ganze Zahlen und
/// Klammern; nach „=“ beginnt eine Ziffer eine neue Rechnung, ein
/// Rechenzeichen rechnet mit dem Ergebnis weiter. Jede Rechnung landet im
/// Verlauf (25 Einträge). Gespeichert wird wie im Web unter `kvm_rechner`:
/// `{"T": [...], "v": [...], "fr": bool, "l": "…", "mini": bool}`.
class RechnerModell extends ChangeNotifier {
  RechnerModell();

  /// Der Rechner der App – Verlauf und Eingabe überleben Schließen und Neustart.
  static final RechnerModell instance = RechnerModell();

  static const String schluessel = 'kvm_rechner';
  static const int verlaufMax = 25;

  static const Map<String, String> _ops = {'+': '+', '−': '-', '×': '*', '÷': '/', '^': '^'};
  static const Map<String, String> _fns = {
    '√': 'sqrt',
    'sin': 'sin',
    'cos': 'cos',
    'tan': 'tan',
    'sin⁻¹': 'asin',
    'cos⁻¹': 'acos',
    'tan⁻¹': 'atan',
  };

  final List<RkEintrag> _t = [];
  bool _frisch = false;
  String _letzte = '';
  List<VerlaufEintrag> _verlauf = [];
  bool _inv = false;
  bool _mini = false;
  String _fehler = '';
  double? _zuletzt;
  int _wackeln = 0;
  SharedPreferences? _prefs;

  // ─────────────────────────── Speicher ───────────────────────────

  /// Lädt Eingabe, Verlauf und „eingeklappt“ (Web `rkLaden`).
  Future<void> laden() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final roh = _prefs!.getString(schluessel);
      _t.clear();
      _verlauf = [];
      _frisch = false;
      _letzte = '';
      _mini = false;
      if (roh != null && roh.isNotEmpty) {
        final d = jsonDecode(roh);
        if (d is Map) {
          final t = d['T'];
          if (t is List) {
            final liste = t.map(RkEintrag.ausJson).toList();
            if (liste.every((e) => e != null)) _t.addAll(liste.cast<RkEintrag>());
          }
          final v = d['v'];
          if (v is List) {
            final alle = v.map(VerlaufEintrag.ausJson).whereType<VerlaufEintrag>().toList();
            _verlauf = alle.length > verlaufMax ? alle.sublist(alle.length - verlaufMax) : alle;
          }
          _frisch = d['fr'] == true && _t.length == 1;
          _letzte = _frisch ? (d['l'] ?? '').toString() : '';
          _mini = d['mini'] == true;
        }
      }
    } catch (_) {
      // Kaputter Speicher: mit leerem Rechner beginnen.
      _t.clear();
      _verlauf = [];
      _frisch = false;
      _letzte = '';
    }
    _fehler = '';
    _inv = false;
    _zuletzt = null;
    _aktualisieren();
  }

  void _speichern() {
    final p = _prefs;
    if (p == null) return;
    p.setString(
        schluessel,
        jsonEncode({
          'T': [for (final e in _t) e.toJson()],
          'v': [for (final e in _verlauf) e.toJson()],
          'fr': _frisch,
          'l': _letzte,
          'mini': _mini,
        }));
  }

  /// Nach jeder Änderung (Web `rkZeigen`): letzten gültigen Wert merken,
  /// speichern, Anzeige neu bauen.
  void _aktualisieren() {
    final v = wert;
    if (_fehler.isEmpty && _t.isNotEmpty && v.isFinite) _zuletzt = v;
    _speichern();
    notifyListeners();
  }

  // ─────────────────────────── Zustand ───────────────────────────

  /// Die Zeichenliste (nur lesen; für Tests und Anzeige).
  List<RkEintrag> get eintraege => List.unmodifiable(_t);
  List<VerlaufEintrag> get verlauf => List.unmodifiable(_verlauf);
  bool get frisch => _frisch;
  bool get inv => _inv;
  bool get mini => _mini;
  String get fehler => _fehler;

  /// Zählt Fehler bei „=“ – die Anzeige wackelt, wenn er steigt.
  int get wackeln => _wackeln;

  RkEintrag? get _last => _t.isEmpty ? null : _t.last;

  static bool _ende(RkEintrag? x) =>
      x != null && (x.t == 'n' || x.t == 'z' || x.t == 'k' || x.t == ')' || x.t == '%' || x.t == '²');

  int _offen() {
    var d = 0;
    for (final x in _t) {
      if (x.t == '(' || x.t == 'f') {
        d++;
      } else if (x.t == ')') {
        d--;
      }
    }
    return d;
  }

  /// Anfang des letzten Operanden: Zahl, π, Zeit oder Klammer/Funktion samt
  /// % und ² (Web `rkOperand`); -1, wenn es keinen gibt.
  int _operand() {
    var j = _t.length - 1;
    while (j >= 0 && (_t[j].t == '%' || _t[j].t == '²')) {
      j--;
    }
    if (j < 0) return -1;
    if (_t[j].t == ')') {
      var d = 0;
      for (; j >= 0; j--) {
        if (_t[j].t == ')') {
          d++;
        } else if ((_t[j].t == '(' || _t[j].t == 'f') && --d == 0) {
          return j;
        }
      }
      return -1;
    }
    return (_t[j].t == 'n' || _t[j].t == 'z' || _t[j].t == 'k') ? j : -1;
  }

  static double _zahl(RkEintrag x) => x.v ?? rkZahl(x.s);

  /// Zeichenliste → Zeichen des Rechenkerns (Web `rkKern`); Zahlen in voller
  /// Genauigkeit, offene Klammern werden geschlossen.
  List<RkZeichen> kern() {
    final k = <RkZeichen>[];
    for (final x in _t) {
      switch (x.t) {
        case 'n':
          k.add(RkZeichen.zahl(_zahl(x)));
        case 'z':
          final m = int.tryParse(x.m) ?? 0;
          k.add(m > 59 ? const RkZeichen.leer() : RkZeichen.zahl(double.parse(x.h) + m / 60));
        case 'k':
          k.add(const RkZeichen.zahl(math.pi));
        case 'o':
          k.add(RkZeichen.op(_ops[x.s]!));
        case '(' || ')':
          k.add(RkZeichen.klammer(x.t));
        case 'f':
          k.add(RkZeichen.fn(_fns[x.s]!));
          k.add(const RkZeichen.klammer('('));
        case '%':
          k.add(const RkZeichen.prozent());
        case '²':
          k.add(const RkZeichen.hoch(2));
      }
    }
    for (var d = _offen(); d > 0; d--) {
      k.add(const RkZeichen.klammer(')'));
    }
    return k;
  }

  /// Wert der Rechnung (Web `rkWert`); `double.nan`, solange sie ungültig ist.
  double get wert {
    if (_frisch) return _t.isEmpty ? double.nan : _zahl(_t.first);
    if (_t.isEmpty) return double.nan;
    return auswerten(kern());
  }

  bool get hatZeit => _t.any((x) => x.t == 'z' || (x.t == 'n' && x.z));

  static String _zahlText(RkEintrag x) {
    if (x.v != null) return fmtRechner(x.v!);
    final p = x.s.split(',');
    final g = p[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return p.length > 1 ? '$g,${p[1]}' : g;
  }

  /// Die Rechnung (Web `rkAusdruck`): Zahlen mit Tausenderpunkt,
  /// Rechenzeichen mit Leerzeichen, Zeit als „6 h 45 min“ (nie „6:45“).
  /// Für die [anzeige] bleiben getippte Minuten wie getippt; fehlende
  /// Klammern und leere Minuten sind blass.
  List<AusdruckTeil> _ausdruck({required bool anzeige}) {
    final teile = <AusdruckTeil>[];
    void text(String s) {
      if (s.isEmpty) return;
      if (teile.isNotEmpty && !teile.last.blass) {
        teile[teile.length - 1] = AusdruckTeil(teile.last.text + s);
      } else {
        teile.add(AusdruckTeil(s));
      }
    }

    void geist(String s) => teile.add(AusdruckTeil(s, blass: anzeige));

    for (final x in _t) {
      switch (x.t) {
        case 'n':
          text(_zahlText(x));
        case 'z':
          text('${x.h} h ');
          if (x.m.isEmpty) {
            geist('00');
          } else {
            text(anzeige ? x.m : x.m.padLeft(2, '0'));
          }
          text(' min');
        case 'k':
          text('π');
        case 'o':
          text(x.u ? '−' : (x.s == '^' ? '^' : ' ${x.s} '));
        case '(' || ')':
          text(x.t);
        case 'f':
          text('${x.s}(');
        case '%':
          text(' %');
        case '²':
          text('²');
      }
    }
    final d = _offen();
    if (d > 0) geist(')' * d);
    if (teile.isEmpty) return teile;
    // Leerraum am Anfang und – wie im Web – am Ende, sofern dort nichts
    // Blasses steht.
    teile[0] = AusdruckTeil(teile.first.text.trimLeft(), blass: teile.first.blass);
    final l = teile.last;
    if (!l.blass) teile[teile.length - 1] = AusdruckTeil(l.text.trimRight());
    return teile.where((t) => t.text.isNotEmpty).toList();
  }

  /// Rechnung als Text im Stil des Rechenwegs („4.400 ÷ 22“, „10 h 00 min − 6 h 45 min“).
  String ausdruckText() => _ausdruck(anzeige: false).map((t) => t.text).join().trim();

  /// Zeile über dem Ergebnis: die Rechnung beim Tippen, nach „=“ „Rechnung =“.
  List<AusdruckTeil> get anzeigeZeile {
    if (_frisch) return _letzte.isEmpty ? const [] : [AusdruckTeil('$_letzte =')];
    return _ausdruck(anzeige: true);
  }

  /// Großes Ergebnis: live beim Tippen; ist die Rechnung gerade
  /// unvollständig, bleibt der letzte gültige Wert blass stehen.
  String get ergebnisText {
    if (_fehler.isNotEmpty) return _fehler;
    if (_t.isEmpty) return '0';
    final v = wert;
    if (v.isFinite) return fmtRechner(v);
    return _zuletzt != null ? fmtRechner(_zuletzt!) : '0';
  }

  ErgebnisArt get ergebnisArt {
    if (_fehler.isNotEmpty) return ErgebnisArt.fehler;
    if (_t.isEmpty) return ErgebnisArt.normal;
    return wert.isFinite ? ErgebnisArt.normal : ErgebnisArt.blass;
  }

  /// Zeitfeld links neben dem Ergebnis („3 h 15 min“), sobald eine Zeit in der
  /// Rechnung steckt.
  String? get zeitText {
    final v = wert;
    if (_fehler.isNotEmpty || !v.isFinite || !hatZeit) return null;
    return fmtZeit(v);
  }

  /// „Übernehmen“ ist möglich: gültiges Ergebnis, kein Fehler.
  bool get kannUebernehmen => _t.isNotEmpty && _fehler.isEmpty && wert.isFinite;

  /// Wert fürs Ergebnisfeld: ohne Tausenderpunkt, Minus als „-“ („1234,5“).
  String get uebernahmeWert => fmtRechner(wert, ohnePunkte: true).replaceAll('−', '-');

  /// Wert für Text und Rechenweg: mit Tausenderpunkt („1.234,5“).
  String get uebernahmeWertMitPunkten => fmtRechner(wert);

  /// Die ganze Rechnung für eine leere Rechenweg-Zeile („4.400 ÷ 22“) – der
  /// Rechenweg rechnet sie nach (Web `rkUebernehmen`).
  String get rechnungText {
    if (_frisch) return _letzte.isNotEmpty ? _letzte : fmtRechner(wert);
    return ausdruckText();
  }

  // ─────────────────────────── Tasten ───────────────────────────

  void _neu() {
    _t.clear();
    _frisch = false;
    _letzte = '';
  }

  void _weiter() {
    _frisch = false;
    _letzte = '';
  }

  void _mal() {
    if (_ende(_last)) _t.add(RkEintrag.op('×'));
  }

  void _ziffer(String d) {
    if (_frisch) _neu();
    final x = _last;
    if (x != null && x.t == 'n' && x.v == null) {
      if (x.s == '0') {
        x.s = d;
      } else if (x.s.replaceAll(RegExp(r'\D'), '').length < 15) {
        x.s += d;
      }
    } else if (x != null && x.t == 'z') {
      if (x.m.length < 2) x.m += d;
    } else {
      _mal();
      _t.add(RkEintrag.zahl(d));
    }
  }

  void _komma() {
    if (_frisch) _neu();
    final x = _last;
    if (x != null && x.t == 'n' && x.v == null) {
      if (!x.s.contains(',')) x.s += ',';
    } else if (!(x != null && x.t == 'z')) {
      _mal();
      _t.add(RkEintrag.zahl('0,'));
    }
  }

  void _operator(String s) {
    if (_frisch) _weiter();
    final x = _last;
    if (x == null || x.t == '(' || x.t == 'f') {
      if (s == '−') _t.add(RkEintrag.op('−', vorzeichen: true));
      return;
    }
    if (x.t == 'o') {
      if (x.u) {
        _t.removeLast();
        _operator(s);
        return;
      }
      if (s == '−' && (x.s == '×' || x.s == '÷' || x.s == '^')) {
        _t.add(RkEintrag.op('−', vorzeichen: true));
        return;
      }
      x.s = s;
      return;
    }
    _t.add(RkEintrag.op(s));
  }

  void _nachsatz(String s) {
    if (_frisch) _weiter();
    final x = _last;
    if (!_ende(x) || (s == '%' && x!.t == '%')) return;
    _t.add(RkEintrag(s));
  }

  void _klammerAuf() {
    if (_frisch) _neu();
    _mal();
    _t.add(RkEintrag('('));
  }

  void _klammerZu() {
    if (!_frisch && _offen() > 0 && _ende(_last)) _t.add(RkEintrag(')'));
  }

  void _pi() {
    if (_frisch) _neu();
    _mal();
    _t.add(RkEintrag('k'));
  }

  /// √, sin …: nach „=“ auf das Ergebnis, hinter einer Zahl oder Klammer auf
  /// diese („16 √“ = 4, „5 + 9 √“ = 8), sonst als Anfang „√(“.
  void _funktion(String name) {
    if (_frisch) {
      _weiter();
      _t.insert(0, RkEintrag.fn(name));
      _t.add(RkEintrag(')'));
      return;
    }
    if (_ende(_last)) {
      final a = _operand();
      if (a < 0) return;
      if (_t[a].t == '(' && _last!.t == ')') {
        _t[a] = RkEintrag.fn(name);
        return;
      }
      _t.insert(a, RkEintrag.fn(name));
      _t.add(RkEintrag(')'));
      return;
    }
    _t.add(RkEintrag.fn(name));
  }

  /// ± wechselt das Vorzeichen der letzten Zahl; „5 − 9“ wird „5 − (−9)“, ein
  /// zweites ± hebt das auf.
  void _vorzeichen() {
    if (_frisch) {
      final erst = _t.first;
      final r = -_zahl(erst);
      _t
        ..clear()
        ..add(RkEintrag.wert(r, zeit: erst.z));
      _weiter();
      return;
    }
    final x = _last;
    if (!_ende(x)) {
      if (x != null && x.t == 'o' && x.u) {
        _t.removeLast();
      } else if (x != null && x.t == 'o' && (x.s == '+' || x.s == '−')) {
        _t
          ..add(RkEintrag('('))
          ..add(RkEintrag.op('−', vorzeichen: true));
      } else {
        _t.add(RkEintrag.op('−', vorzeichen: true));
      }
      return;
    }
    final a = _operand();
    final e = _t.length - 1;
    if (a < 0) return;
    if (a == e && _t[a].t == 'n' && _t[a].v != null) {
      _t[a] = RkEintrag.wert(-_t[a].v!, zeit: _t[a].z);
      return;
    }
    if (_t[a].t == '(' && a + 1 < _t.length && _t[a + 1].u && _t[e].t == ')') {
      _t
        ..removeLast()
        ..removeRange(a, a + 2);
      return;
    }
    final vor = a > 0 ? _t[a - 1] : null;
    if (vor != null && vor.t == 'o' && vor.u) {
      _t.removeAt(a - 1);
      return;
    }
    if (vor == null || vor.t == '(' || vor.t == 'f' || (vor.s != '+' && vor.s != '−')) {
      _t.insert(a, RkEintrag.op('−', vorzeichen: true));
      return;
    }
    _t
      ..insertAll(a, [RkEintrag('('), RkEintrag.op('−', vorzeichen: true)])
      ..add(RkEintrag(')'));
  }

  /// „h min“: aus „6“ wird „6 h __ min“; die nächsten zwei Ziffern sind Minuten.
  void _zeit() {
    if (_frisch) _neu();
    final x = _last;
    if (x != null && x.t == 'n' && x.v == null && RegExp(r'^\d+$').hasMatch(x.s)) {
      _t[_t.length - 1] = RkEintrag('z', h: x.s, m: '');
      return;
    }
    if (_ende(x)) return;
    _t.add(RkEintrag('z', h: '0', m: ''));
  }

  void _zurueck() {
    if (_frisch) {
      _neu();
      return;
    }
    final x = _last;
    if (x == null) return;
    if (x.t == 'n' && x.v == null) {
      x.s = x.s.substring(0, x.s.length - 1);
      if (x.s.isEmpty) _t.removeLast();
      return;
    }
    if (x.t == 'z') {
      if (x.m.isNotEmpty) {
        x.m = x.m.substring(0, x.m.length - 1);
      } else {
        _t[_t.length - 1] = RkEintrag.zahl(x.h);
      }
      return;
    }
    _t.removeLast();
  }

  void _gleich() {
    if (_frisch || _t.isEmpty) return;
    final v = wert;
    if (!v.isFinite) {
      _fehler = _t.any((x) => x.t == 'z' && (int.tryParse(x.m) ?? 0) > 59)
          ? 'Minuten gehen nur bis 59'
          : (_ende(_last) ? 'Nicht definiert' : 'Rechnung unvollständig');
      _wackeln++;
      return;
    }
    final text = ausdruckText();
    final z = hatZeit;
    if (!(_t.length == 1 && _t.first.t == 'n')) {
      _verlauf = [..._verlauf, VerlaufEintrag(text, v, z)];
      if (_verlauf.length > verlaufMax) _verlauf = _verlauf.sublist(_verlauf.length - verlaufMax);
    }
    _letzte = text;
    _t
      ..clear()
      ..add(RkEintrag.wert(v, zeit: z));
    _frisch = true;
  }

  /// Eine Taste (Web `rkTaste`): Ziffern, `,`, `+ − × ÷ ^`, `%`, `²`, `(`,
  /// `)`, `π`, `√`, `sin cos tan`, `inv`, `zeit`, `±`, `⌫`, `C`, `=`.
  void taste(String k) {
    _fehler = '';
    if (RegExp(r'^\d$').hasMatch(k)) {
      _ziffer(k);
    } else if (k == ',') {
      _komma();
    } else if (_ops.containsKey(k)) {
      _operator(k);
    } else if (k == '%' || k == '²') {
      _nachsatz(k);
    } else if (k == '(') {
      _klammerAuf();
    } else if (k == ')') {
      _klammerZu();
    } else if (k == 'π') {
      _pi();
    } else if (k == '√') {
      _funktion('√');
    } else if (k == 'sin' || k == 'cos' || k == 'tan') {
      _funktion(k + (_inv ? '⁻¹' : ''));
      _inv = false;
    } else if (k == 'inv') {
      _inv = !_inv;
    } else if (k == 'zeit') {
      _zeit();
    } else if (k == '±') {
      _vorzeichen();
    } else if (k == '⌫') {
      _zurueck();
    } else if (k == 'C') {
      _neu();
      _zuletzt = null;
    } else if (k == '=') {
      _gleich();
    }
    _aktualisieren();
  }

  /// Mehrere Tasten nacheinander (Tests, Tastatur).
  void tasten(Iterable<String> ks) {
    for (final k in ks) {
      taste(k);
    }
  }

  /// Ergebnis aus dem Verlauf als festen Wert einsetzen (Web `rkEinsetzen`).
  void einsetzen(int index) {
    if (index < 0 || index >= _verlauf.length) return;
    final e = _verlauf[index];
    _fehler = '';
    if (_frisch) _neu();
    _mal();
    _t.add(RkEintrag.wert(e.v, zeit: e.z));
    _aktualisieren();
  }

  void verlaufLeeren() {
    _verlauf = [];
    _aktualisieren();
  }

  void miniUmschalten() {
    _mini = !_mini;
    _aktualisieren();
  }

  void aufklappen() {
    if (!_mini) return;
    _mini = false;
    _aktualisieren();
  }

  /// Alles zurück auf Anfang, Verlauf eingeschlossen (für Tests).
  @visibleForTesting
  void zuruecksetzen() {
    _neu();
    _verlauf = [];
    _inv = false;
    _mini = false;
    _fehler = '';
    _zuletzt = null;
    _wackeln = 0;
    _aktualisieren();
  }
}
