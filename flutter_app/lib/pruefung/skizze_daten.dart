import 'dart:math' as math;

/// Skizze je Teilaufgabe (FR-013) – Datenmodell und Regeln ohne Oberfläche,
/// wie im Web (`kvm_open_sketch`): Striche und Formen als kleine Vektorliste
/// in einem festen Raum von [skBreite] Einheiten Breite – so passt sie auf
/// jede Bildschirmbreite.
///
/// `{ <Teilaufgaben-ID>: { v: 1, bg: 'karo'|'anlage', fmt: 'quer'|'hoch', els: [...] } }`
///
/// | `t` | Element | Felder |
/// |---|---|---|
/// | `p` | Freihand | `pts: [x0, y0, x1, y1, …]` (ganze Zahlen) |
/// | `l` / `a` | Linie / Pfeil | `x1, y1, x2, y2` |
/// | `r` / `d` / `o` | Rechteck / Raute / Oval | `x, y, w, h`, optional `txt` |
/// | `x` | Text | `x, y` (linke Mitte), `txt` |
///
/// Dazu je Element `c` ∈ `k|p|r|b` (Farbe) und `s` (Strichstärke, 3).

const double skBreite = 1000;
const double skQuer = 625;
const double skHoch = 1250;
const double skRaster = 25;

/// Farben der Skizze – bewusst fest, die Skizze ist Papier (auch im Dunkeln).
const Map<String, int> skFarben = {'k': 0xFF17272E, 'p': 0xFF0C6C78, 'r': 0xFFC0472F, 'b': 0xFF3F6FB5};
const Map<String, String> skFarbNamen = {'k': 'Schwarz', 'p': 'Petrol', 'r': 'Rot', 'b': 'Blau'};

/// Zeichenaufgabe = eine Aufforderung zum Zeichnen, nicht „Nennen Sie
/// Diagrammarten“ (Web `SK_RE` / `SK_OBJ`).
const _skObjekt =
    '(Flussdiagramm|Programmablaufplan|Struktogramm|Diagramm|Schaubild|Histogramm|Organigramm|Netzplan|Balkenplan|Gantt|Erzeugnisstruktur|Wahrscheinlichkeitsnetz|Wahrscheinlichkeitsgerade|Portfolio|Matrix|Kurve|Gerade|Normalverteilung)';
final List<RegExp> _skRegeln = [
  RegExp(r'\b(zeichnen|skizzieren) Sie\b', caseSensitive: false),
  RegExp(r'\b(zeichnerisch|grafisch|graphisch)\b', caseSensitive: false),
  RegExp(r'\b(stellen|tragen) Sie\b[^.?!]{0,200}?\b(in|im|als|auf)\b[^.?!]{0,80}?' + _skObjekt, caseSensitive: false),
  RegExp(r'\b(erstellen|entwerfen|ergänzen|vervollständigen|vergleichen) Sie\b[^.?!]{0,120}?' + _skObjekt,
      caseSensitive: false),
  RegExp(r'\bkennzeichnen Sie\b[^.?!]{0,80}?\b(im|in)\b[^.?!]{0,40}?' + _skObjekt, caseSensitive: false),
];

/// Verlangt der Fragetext eine Zeichnung?
bool skZeichenteil(String frage) {
  final t = frage.replaceAll(RegExp(r'\s+'), ' ');
  return _skRegeln.any((r) => r.hasMatch(t));
}

/// Format: Flussdiagramme laufen von oben nach unten – dafür hochkant.
String skStartFormat(String frage, Map<String, dynamic>? gespeichert) {
  final f = gespeichert?['fmt'];
  if (f == 'quer' || f == 'hoch') return f as String;
  return RegExp(r'Flussdiagramm|Programmablaufplan|Struktogramm', caseSensitive: false).hasMatch(frage)
      ? 'hoch'
      : 'quer';
}

/// Hintergrund: die Anlage der Aufgabe, wenn es sie als Bild gibt –
/// voreingestellt nur, wenn die Aufgabe ausdrücklich in die Anlage zeichnen
/// lässt.
String skStartHintergrund(String frage, Map<String, dynamic>? gespeichert, {required bool hatAnlage}) {
  final bg = gespeichert?['bg'];
  if (bg == 'karo' || bg == 'anlage') return (bg == 'anlage' && !hatAnlage) ? 'karo' : bg as String;
  return (hatAnlage && frage.contains('Anlage')) ? 'anlage' : 'karo';
}

/// Höhe der Fläche in Einheiten: auf der Anlage deren Seitenverhältnis.
double skHoehe({required String bg, required String fmt, double? anlageVerhaeltnis}) {
  if (bg == 'anlage' && anlageVerhaeltnis != null && anlageVerhaeltnis > 0) {
    return (skBreite / anlageVerhaeltnis).roundToDouble();
  }
  return fmt == 'hoch' ? skHoch : skQuer;
}

/// Auf ein halbes Karo einrasten.
double skRasten(double v) {
  const s = skRaster / 2;
  return (v / s).roundToDouble() * s;
}

double _abstand(double px, double py, double x1, double y1, double x2, double y2) {
  final dx = x2 - x1, dy = y2 - y1, l = dx * dx + dy * dy;
  final t = l == 0 ? 0.0 : math.max(0.0, math.min(1.0, ((px - x1) * dx + (py - y1) * dy) / l));
  final x = x1 + t * dx, y = y1 + t * dy;
  return math.sqrt((px - x) * (px - x) + (py - y) * (py - y));
}

double _n(dynamic v) => v is num ? v.toDouble() : 0;

/// Oberstes Element unter dem Punkt (für Radierer und Beschriften), sonst -1.
int skTreffer(List<Map<String, dynamic>> els, double x, double y) {
  for (var i = els.length - 1; i >= 0; i--) {
    final e = els[i];
    final t = e['t'];
    if (t == 'p') {
      final p = (e['pts'] as List? ?? const []).map(_n).toList();
      if (p.length == 2 && math.sqrt((x - p[0]) * (x - p[0]) + (y - p[1]) * (y - p[1])) < 12) return i;
      for (var j = 2; j + 1 < p.length; j += 2) {
        if (_abstand(x, y, p[j - 2], p[j - 1], p[j], p[j + 1]) < 12) return i;
      }
    } else if (t == 'l' || t == 'a') {
      if (_abstand(x, y, _n(e['x1']), _n(e['y1']), _n(e['x2']), _n(e['y2'])) < 12) return i;
    } else if (t == 'x') {
      final ex = _n(e['x']), ey = _n(e['y']);
      final len = (e['txt'] ?? '').toString().length;
      if (x >= ex - 6 && x <= ex + math.max(24, len * 12) + 6 && (y - ey).abs() < 18) return i;
    } else {
      final ex = _n(e['x']), ey = _n(e['y']), w = _n(e['w']), h = _n(e['h']);
      if (x >= ex - 6 && x <= ex + w + 6 && y >= ey - 6 && y <= ey + h + 6) return i;
    }
  }
  return -1;
}

/// Für den Prüfauftrag an eine KI: Bestand und Beschriftungen der Skizze.
String skText(Map<String, dynamic>? d) {
  final els = (d?['els'] as List?)?.whereType<Map>().toList() ?? const [];
  if (els.isEmpty) return '';
  const namen = {
    'p': ['Freihandstrich', 'Freihandstriche'],
    'l': ['Linie', 'Linien'],
    'a': ['Pfeil', 'Pfeile'],
    'r': ['Rechteck', 'Rechtecke'],
    'd': ['Raute', 'Rauten'],
    'o': ['Oval', 'Ovale'],
    'x': ['Text', 'Texte'],
  };
  final n = <String, int>{};
  final txt = <String>[];
  for (final e in els) {
    final t = (e['t'] ?? '').toString();
    n[t] = (n[t] ?? 0) + 1;
    final s = (e['txt'] ?? '').toString();
    if (s.isNotEmpty) txt.add('„$s“');
  }
  final teile = ['r', 'd', 'o', 'a', 'l', 'x', 'p']
      .where((t) => (n[t] ?? 0) > 0)
      .map((t) => '${n[t]} ${namen[t]![n[t] == 1 ? 0 : 1]}')
      .toList();
  return '[Eigene Skizze: ${teile.join(', ')}${txt.isNotEmpty ? ' · Beschriftungen: ${txt.join(', ')}' : ''}]';
}
