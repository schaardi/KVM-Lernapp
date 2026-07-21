import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

/// Prüfungsreife-Radar mit dynamischen Achsen – je aktivem Fach eine Zacke
/// (4 oder 5, je nach gewählter Fachrichtung). Gezeichnet mit CustomPainter.
class RadarChart extends StatelessWidget {
  final List<int> facher; // aktive Fach-Nummern, z. B. [1,2,3,4] oder [1,2,3,4,5]
  final List<double> values; // Werte 0..1, gleiche Reihenfolge wie facher
  const RadarChart({super.key, required this.facher, required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 220,
      child: CustomPaint(painter: _RadarPainter(facher, values)),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<int> facher;
  final List<double> values;
  _RadarPainter(this.facher, this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 4;
    final r = min(cx, cy) - 22;
    final n = facher.length;
    if (n < 1) return;

    Offset pt(int i, double rad) {
      final a = -pi / 2 + i * 2 * pi / n;
      return Offset(cx + cos(a) * rad, cy + sin(a) * rad);
    }

    final grid = Paint()
      ..color = kLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final g in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pt(i, r * g);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(Offset(cx, cy), pt(i, r), grid);
      final lp = pt(i, r + 14);
      final tp = TextPainter(
        text: TextSpan(
          text: '${facher[i]}',
          style: TextStyle(
            color: kFachColor[facher[i]],
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lp.dx - tp.width / 2, lp.dy - tp.height / 2));
    }

    // Datenpolygon
    final fill = Paint()
      ..color = kPetrol.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = kPetrol
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dp = Path();
    for (var i = 0; i < n; i++) {
      final double v = (i < values.length ? values[i] : 0.0).clamp(0.015, 1.0).toDouble();
      final p = pt(i, r * v);
      i == 0 ? dp.moveTo(p.dx, p.dy) : dp.lineTo(p.dx, p.dy);
    }
    dp.close();
    canvas.drawPath(dp, fill);
    canvas.drawPath(dp, stroke);
    for (var i = 0; i < n; i++) {
      final double v = (i < values.length ? values[i] : 0.0).clamp(0.015, 1.0).toDouble();
      canvas.drawCircle(pt(i, r * v), 3.2, Paint()..color = kFachColor[facher[i]]!);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.facher != facher;
}
