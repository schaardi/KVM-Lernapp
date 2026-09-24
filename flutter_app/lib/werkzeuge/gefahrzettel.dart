import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import 'adr_daten.dart';

/// Gefahrzettel als gezeichnete Raute (Web: SVG in `label()`, viewBox 100):
/// Grundfläche, Symbol, schwarzer Rand und Klassenzahl unten. Die ADR-Farben
/// bleiben auch im Dunkelmodus.
class Gefahrzettel extends StatelessWidget {
  final AdrKlasse klasse;
  final double groesse;
  const Gefahrzettel(this.klasse, {super.key, this.groesse = 82});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Gefahrzettel Klasse ${klasse.klasse}',
      child: SizedBox.square(
        dimension: groesse,
        child: CustomPaint(painter: GefahrzettelMaler(klasse)),
      ),
    );
  }
}

class GefahrzettelMaler extends CustomPainter {
  final AdrKlasse k;
  GefahrzettelMaler(this.k);

  static final Path _raute = Path()
    ..moveTo(50, 2)
    ..lineTo(98, 50)
    ..lineTo(50, 98)
    ..lineTo(2, 50)
    ..close();

  static Paint _fuell(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  static Paint _strich(Color c, double breite) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = breite
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    _flaeche(canvas);
    canvas.save();
    canvas.clipPath(_raute);
    _symbol(canvas, k.symbol, k.symbolFarbe);
    canvas.restore();
    canvas.drawPath(_raute, _strich(kAdrSchwarz, 3)..strokeJoin = StrokeJoin.miter);

    final tp = TextPainter(
      text: TextSpan(
        text: k.nummer,
        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: k.nummerFarbe),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final grundlinie = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(50 - tp.width / 2, 91 - grundlinie));
    tp.dispose();
    canvas.restore();
  }

  void _haelften(Canvas canvas, Color oben, Color unten) {
    canvas.drawPath(
        Path()
          ..moveTo(50, 2)
          ..lineTo(98, 50)
          ..lineTo(2, 50)
          ..close(),
        _fuell(oben));
    canvas.drawPath(
        Path()
          ..moveTo(2, 50)
          ..lineTo(98, 50)
          ..lineTo(50, 98)
          ..close(),
        _fuell(unten));
  }

  void _flaeche(Canvas canvas) {
    switch (k.flaeche) {
      case AdrFlaeche.voll:
        canvas.drawPath(_raute, _fuell(k.farbe));
      case AdrFlaeche.weissRot:
        _haelften(canvas, kAdrWeiss, kAdrRot);
      case AdrFlaeche.rotGelb:
        _haelften(canvas, kAdrRot, kAdrGelb);
      case AdrFlaeche.gelbWeiss:
        _haelften(canvas, kAdrGelb, kAdrWeiss);
      case AdrFlaeche.weissSchwarz:
        _haelften(canvas, kAdrWeiss, kAdrSchwarz);
      case AdrFlaeche.streifenRot:
        canvas.drawPath(_raute, _fuell(kAdrWeiss));
        canvas.save();
        canvas.clipPath(_raute);
        for (var x = 8.0; x < 98; x += 14) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 6, 100), _fuell(kAdrRot));
        }
        canvas.restore();
      case AdrFlaeche.streifen9:
        canvas.drawPath(_raute, _fuell(kAdrWeiss));
        canvas.save();
        canvas.clipPath(_raute);
        for (var x = 6.0; x < 98; x += 13) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 5, 50), _fuell(kAdrSchwarz));
        }
        canvas.restore();
    }
  }

  static Path _flamme() => Path()
    ..moveTo(50, 16)
    ..cubicTo(58, 28, 47, 32, 52, 44)
    ..cubicTo(55, 40, 56, 37, 56, 37)
    ..cubicTo(62, 45, 58, 57, 50, 58)
    ..cubicTo(41, 57, 37, 47, 43, 39)
    ..cubicTo(44, 44, 47, 44, 48, 42)
    ..cubicTo(51, 36, 48, 26, 50, 16)
    ..close();

  /// Keil des Strahlenzeichens (Web `wedge`): Ringstück zwischen r1 und r2,
  /// ±25° um [mitte].
  static Path _keil(double cx, double cy, double r1, double r2, double mitte) {
    const h = 25 * math.pi / 180;
    final a1 = mitte - h, a2 = mitte + h;
    final c = Offset(cx, cy);
    return Path()
      ..moveTo(cx + r1 * math.cos(a1), cy + r1 * math.sin(a1))
      ..lineTo(cx + r2 * math.cos(a1), cy + r2 * math.sin(a1))
      ..arcTo(Rect.fromCircle(center: c, radius: r2), a1, 2 * h, false)
      ..lineTo(cx + r1 * math.cos(a2), cy + r1 * math.sin(a2))
      ..arcTo(Rect.fromCircle(center: c, radius: r1), a2, -2 * h, false)
      ..close();
  }

  void _gedreht(Canvas canvas, double grad, Offset um, void Function() malen) {
    canvas.save();
    canvas.translate(um.dx, um.dy);
    canvas.rotate(grad * math.pi / 180);
    canvas.translate(-um.dx, -um.dy);
    malen();
    canvas.restore();
  }

  void _symbol(Canvas canvas, AdrSymbol sym, Color c) {
    final f = _fuell(c);
    switch (sym) {
      case AdrSymbol.flamme:
        canvas.drawPath(_flamme(), f);
      case AdrSymbol.flasche:
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 24, 14, 34), const Radius.circular(7)), f);
        canvas.drawRect(const Rect.fromLTWH(47, 17, 6, 9), f);
      case AdrSymbol.totenkopf:
        canvas.drawCircle(const Offset(50, 34), 12, f);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(43, 43, 14, 8), const Radius.circular(3)), f);
        final weiss = _fuell(kAdrWeiss);
        canvas.drawCircle(const Offset(45.5, 33), 3.2, weiss);
        canvas.drawCircle(const Offset(54.5, 33), 3.2, weiss);
        canvas.drawPath(
            Path()
              ..moveTo(50, 36)
              ..relativeLineTo(-2.5, 5)
              ..relativeLineTo(5, 0)
              ..close(),
            weiss);
        final knochen = _strich(c, 4);
        canvas.drawLine(const Offset(37, 53), const Offset(63, 63), knochen);
        canvas.drawLine(const Offset(63, 53), const Offset(37, 63), knochen);
        for (final p in const [Offset(37, 53), Offset(63, 53), Offset(37, 63), Offset(63, 63)]) {
          canvas.drawCircle(p, 3, f);
        }
      case AdrSymbol.explosion:
        const schritte = [
          Offset(4, 13), Offset(12, -7), Offset(-6, 13), Offset(14, 3), Offset(-14, 4), Offset(6, 13),
          Offset(-12, -7), Offset(-4, 13), Offset(-4, -13), Offset(-12, 7), Offset(6, -13), Offset(-14, -4),
          Offset(14, -3), Offset(-6, -13), Offset(12, 7),
        ];
        final p = Path()..moveTo(50, 16);
        for (final d in schritte) {
          p.relativeLineTo(d.dx, d.dy);
        }
        canvas.drawPath(p..close(), f);
      case AdrSymbol.oxidation:
        canvas.drawCircle(const Offset(50, 48), 15, _strich(c, 4));
        canvas.drawPath(
            Path()
              ..moveTo(50, 18)
              ..cubicTo(57, 28, 47, 31, 52, 40)
              ..cubicTo(54, 37, 55, 35, 55, 35)
              ..cubicTo(60, 41, 55, 48, 50, 48)
              ..cubicTo(44, 48, 41, 41, 46, 35)
              ..cubicTo(47, 38, 49, 38, 49, 37)
              ..cubicTo(51, 31, 49, 26, 50, 18)
              ..close(),
            f);
      case AdrSymbol.aetzend:
        _gedreht(canvas, 38, const Offset(31, 31), () {
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 24, 6, 15), const Radius.circular(2)), f);
        });
        _gedreht(canvas, -38, const Offset(69, 31), () {
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 24, 6, 15), const Radius.circular(2)), f);
        });
        canvas.drawRect(const Rect.fromLTWH(24, 54, 20, 4), f);
        canvas.drawPath(
            Path()
              ..moveTo(56, 54)
              ..relativeQuadraticBezierTo(7, 5, 15, 4)
              ..relativeQuadraticBezierTo(-2, 6, -9, 5)
              ..relativeQuadraticBezierTo(-7, -1, -6, -9)
              ..close(),
            f);
        final tropfen = _strich(c, 2.6);
        canvas.drawLine(const Offset(40, 42), const Offset(37, 52), tropfen);
        canvas.drawLine(const Offset(60, 42), const Offset(63, 52), tropfen);
      case AdrSymbol.radioaktiv:
        canvas.drawCircle(const Offset(50, 44), 5, f);
        for (var i = 0; i < 3; i++) {
          canvas.drawPath(_keil(50, 44, 9, 26, (-90 + i * 120) * math.pi / 180), f);
        }
      case AdrSymbol.biogefahr:
        final ring = _strich(c, 4);
        for (var i = 0; i < 3; i++) {
          final a = (-90 + i * 120) * math.pi / 180;
          canvas.drawCircle(Offset(50 + 13 * math.cos(a), 44 + 13 * math.sin(a)), 9, ring);
        }
        canvas.drawCircle(const Offset(50, 44), 5, f);
      case AdrSymbol.keins:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant GefahrzettelMaler alt) => !identical(alt.k, k);
}

// Warntafel wie am Fahrzeug (Web `.warntafel`): orange, schwarzer Rand.
const Color _tafelOrange = Color(0xFFF49B00);

/// Orange Warntafel: oben die Gefahrnummer (Kemler-Zahl), unten die UN-Nummer.
class Warntafel extends StatelessWidget {
  final String kemler;
  final String un;
  const Warntafel({super.key, required this.kemler, required this.un});

  @override
  Widget build(BuildContext context) {
    const schrift = TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 30,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.8,
      height: 1.2,
      color: kAdrSchwarz,
    );
    Widget feld(String t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Text(t, textAlign: TextAlign.center, style: schrift),
        );
    return Semantics(
      label: 'Warntafel: Gefahrnummer $kemler, UN-Nummer $un',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: _tafelOrange,
          border: Border.all(color: kAdrSchwarz, width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: kSoftShadow,
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              feld(kemler),
              const ColoredBox(color: kAdrSchwarz, child: SizedBox(height: 3)),
              feld(un),
            ],
          ),
        ),
      ),
    );
  }
}
