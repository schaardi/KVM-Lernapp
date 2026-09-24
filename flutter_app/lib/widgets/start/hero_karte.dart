import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/progress_service.dart';
import '../../util/format.dart';
import '../ui.dart';
import 'plan_block.dart';

/// Heute-Karte (FR-003 E.2, FR-015 2.3): Ring mit Prüfungsreife und Ampel,
/// die Aufgabe des Tages und „Jetzt lernen →“; darunter der Prüfungstermin.
class HeroKarte extends StatelessWidget {
  final VoidCallback onLernen;
  final bool kompakt;
  final bool breit;
  const HeroKarte({super.key, required this.onLernen, this.kompakt = false, this.breit = false});

  static const _ringFarbe = {
    Ampel.aus: Color(0x80FFFFFF),
    Ampel.rot: Color(0xFFFF9B85),
    Ampel.gelb: Color(0xFFFFD28F),
    Ampel.gruen: Color(0xFF8FE3AA),
  };

  @override
  Widget build(BuildContext context) {
    final prog = ProgressService.instance;
    final gesehen = prog.seenCount();
    final r = prog.overallReife();
    final amp = ampelVon(r, begonnen: gesehen > 0);
    final due = prog.dueCount();
    final fresh = prog.freshCount();
    final titel = due > 0
        ? '${fmtN(due)} Frage${due == 1 ? '' : 'n'} fällig'
        : (fresh > 0 ? 'Neue Fragen lernen' : 'Alles wiederholt');
    final text = due > 0
        ? 'Heute zur Wiederholung dran (Leitner-System) – je Runde $kRoundLen Fragen, aufgefüllt mit neuen.'
        : (fresh > 0
            ? 'Aktuell nichts fällig – starte mit neuen Fragen. Beantwortete Fragen kommen je nach Box in 1–33 Tagen zur Wiederholung.'
            : 'Alles wiederholt und nichts fällig. Komm morgen wieder – oder nutze das Schwächen-Training.');
    final kann = due + fresh > 0;
    final ring = breit ? 110.0 : (kompakt ? 64.0 : 78.0);
    final p = kPalette;

    final ringWidget = SizedBox(
      width: ring,
      height: ring,
      child: CustomPaint(
        painter: _RingMaler(r, _ringFarbe[amp]!),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(fmtProzent(r), style: dispStyle(ring * 0.26, color: Colors.white, height: 1)),
            if (!kompakt) ...[
              const SizedBox(height: 3),
              Text('PRÜFUNGSREIF', style: monoStyle(ring * 0.075, color: Colors.white.withValues(alpha: 0.8), spacing: 0.6)),
            ],
          ]),
        ),
      ),
    );

    final kicker = Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: amp == Ampel.aus ? Colors.white.withValues(alpha: 0.5) : ampelFarbe(amp),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.35), spreadRadius: 2)],
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          gesehen > 0 ? 'PRÜFUNGSREIFE · ${kAmpelText[amp]!.toUpperCase()}' : 'WILLKOMMEN – LEG LOS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: monoStyle(kompakt ? 9 : 10, color: Colors.white.withValues(alpha: 0.78), spacing: 1.1),
        ),
      ),
    ]);

    final knopf = FilledButton(
      onPressed: kann ? onLernen : null,
      style: FilledButton.styleFrom(
        backgroundColor: p.ctaBg,
        foregroundColor: p.ctaInk,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        minimumSize: Size(0, breit ? 46 : 38),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Jetzt lernen'),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 18),
      ]),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.heroFrom, p.heroTo]),
        boxShadow: const [BoxShadow(color: Color(0xBF084F58), blurRadius: 44, offset: Offset(0, 22), spreadRadius: -22)],
      ),
      child: Stack(children: [
        // zwei weiche Lichtkreise
        Positioned(
          right: -60,
          top: -70,
          child: _licht(200, Colors.white.withValues(alpha: 0.16)),
        ),
        Positioned(
          left: -50,
          bottom: -80,
          child: _licht(190, const Color(0xFFD9820A).withValues(alpha: 0.30)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(kompakt ? 12 : 14, kompakt ? 10 : 13, kompakt ? 12 : 14, kompakt ? 10 : 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              ringWidget,
              SizedBox(width: breit ? 18 : 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  kicker,
                  const SizedBox(height: 4),
                  Text(titel.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: dispStyle(breit ? 30 : (kompakt ? 19 : 21), color: Colors.white, height: 1.05)),
                  if (breit) ...[
                    const SizedBox(height: 6),
                    Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: Colors.white.withValues(alpha: 0.84))),
                  ],
                  SizedBox(height: kompakt ? 6 : 9),
                  knopf,
                ]),
              ),
            ]),
            const PlanBlock(),
          ]),
        ),
      ]),
    );
  }

  Widget _licht(double d, Color c) => IgnorePointer(
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
          ),
        ),
      );
}

class _RingMaler extends CustomPainter {
  final double wert;
  final Color farbe;
  _RingMaler(this.wert, this.farbe);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width * 0.085;
    final rect = Offset(s / 2, s / 2) & Size(size.width - s, size.height - s);
    final spur = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s;
    canvas.drawArc(rect, 0, math.pi * 2, false, spur);
    final w = wert.isNaN ? 0.0 : wert.clamp(0.0, 1.0);
    if (w <= 0) return;
    final fg = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * w, false, fg);
  }

  @override
  bool shouldRepaint(_RingMaler old) => old.wert != wert || old.farbe != farbe;
}
