import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/answer_store.dart';
import '../services/data_service.dart';
import '../widgets/ui.dart';
import 'pruef_ui.dart';
import 'skizze_daten.dart';

/// Skizze je Teilaufgabe (FR-013, Web „Skizze: Zeichenfläche für
/// Zeichenaufgaben“): Stift, Linie, Pfeil, Rechteck, Raute, Oval, Text und
/// Radierer auf Karopapier oder direkt auf der Anlage. Linien, Pfeile und
/// Formen rasten auf ein halbes Karo ein. Gespeichert wird in
/// `kvm_open_sketch` (über den [AnswerStore]); die Skizze zählt als Antwort.

const _werkzeuge = [
  ('stift', 'Stift'),
  ('linie', 'Linie'),
  ('pfeil', 'Pfeil'),
  ('rechteck', 'Rechteck'),
  ('raute', 'Raute'),
  ('oval', 'Oval'),
  ('text', 'Text'),
  ('radierer', 'Radierer'),
];

/// Zustand einer Skizze – geteilt zwischen dem Feld im Aufgabenblatt und der
/// Vollbild-Ansicht („Groß zeichnen“).
class SkizzeZustand extends ChangeNotifier {
  final String id;
  final Anlagenbild? anlage;
  final VoidCallback onAenderung;
  String bg;
  String fmt;
  List<Map<String, dynamic>> els;
  final _verlauf = <String>[];
  String werkzeug = 'stift';
  String farbe = 'k';
  Map<String, dynamic>? akt; // Element im Entstehen
  Offset? _start; // Startpunkt einer Form
  String? _radiert; // Stand vor dem Radieren

  SkizzeZustand({required this.id, required String frage, required this.anlage, required this.onAenderung})
      : bg = 'karo',
        fmt = 'quer',
        els = [] {
    final d = AnswerStore.instance.skizze(id);
    bg = skStartHintergrund(frage, d, hatAnlage: anlage != null);
    fmt = skStartFormat(frage, d);
    els = [for (final e in (d?['els'] as List? ?? const [])) Map<String, dynamic>.from(e as Map)];
  }

  double get hoehe => skHoehe(bg: bg, fmt: fmt, anlageVerhaeltnis: anlage?.verhaeltnis);
  bool get kannZurueck => _verlauf.isNotEmpty;

  void _speichern() {
    AnswerStore.instance.setSkizze(id, bg: bg, fmt: fmt, els: els);
    onAenderung();
  }

  void _merken() {
    _verlauf.add(json.encode(els));
    if (_verlauf.length > 60) _verlauf.removeAt(0);
  }

  void setzeWerkzeug(String w) {
    werkzeug = w;
    notifyListeners();
  }

  void setzeFarbe(String f) {
    farbe = f;
    notifyListeners();
  }

  void setzeFormat(String f) {
    fmt = f;
    if (els.isNotEmpty) _speichern();
    notifyListeners();
  }

  void setzeHintergrund(String b) {
    bg = b;
    if (els.isNotEmpty) _speichern();
    notifyListeners();
  }

  void zurueck() {
    if (_verlauf.isEmpty) return;
    els = [for (final e in json.decode(_verlauf.removeLast()) as List) Map<String, dynamic>.from(e as Map)];
    _speichern();
    notifyListeners();
  }

  void leeren() {
    _merken();
    els = [];
    _speichern();
    notifyListeners();
  }

  // ───────────── Zeichnen (Punkte in Einheiten: 1000 breit) ─────────────

  void start(Offset p) {
    final x = skRasten(p.dx), y = skRasten(p.dy);
    switch (werkzeug) {
      case 'radierer':
        _radiert = json.encode(els);
        _radieren(p);
        return;
      case 'stift':
        akt = {'t': 'p', 'c': farbe, 's': 3, 'pts': [p.dx.round(), p.dy.round()]};
      case 'linie':
      case 'pfeil':
        akt = {'t': werkzeug == 'linie' ? 'l' : 'a', 'c': farbe, 's': 3, 'x1': x, 'y1': y, 'x2': x, 'y2': y};
      default:
        _start = Offset(x, y);
        akt = {
          't': {'rechteck': 'r', 'raute': 'd', 'oval': 'o'}[werkzeug] ?? 'r',
          'c': farbe,
          's': 3,
          'x': x,
          'y': y,
          'w': 0.0,
          'h': 0.0,
        };
    }
    notifyListeners();
  }

  void bewegen(Offset p) {
    if (_radiert != null) {
      _radieren(p);
      return;
    }
    final a = akt;
    if (a == null) return;
    if (a['t'] == 'p') {
      final pts = a['pts'] as List;
      final lx = (pts[pts.length - 2] as num).toDouble(), ly = (pts[pts.length - 1] as num).toDouble();
      if (math.sqrt((p.dx - lx) * (p.dx - lx) + (p.dy - ly) * (p.dy - ly)) >= 3) {
        pts
          ..add(p.dx.round())
          ..add(p.dy.round());
      }
    } else if (a['t'] == 'l' || a['t'] == 'a') {
      a['x2'] = skRasten(p.dx);
      a['y2'] = skRasten(p.dy);
    } else {
      final x = skRasten(p.dx), y = skRasten(p.dy), s = _start!;
      a['x'] = math.min(s.dx, x);
      a['y'] = math.min(s.dy, y);
      a['w'] = (x - s.dx).abs();
      a['h'] = (y - s.dy).abs();
    }
    notifyListeners();
  }

  void ende() {
    if (_radiert != null) {
      if (json.encode(els) != _radiert) {
        _verlauf.add(_radiert!);
        if (_verlauf.length > 60) _verlauf.removeAt(0);
        _speichern();
      }
      _radiert = null;
      notifyListeners();
      return;
    }
    final e = akt;
    akt = null;
    if (e == null) return;
    final t = e['t'];
    final ok = t == 'p' ||
        ((t == 'l' || t == 'a')
            ? _laenge(e['x1'], e['y1'], e['x2'], e['y2']) >= 10
            : ((e['w'] as num) >= 12 && (e['h'] as num) >= 12));
    if (ok) {
      _merken();
      els.add(e);
      _speichern();
    }
    notifyListeners();
  }

  static double _laenge(dynamic x1, dynamic y1, dynamic x2, dynamic y2) {
    final dx = (x2 as num) - (x1 as num), dy = (y2 as num) - (y1 as num);
    return math.sqrt(dx * dx + dy * dy);
  }

  void _radieren(Offset p) {
    final i = skTreffer(els, p.dx, p.dy);
    if (i >= 0) {
      els.removeAt(i);
      notifyListeners();
    }
  }

  /// Text: in eine Form tippen beschriftet sie, auf einen Text tippen ändert
  /// ihn, sonst entsteht freier Text an der Stelle.
  Future<void> text(BuildContext context, Offset p) async {
    final i = skTreffer(els, p.dx, p.dy);
    final e = i >= 0 ? els[i] : null;
    if (e != null && (e['t'] == 'r' || e['t'] == 'd' || e['t'] == 'o')) {
      final t = await _texteingabe(context, 'Beschriftung der Form:', (e['txt'] ?? '').toString());
      if (t == null) return;
      _merken();
      final s = _kuerzen(t);
      if (s.isNotEmpty) {
        e['txt'] = s;
      } else {
        e.remove('txt');
      }
    } else if (e != null && e['t'] == 'x') {
      final t = await _texteingabe(context, 'Text ändern (leer = löschen):', (e['txt'] ?? '').toString());
      if (t == null) return;
      _merken();
      final s = _kuerzen(t);
      if (s.isNotEmpty) {
        e['txt'] = s;
      } else {
        els.removeAt(i);
      }
    } else {
      final t = await _texteingabe(context, 'Text:', '');
      if (t == null || t.trim().isEmpty) return;
      _merken();
      els.add({'t': 'x', 'c': farbe, 'x': p.dx.round(), 'y': p.dy.round(), 'txt': _kuerzen(t)});
    }
    _speichern();
    notifyListeners();
  }

  static String _kuerzen(String t) {
    final s = t.trim();
    return s.length > 120 ? s.substring(0, 120) : s;
  }
}

Future<String?> _texteingabe(BuildContext context, String titel, String vorgabe) {
  final c = TextEditingController(text: vorgabe);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titel, style: const TextStyle(fontSize: 17)),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLength: 120,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
      ],
    ),
  ).whenComplete(() => WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose()));
}

// ───────────────────────────── Malen ─────────────────────────────

/// Malt Raster und Elemente in Einheiten (1000 breit).
class SkizzeMaler extends CustomPainter {
  final List<Map<String, dynamic>> els;
  final Map<String, dynamic>? akt;
  final double hoehe;
  final bool raster;
  SkizzeMaler({required this.els, this.akt, required this.hoehe, required this.raster, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / skBreite;
    canvas.save();
    canvas.scale(s);
    if (raster) {
      final p = Paint()
        ..color = const Color(0xFFDBE7EA)
        ..strokeWidth = 1;
      for (var x = skRaster; x < skBreite; x += skRaster) {
        canvas.drawLine(Offset(x, 0), Offset(x, hoehe), p);
      }
      for (var y = skRaster; y < hoehe; y += skRaster) {
        canvas.drawLine(Offset(0, y), Offset(skBreite, y), p);
      }
    }
    for (final e in els) {
      _element(canvas, e);
    }
    if (akt != null) _element(canvas, akt!);
    canvas.restore();
  }

  static double _n(dynamic v) => v is num ? v.toDouble() : 0;

  static void _element(Canvas canvas, Map<String, dynamic> e) {
    final farbe = Color(skFarben[e['c']] ?? skFarben['k']!);
    final strich = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = _n(e['s']) > 0 ? _n(e['s']) : 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (e['t']) {
      case 'p':
        final pts = (e['pts'] as List? ?? const []).map(_n).toList();
        if (pts.length < 2) return;
        final pfad = Path()..moveTo(pts[0], pts[1]);
        if (pts.length == 2) pfad.lineTo(pts[0] + 0.1, pts[1]);
        for (var i = 2; i + 1 < pts.length; i += 2) {
          pfad.lineTo(pts[i], pts[i + 1]);
        }
        canvas.drawPath(pfad, strich);
      case 'l':
      case 'a':
        final x1 = _n(e['x1']), y1 = _n(e['y1']), x2 = _n(e['x2']), y2 = _n(e['y2']);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), strich);
        if (e['t'] == 'a') {
          final wk = math.atan2(y2 - y1, x2 - x1);
          const l = 18.0;
          final spitze = Path()
            ..moveTo(x2, y2)
            ..lineTo(x2 - l * math.cos(wk - 0.45), y2 - l * math.sin(wk - 0.45))
            ..lineTo(x2 - l * math.cos(wk + 0.45), y2 - l * math.sin(wk + 0.45))
            ..close();
          canvas.drawPath(spitze, Paint()..color = farbe);
        }
      case 'x':
        final tp = TextPainter(
          text: TextSpan(
              text: (e['txt'] ?? '').toString(),
              style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w600, color: farbe)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(_n(e['x']), _n(e['y']) - tp.height / 2));
        tp.dispose();
      default:
        final x = _n(e['x']), y = _n(e['y']), w = _n(e['w']), h = _n(e['h']);
        final Path pfad;
        if (e['t'] == 'd') {
          pfad = Path()
            ..moveTo(x + w / 2, y)
            ..lineTo(x + w, y + h / 2)
            ..lineTo(x + w / 2, y + h)
            ..lineTo(x, y + h / 2)
            ..close();
        } else if (e['t'] == 'o') {
          pfad = Path()
            ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(math.min(w, h) / 2)));
        } else {
          pfad = Path()..addRect(Rect.fromLTWH(x, y, w, h));
        }
        canvas.drawPath(pfad, Paint()..color = farbe.withValues(alpha: 0.1));
        canvas.drawPath(pfad, strich);
        final txt = (e['txt'] ?? '').toString();
        if (txt.isNotEmpty) {
          final breite = math.max(30.0, e['t'] == 'd' ? w * 0.62 : w - 14);
          final tp = TextPainter(
            text: TextSpan(
                text: txt,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    height: 21 / 18,
                    fontWeight: FontWeight.w600,
                    color: Color(skFarben['k']!))),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: breite);
          tp.paint(canvas, Offset(x + w / 2 - tp.width / 2, y + h / 2 - tp.height / 2));
          tp.dispose();
        }
    }
  }

  @override
  bool shouldRepaint(covariant SkizzeMaler old) => true;
}

/// Zieht sofort beim Aufsetzen – die Seite scrollt beim Zeichnen nicht mit.
class _SofortZiehen extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// Die Zeichenfläche: weißes Papier (auch im Dunkeln), Karo oder Anlage.
class _Flaeche extends StatelessWidget {
  final SkizzeZustand z;
  const _Flaeche(this.z);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: z,
      builder: (context, _) {
        final h = z.hoehe;
        final anlage = z.bg == 'anlage' ? z.anlage : null;
        return AspectRatio(
          aspectRatio: skBreite / h,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kLineStrong),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: LayoutBuilder(builder: (context, c) {
                Offset einheit(Offset p) => Offset(p.dx / c.maxWidth * skBreite, p.dy / c.maxHeight * h);
                final malen = Stack(fit: StackFit.expand, children: [
                  if (anlage != null) _AnlageHintergrund(anlage),
                  CustomPaint(painter: SkizzeMaler(els: z.els, akt: z.akt, hoehe: h, raster: anlage == null)),
                ]);
                return Semantics(
                  label: 'Zeichenfläche',
                  child: z.werkzeug == 'text'
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) => z.text(context, einheit(d.localPosition)),
                          child: malen,
                        )
                      : RawGestureDetector(
                          behavior: HitTestBehavior.opaque,
                          gestures: {
                            _SofortZiehen: GestureRecognizerFactoryWithHandlers<_SofortZiehen>(
                              () => _SofortZiehen(),
                              (r) {
                                r
                                  ..dragStartBehavior = DragStartBehavior.down
                                  ..onStart = (d) {
                                    z.start(einheit(d.localPosition));
                                  }
                                  ..onUpdate = (d) {
                                    z.bewegen(einheit(d.localPosition));
                                  }
                                  ..onEnd = (_) {
                                    z.ende();
                                  }
                                  ..onCancel = z.ende;
                              },
                            ),
                          },
                          child: malen,
                        ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _AnlageHintergrund extends StatelessWidget {
  final Anlagenbild a;
  const _AnlageHintergrund(this.a);

  @override
  Widget build(BuildContext context) {
    if (a.datei.isNotEmpty) return Image.asset(a.asset, fit: BoxFit.fill);
    final komma = a.uri.indexOf(',');
    if (!a.uri.startsWith('data:') || komma < 0) return const SizedBox.shrink();
    try {
      return Image.memory(base64Decode(a.uri.substring(komma + 1)), fit: BoxFit.fill);
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

/// Die Skizze im Aufgabenblatt: Kopf, Werkzeuge, Fläche, „Groß zeichnen“.
class SkizzeFeld extends StatefulWidget {
  final Question frage;

  /// Bild-Anlage der Teilaufgabe oder ihrer Aufgabe („Auf der Anlage“).
  final String? anlageRef;
  final VoidCallback onAenderung;
  const SkizzeFeld({super.key, required this.frage, required this.anlageRef, required this.onAenderung});

  @override
  State<SkizzeFeld> createState() => _SkizzeFeldState();
}

class _SkizzeFeldState extends State<SkizzeFeld> {
  late final SkizzeZustand _z;

  @override
  void initState() {
    super.initState();
    _z = SkizzeZustand(
      id: widget.frage.id,
      frage: widget.frage.q,
      anlage: DataService.instance.anlage(widget.anlageRef),
      onAenderung: widget.onAenderung,
    );
  }

  @override
  void dispose() {
    _z.dispose();
    super.dispose();
  }

  Future<void> _gross() => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SkizzeVollbild(_z),
      ));

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final handy = w <= 560;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: handy ? 6 : 10, vertical: handy ? 8 : 10),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kPetrolLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
            Text('SKIZZE', style: monoStyle(10, color: kPetrolInk, weight: FontWeight.w700, spacing: 1)),
            Text('wie auf dem Lösungsblatt · wird gespeichert', style: TextStyle(fontSize: 11, color: kMuted, height: 1.3)),
          ]),
        ),
        _Werkzeuge(_z, handy: handy, vollbild: false, onGross: _gross),
        const SizedBox(height: 8),
        _Flaeche(_z),
        if (w <= 820) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _gross,
              icon: const Icon(Icons.open_in_full, size: 17),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPetrolInkDeep,
                backgroundColor: kPetrolSoft,
                side: BorderSide(color: kPetrol),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
              ),
              label: const Text('Groß zeichnen'),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
          child: Text(
            'Formen und Linien rasten am Karo ein. Mit „Text“ in eine Form tippen, um sie zu beschriften – oder daneben für freien Text.',
            style: TextStyle(fontSize: 11, height: 1.4, color: kMuted),
          ),
        ),
      ]),
    );
  }
}

/// Vollbild: die Skizze füllt den Bildschirm („Groß zeichnen“ / „Fertig“).
class _SkizzeVollbild extends StatelessWidget {
  final SkizzeZustand z;
  const _SkizzeVollbild(this.z);

  @override
  Widget build(BuildContext context) {
    final handy = MediaQuery.sizeOf(context).width <= 560;
    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            _Werkzeuge(z, handy: handy, vollbild: true, onGross: () => Navigator.of(context).pop()),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: z,
                builder: (context, _) => LayoutBuilder(builder: (context, c) {
                  final breite = math.max(120.0, math.min(c.maxWidth, c.maxHeight * skBreite / z.hoehe));
                  return Center(child: SizedBox(width: breite, child: _Flaeche(z)));
                }),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Werkzeuge extends StatelessWidget {
  final SkizzeZustand z;
  final bool handy;
  final bool vollbild;
  final VoidCallback onGross;
  const _Werkzeuge(this.z, {required this.handy, required this.vollbild, required this.onGross});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: z,
      builder: (context, _) {
        Widget knopf(String label, Widget symbol, VoidCallback? onTap, {bool an = false}) {
          final farbe = an ? Colors.white : kInk;
          return Tooltip(
            message: label,
            child: Semantics(
              button: true,
              selected: an,
              label: label,
              excludeSemantics: true,
              child: Material(
                color: an ? kPetrol : kPaper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: BorderSide(color: an ? kPetrol : kLineStrong),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: onTap,
                  child: Container(
                    constraints: BoxConstraints(minWidth: handy ? 34 : 38, minHeight: handy ? 34 : 36),
                    padding: EdgeInsets.symmetric(horizontal: handy ? 6 : 9, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconTheme(data: IconThemeData(color: farbe, size: 17), child: symbol),
                      if (!handy) ...[
                        const SizedBox(width: 5),
                        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: farbe)),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          );
        }

        Widget farbKnopf(String k) {
          final an = z.farbe == k;
          final d = handy ? 28.0 : 30.0;
          return Semantics(
            button: true,
            selected: an,
            label: 'Farbe ${skFarbNamen[k]}',
            child: GestureDetector(
              onTap: () => z.setzeFarbe(k),
              child: Container(
                width: d,
                height: d,
                margin: EdgeInsets.symmetric(horizontal: handy ? 1 : 2),
                decoration: BoxDecoration(
                  color: Color(skFarben[k]!),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPaper, width: 2),
                  boxShadow: [BoxShadow(color: an ? kPetrol : kLineStrong, spreadRadius: an ? 2 : 1)],
                ),
              ),
            ),
          );
        }

        Widget segment(List<(String, String)> wahl, String wert, ValueChanged<String> setzen) => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: kSurface,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final (k, label) in wahl)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Semantics(
                      selected: wert == k,
                      button: true,
                      child: Material(
                        color: wert == k ? kPaper : Colors.transparent,
                        elevation: wert == k ? 1 : 0,
                        borderRadius: BorderRadius.circular(7),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () => setzen(k),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            alignment: Alignment.center,
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w600, color: wert == k ? kInk : kMuted)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            );

        final lueckeGruppe = handy ? 3.0 : 4.0;
        return Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Wrap(spacing: lueckeGruppe, runSpacing: 4, children: [
            for (final (k, label) in _werkzeuge)
              knopf(label, _SkSymbol(k), () => z.setzeWerkzeug(k), an: z.werkzeug == k),
          ]),
          Wrap(spacing: lueckeGruppe, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final k in skFarben.keys) farbKnopf(k),
            knopf('Zurück', const Icon(Icons.undo), z.kannZurueck ? z.zurueck : null),
            knopf('Leeren', const Icon(Icons.delete_outline), () async {
              if (z.els.isEmpty) return;
              final ok = await nachfragen(context,
                  titel: 'Skizze leeren?', text: 'Rückgängig geht danach noch.', ja: 'Leeren', gefaehrlich: true);
              if (ok) z.leeren();
            }),
            knopf(vollbild ? 'Fertig' : 'Groß', Icon(vollbild ? Icons.close_fullscreen : Icons.open_in_full), onGross,
                an: vollbild),
          ]),
          if (z.bg != 'anlage') segment(const [('quer', 'Quer'), ('hoch', 'Hoch')], z.fmt, z.setzeFormat),
          if (z.anlage != null) segment(const [('karo', 'Karo'), ('anlage', 'Auf der Anlage')], z.bg, z.setzeHintergrund),
        ]);
      },
    );
  }
}

/// Die Symbole der Zeichenwerkzeuge – dieselben Formen wie im Web (24er Raster).
class _SkSymbol extends StatelessWidget {
  final String name;
  const _SkSymbol(this.name);

  @override
  Widget build(BuildContext context) {
    final t = IconTheme.of(context);
    final g = t.size ?? 17;
    return SizedBox(width: g, height: g, child: CustomPaint(painter: _SkSymbolMaler(name, t.color ?? kInk)));
  }
}

class _SkSymbolMaler extends CustomPainter {
  final String name;
  final Color farbe;
  _SkSymbolMaler(this.name, this.farbe);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pfad = Path();
    switch (name) {
      case 'stift':
        pfad
          ..moveTo(12, 20)
          ..lineTo(21, 20)
          ..moveTo(16.5, 3.5)
          ..quadraticBezierTo(18.5, 1.8, 20.2, 3.8)
          ..quadraticBezierTo(21.2, 5.4, 19.5, 6.5)
          ..lineTo(7, 19)
          ..lineTo(3, 20)
          ..lineTo(4, 16)
          ..close();
      case 'linie':
        pfad
          ..moveTo(5, 19)
          ..lineTo(19, 5);
      case 'pfeil':
        pfad
          ..moveTo(5, 19)
          ..lineTo(19, 5)
          ..moveTo(10, 5)
          ..lineTo(19, 5)
          ..lineTo(19, 14);
      case 'rechteck':
        pfad.addRRect(RRect.fromLTRBR(4, 6, 20, 18, const Radius.circular(1)));
      case 'raute':
        pfad
          ..moveTo(12, 3)
          ..lineTo(21, 12)
          ..lineTo(12, 21)
          ..lineTo(3, 12)
          ..close();
      case 'oval':
        pfad.addRRect(RRect.fromLTRBR(3, 7, 21, 17, const Radius.circular(5)));
      case 'text':
        pfad
          ..moveTo(5, 7)
          ..lineTo(5, 5)
          ..lineTo(19, 5)
          ..lineTo(19, 7)
          ..moveTo(12, 5)
          ..lineTo(12, 19)
          ..moveTo(9, 19)
          ..lineTo(15, 19);
      case 'radierer':
        pfad
          ..moveTo(7, 21)
          ..lineTo(3, 17)
          ..lineTo(3, 14.2)
          ..lineTo(13.2, 4)
          ..lineTo(16, 4)
          ..lineTo(20, 8)
          ..lineTo(20, 10.8)
          ..lineTo(11, 20)
          ..moveTo(7, 21)
          ..lineTo(20, 21);
    }
    canvas.drawPath(pfad, p);
  }

  @override
  bool shouldRepaint(covariant _SkSymbolMaler old) => old.name != name || old.farbe != farbe;
}

/// Nach dem Aufdecken: die eigene Skizze als Bild; antippen vergrößert sie.
class SkizzeBild extends StatelessWidget {
  final String id;
  final String? anlageRef;
  const SkizzeBild({super.key, required this.id, required this.anlageRef});

  @override
  Widget build(BuildContext context) {
    final d = AnswerStore.instance.skizze(id);
    if (d == null) return const SizedBox.shrink();
    final anlage = DataService.instance.anlage(anlageRef);
    final bg = (d['bg'] == 'anlage' && anlage != null) ? 'anlage' : 'karo';
    final h = skHoehe(bg: bg, fmt: (d['fmt'] ?? 'quer').toString(), anlageVerhaeltnis: anlage?.verhaeltnis);
    final els = [for (final e in d['els'] as List) Map<String, dynamic>.from(e as Map)];
    Widget bild() => AspectRatio(
          aspectRatio: skBreite / h,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kLine),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(fit: StackFit.expand, children: [
                if (bg == 'anlage') _AnlageHintergrund(anlage!),
                CustomPaint(painter: SkizzeMaler(els: els, hoehe: h, raster: bg != 'anlage')),
              ]),
            ),
          ),
        );
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Semantics(
          image: true,
          button: true,
          label: 'Deine Skizze – antippen zum Vergrößern',
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black87,
              pageBuilder: (ctx, _, __) => Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Stack(children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        child: Center(child: Padding(padding: const EdgeInsets.all(12), child: bild())),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Text('Deine Skizze',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white)),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Schließen',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ]),
                ),
              ),
            )),
            child: bild(),
          ),
        ),
      ),
    );
  }
}
