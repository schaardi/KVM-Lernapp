import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants.dart';

// Das Rechenblatt ist Papier und bleibt auch im Dunkelmodus weiß (FR-002 I);
// Stift- und Rasterfarben wie im Web (`.pad-swatch`, `drawGrid`).
const Color _papier = Color(0xFFFFFFFF);
const Color _raster = Color(0xFFDBE7EA);
const List<Color> _stifte = [Color(0xFF17272E), Color(0xFF0C6C78), Color(0xFFC0472F), Color(0xFFD9820A)];
const List<String> _stiftNamen = ['Schwarz', 'Petrol', 'Rot', 'Orange'];

class _Strich {
  final List<Offset> punkte;
  final Color farbe;
  final double breite;
  final bool radierer;
  _Strich(this.punkte, this.farbe, this.breite, this.radierer);
}

/// Rechenblatt: Karopapier zum Rechnen von Hand (Web `#mPad`). Der Inhalt
/// bleibt erhalten, solange die App geöffnet ist – auch wenn das Blatt
/// zwischendurch geschlossen wird.
class DrawingPad extends StatefulWidget {
  const DrawingPad({super.key});

  /// Striche des Blatts – leben so lange wie die App.
  static final List<_Strich> _blatt = [];

  /// Anzahl der Striche (für Tests).
  @visibleForTesting
  static int get anzahlStriche => _blatt.length;

  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _DrawingPadState extends State<DrawingPad> {
  static Color _farbe = _stifte.first;
  static double _breite = 3;
  static bool _radierer = false;
  int? _zeiger;

  List<_Strich> get _striche => DrawingPad._blatt;

  void _start(PointerDownEvent e) {
    if (_zeiger != null) return; // zweiter Finger zeichnet nicht
    _zeiger = e.pointer;
    setState(() => _striche.add(_Strich([e.localPosition], _farbe, _radierer ? _breite * 4 : _breite, _radierer)));
  }

  void _weiter(PointerMoveEvent e) {
    if (e.pointer != _zeiger || _striche.isEmpty) return;
    setState(() => _striche.last.punkte.add(e.localPosition));
  }

  void _ende(PointerEvent e) {
    if (e.pointer == _zeiger) _zeiger = null;
  }

  Widget _werkzeug(String text, bool an, VoidCallback onTap) {
    final r = BorderRadius.circular(8);
    return Semantics(
      button: true,
      selected: an,
      child: Material(
        color: an ? kPetrolSoft : kPaper,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: an ? kPetrol : kLineStrong)),
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Center(
                widthFactor: 1,
                child: Text(text,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: an ? kPetrolInkDeep : kInkSoft)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(children: [
            for (var i = 0; i < _stifte.length; i++)
              Semantics(
                button: true,
                selected: !_radierer && _farbe == _stifte[i],
                label: 'Stift ${_stiftNamen[i]}',
                child: GestureDetector(
                  onTap: () => setState(() {
                    _farbe = _stifte[i];
                    _radierer = false;
                  }),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _stifte[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: !_radierer && _farbe == _stifte[i] ? kPetrol : kLine, width: 2.5),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            _werkzeug('Stift', !_radierer, () => setState(() => _radierer = false)),
            const SizedBox(width: 6),
            _werkzeug('Radierer', _radierer, () => setState(() => _radierer = true)),
            const SizedBox(width: 10),
            for (final (w, name) in [(1.5, 'dünn'), (3.0, 'mittel'), (6.0, 'dick')]) ...[
              _werkzeug(name, _breite == w, () => setState(() => _breite = w)),
              const SizedBox(width: 6),
            ],
            const SizedBox(width: 4),
            _werkzeug('Leeren', false, () => setState(_striche.clear)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: kLine),
                  borderRadius: BorderRadius.circular(10),
                ),
                // Die Fläche nimmt jeden Finger sofort an: Das Blatt darüber
                // verrutscht beim Zeichnen nicht.
                child: RawGestureDetector(
                  gestures: {
                    EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                      EagerGestureRecognizer.new,
                      (_) {},
                    ),
                  },
                  child: Listener(
                    onPointerDown: _start,
                    onPointerMove: _weiter,
                    onPointerUp: _ende,
                    onPointerCancel: _ende,
                    child: CustomPaint(
                      painter: _BlattMaler(_striche, _striche.length, _striche.isEmpty ? 0 : _striche.last.punkte.length),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Text(
            'Karopapier zum Rechnen von Hand – mit Maus oder Finger malen. '
            'Der Inhalt bleibt erhalten, solange die App geöffnet ist.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: kMuted),
          ),
        ),
      ],
    );
  }
}

class _BlattMaler extends CustomPainter {
  final List<_Strich> striche;
  final int anzahl;
  final int punkte;
  _BlattMaler(this.striche, this.anzahl, this.punkte);

  @override
  void paint(Canvas canvas, Size size) {
    final rahmen = Offset.zero & size;
    canvas.drawRect(rahmen, Paint()..color = _papier);
    final gitter = Paint()
      ..color = _raster
      ..strokeWidth = 1;
    const schritt = 24.0;
    for (var x = schritt; x < size.width; x += schritt) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gitter);
    }
    for (var y = schritt; y < size.height; y += schritt) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gitter);
    }
    // Eigene Ebene: Der Radierer löscht Striche, nicht das Karo.
    canvas.saveLayer(rahmen, Paint());
    for (final s in striche) {
      final p = Paint()
        ..color = s.farbe
        ..strokeWidth = s.breite
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = s.radierer ? BlendMode.clear : BlendMode.srcOver;
      if (s.punkte.length == 1) {
        canvas.drawCircle(
            s.punkte.first, s.breite / 2, p..style = PaintingStyle.fill);
        continue;
      }
      final pfad = Path()..moveTo(s.punkte.first.dx, s.punkte.first.dy);
      for (final q in s.punkte.skip(1)) {
        pfad.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(pfad, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlattMaler alt) =>
      alt.anzahl != anzahl || alt.punkte != punkte || !identical(alt.striche, striche);
}
