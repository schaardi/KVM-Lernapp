import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

/// Prüfungsreife-Radar (5 Achsen = 5 Fächer), gezeichnet mit CustomPainter.
class RadarChart extends StatelessWidget {
  final List<double> values; // 5 Werte 0..1, Index 0..4 = Fach 1..5
  const RadarChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 220,
      child: CustomPaint(painter: _RadarPainter(values)),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  _RadarPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 4;
    final r = min(cx, cy) - 22;
    const n = 5;

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
          text: '${i + 1}',
          style: TextStyle(
            color: kFachColor[i + 1],
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
      ..color = kPetrol.withOpacity(0.18)
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
      canvas.drawCircle(pt(i, r * v), 3.2, Paint()..color = kFachColor[i + 1]!);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.values != values;
}
