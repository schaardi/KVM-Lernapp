import 'package:flutter/material.dart';
import '../constants.dart';

/// Rechenblatt: Karopapier zum Rechnen von Hand (CustomPaint + Gesten).
class DrawingPad extends StatefulWidget {
  const DrawingPad({super.key});
  @override
  State<DrawingPad> createState() => _DrawingPadState();
}

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke(this.points, this.color, this.width);
}

class _DrawingPadState extends State<DrawingPad> {
  final List<_Stroke> _strokes = [];
  Color _color = kInk;
  double _width = 2.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            for (final c in [kInk, kPetrol, kErr, kAmber])
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _color == c ? kInk : Colors.transparent, width: 2),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            for (final w in [1.5, 2.5, 4.5])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(w == 1.5 ? 'dünn' : (w == 2.5 ? 'mittel' : 'dick')),
                  selected: _width == w,
                  onSelected: (_) => setState(() => _width = w),
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _strokes.clear()),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Leeren'),
            ),
          ]),
        ),
        Expanded(
          child: GestureDetector(
            onPanStart: (d) => setState(
                () => _strokes.add(_Stroke([d.localPosition], _color, _width))),
            onPanUpdate: (d) =>
                setState(() => _strokes.last.points.add(d.localPosition)),
            child: CustomPaint(
              painter: _PadPainter(_strokes),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PadPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _PadPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    // Karogitter
    final grid = Paint()
      ..color = const Color(0xFFDDE8EA)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final s in strokes) {
      final p = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < s.points.length - 1; i++) {
        canvas.drawLine(s.points[i], s.points[i + 1], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
}
