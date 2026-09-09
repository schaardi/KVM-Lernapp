import 'dart:math' as math;

/// Rechenkern des Formelbuchs – wortgleich zur Web-Fassung in index.html und
/// zur Referenz in scripts/formeln/rechner.py.
///
/// Erlaubt sind + − · ÷ ^ ( ) , Zahlen, Variablen, die Konstante `pi` und die
/// Funktionen sqrt, sin, cos, tan, abs, min, max, round. Winkel in Grad.
class FormulaError implements Exception {
  final String message;
  const FormulaError(this.message);
  @override
  String toString() => message;
}

const Map<String, int> _fnArity = {
  'sqrt': 1, 'sin': 1, 'cos': 1, 'tan': 1, 'abs': 1, 'round': 1,
  'min': 2, 'max': 2,
};
const Map<String, double> _consts = {'pi': math.pi};

final RegExp _tokenRe =
    RegExp(r'\s*(\d+\.?\d*|[A-Za-z_][A-Za-z_0-9]*|\*\*|[-+*/^(),])');

List<String> tokenize(String s) {
  final out = <String>[];
  var i = 0;
  while (i < s.length) {
    final m = _tokenRe.matchAsPrefix(s, i);
    if (m == null) {
      if (s[i].trim().isEmpty) {
        i++;
        continue;
      }
      throw FormulaError('unerwartetes Zeichen „${s[i]}“');
    }
    out.add(m.group(1)!);
    i = m.end;
  }
  return out;
}

class _Parser {
  final List<String> t;
  final Map<String, double> vals;
  int i = 0;
  _Parser(this.t, this.vals);

  String? get _peek => i < t.length ? t[i] : null;

  String _take([String? want]) {
    final tok = _peek;
    if (want != null && tok != want) {
      throw FormulaError('erwartet „$want“, gefunden „${tok ?? '·'}“');
    }
    i++;
    return tok!;
  }

  double expr() {
    var x = term();
    while (_peek == '+' || _peek == '-') {
      final op = _take();
      final y = term();
      x = op == '+' ? x + y : x - y;
    }
    return x;
  }

  double term() {
    var x = faktor();
    while (_peek == '*' || _peek == '/') {
      final op = _take();
      final y = faktor();
      if (op == '/') {
        if (y == 0) throw const FormulaError('Division durch null');
        x = x / y;
      } else {
        x = x * y;
      }
    }
    return x;
  }

  double faktor() {
    final x = unaer();
    if (_peek == '^' || _peek == '**') {
      _take();
      return math.pow(x, faktor()).toDouble();
    }
    return x;
  }

  double unaer() {
    if (_peek == '-') {
      _take();
      return -unaer();
    }
    if (_peek == '+') {
      _take();
      return unaer();
    }
    return atom();
  }

  double atom() {
    final tok = _peek;
    if (tok == null) throw const FormulaError('Ausdruck bricht ab');
    if (tok == '(') {
      _take('(');
      final x = expr();
      _take(')');
      return x;
    }
    if (RegExp(r'^\d').hasMatch(tok)) {
      _take();
      return double.parse(tok);
    }
    final name = _take();
    if (_peek == '(') {
      _take('(');
      final args = <double>[expr()];
      while (_peek == ',') {
        _take(',');
        args.add(expr());
      }
      _take(')');
      final n = _fnArity[name];
      if (n == null) throw FormulaError('unbekannte Funktion „$name“');
      if (args.length != n) throw FormulaError('$name erwartet $n Argument(e)');
      switch (name) {
        case 'sqrt':
          return math.sqrt(args[0]);
        case 'sin':
          return math.sin(args[0] * math.pi / 180);
        case 'cos':
          return math.cos(args[0] * math.pi / 180);
        case 'tan':
          return math.tan(args[0] * math.pi / 180);
        case 'abs':
          return args[0].abs();
        case 'round':
          return args[0].roundToDouble();
        case 'min':
          return math.min(args[0], args[1]);
        default:
          return math.max(args[0], args[1]);
      }
    }
    final c = _consts[name];
    if (c != null) return c;
    final v = vals[name];
    if (v != null) return v;
    throw FormulaError('unbekannte Variable „$name“');
  }
}

double evalFormula(String expr, Map<String, double> vals) {
  final p = _Parser(tokenize(expr), vals);
  final x = p.expr();
  if (p._peek != null) throw FormulaError('überzähliges Zeichen „${p._peek}“');
  return x;
}

/// Ausdruck mit eingesetzten Zahlen – der Rechenweg unter dem Ergebnis.
String traceFormula(String expr, Map<String, double> vals,
    String Function(double) fmt) {
  final buf = StringBuffer();
  for (final t in tokenize(expr)) {
    switch (t) {
      case '*':
        buf.write(' · ');
      case '/':
        buf.write(' ÷ ');
      case '+':
        buf.write(' + ');
      case '-':
        buf.write(' − ');
      case ',':
        buf.write('; ');
      case 'sqrt':
        buf.write('√');
      case 'pi':
        buf.write('π');
      default:
        if (RegExp(r'^[A-Za-z_]').hasMatch(t) &&
            !_fnArity.containsKey(t) &&
            !_consts.containsKey(t)) {
          buf.write(fmt(vals[t] ?? 0));
        } else {
          buf.write(t);
        }
    }
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'\(\s+'), '(')
      .replaceAll(RegExp(r'\s+\)'), ')');
}

/// Zwischenergebnis eines Schema-Durchlaufs: Zeilenwerte als (a, b) für a + b·x
/// und die Gleichungen, die aus vorgegebenen Beträgen entstehen.
class _Lauf {
  final Map<String, List<double>> val;
  final List<List<double>> gl;
  const _Lauf(this.val, this.gl);
}

/// Ergebnis eines Kalkulationsschemas.
class SchemaResult {
  final Map<String, double> werte;
  final String? unbekannt;
  final String? hinweis;
  const SchemaResult(this.werte, this.unbekannt, this.hinweis);
}

/// Löst ein Kalkulationsschema vorwärts und rückwärts.
///
/// Jeder Zeilenwert ist affin in der einen Unbekannten x: `(a, b)` meint
/// `a + b·x`. Unbekannt ist die einzige leer gelassene Pflicht-Eingabezeile;
/// ein weiter unten eingetragener Betrag liefert die Gleichung, aus der x
/// bestimmt wird.
SchemaResult solveSchema(
  List<Map<String, dynamic>> rows,
  Map<String, double> eingaben,
  Map<String, double> saetze,
) {
  final byK = {for (final r in rows) r['k'] as String: r};
  final pflicht = rows
      .where((r) =>
          r['t'] == 'in' && r['opt'] != true && !eingaben.containsKey(r['k']))
      .map((r) => r['k'] as String)
      .toList();
  final ziele =
      rows.where((r) => r['t'] != 'in' && eingaben.containsKey(r['k'])).toList();

  String? hinweis;
  String? unbekannt;
  if (ziele.isNotEmpty && pflicht.length == 1) {
    unbekannt = pflicht.first;
  } else if (ziele.isNotEmpty) {
    hinweis = 'Für die Rückwärtsrechnung genau eine Kostenzeile frei lassen – '
        'zurzeit ${pflicht.isEmpty ? 'ist keine frei' : 'sind es ${pflicht.length}'}.';
  }

  double satz(String k) =>
      saetze[k] ?? ((byK[k]!['rd'] as num?)?.toDouble() ?? 0);

  _Lauf lauf(double? x) {
    final val = <String, List<double>>{};
    final gl = <List<double>>[];

    List<double> hole(String ref) {
      final neg = ref.startsWith('-');
      final v = val[neg ? ref.substring(1) : ref]!;
      return neg ? [-v[0], -v[1]] : v;
    }

    for (final r in rows) {
      final k = r['k'] as String;
      final t = r['t'] as String;
      if (t == 'in') {
        final e = eingaben[k];
        if (e != null) {
          val[k] = [e, 0];
        } else if (k == unbekannt) {
          val[k] = x == null ? [0, 1] : [x, 0];
        } else {
          val[k] = [0, 0];
        }
      } else if (t == 'pct') {
        final p = satz(k);
        final b = val[r['base'] as String]!;
        val[k] = [b[0] * p / 100, b[1] * p / 100];
      } else if (t == 'ih') {
        val[k] ??= [0, 0];
      } else if (t == 'sum') {
        var a = 0.0, b = 0.0;
        for (final ref in (r['of'] as List).cast<String>()) {
          final v = hole(ref);
          a += v[0];
          b += v[1];
        }
        final ihs = ((r['ih'] as List?) ?? const []).cast<String>();
        if (ihs.isNotEmpty) {
          final ps = ihs.map(satz).toList();
          final rest = 1 - ps.fold<double>(0, (s, p) => s + p) / 100;
          if (rest <= 0) {
            throw const FormulaError(
                'Die Sätze „im Hundert“ ergeben zusammen 100 % oder mehr.');
          }
          a /= rest;
          b /= rest;
          for (var j = 0; j < ihs.length; j++) {
            val[ihs[j]] = [a * ps[j] / 100, b * ps[j] / 100];
          }
        }
        val[k] = [a, b];
      }
      if (t == 'pct' || t == 'sum') {
        final e = eingaben[k];
        if (e != null) gl.add([val[k]![0], val[k]![1], e]);
      }
    }
    return _Lauf(val, gl);
  }

  var res = lauf(null);
  if (unbekannt != null) {
    final lb = res.gl.where((g) => g[1].abs() > 1e-12).toList();
    if (lb.isNotEmpty) {
      res = lauf((lb.first[2] - lb.first[0]) / lb.first[1]);
    } else {
      hinweis ??= 'Aus dem eingetragenen Betrag lässt sich die freie Zeile '
          'nicht bestimmen.';
    }
  }
  return SchemaResult(
      {for (final e in res.val.entries) e.key: e.value[0]}, unbekannt, hinweis);
}
