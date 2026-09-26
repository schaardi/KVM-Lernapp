import 'package:flutter/material.dart';

/// Die Seiten der Startansicht übereinander (FR-015): Alle bleiben erhalten
/// (Zustand, Scrollposition), sichtbar ist eine. Beim Wechsel huscht die alte
/// Seite ein Stück hinaus und blendet aus, erst danach gleitet die neue in
/// Laufrichtung herein – wie im Web (weiter rechts in der Leiste = von rechts).
/// Nacheinander, nicht übereinander: Gleichzeitig überblendet lagen beide
/// Seiten sichtbar übereinander (Geisterbild). Ohne Animationen (Einstellung
/// „Animationen entfernen“) wird sofort gewechselt.
class SeitenStapel extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const SeitenStapel({super.key, required this.index, required this.children});

  @override
  State<SeitenStapel> createState() => _SeitenStapelState();
}

class _SeitenStapelState extends State<SeitenStapel> with SingleTickerProviderStateMixin {
  /// So weit (dp) kommt die neue Seite von der Seite herein bzw. huscht die
  /// alte hinaus.
  static const double _weg = 36;

  /// Ablauf in Teilen des Ganzen (320 ms): die alte Seite bis 0,12 s, die
  /// neue erst ab dann – nie sind beide zugleich zu sehen.
  static const double _rausBis = 120 / 320;
  static const double _reinAb = 120 / 320;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);

  /// Die Seite, die gerade hinausgleitet.
  int? _alt;
  bool _vor = true;

  @override
  void didUpdateWidget(SeitenStapel alt) {
    super.didUpdateWidget(alt);
    if (alt.index == widget.index) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _alt = null;
      _c.value = 1;
      return;
    }
    _alt = alt.index;
    _vor = widget.index > alt.index;
    _c.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _alt = null);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      for (var i = 0; i < widget.children.length; i++) _seite(i),
    ]);
  }

  /// Für jede Seite derselbe Aufbau – so bleibt ihr Zustand beim Wechsel
  /// erhalten; nur Deckkraft und Versatz ändern sich.
  Widget _seite(int i) {
    final aktiv = i == widget.index;
    final raus = i == _alt && !aktiv;
    final sichtbar = aktiv || raus;
    return Offstage(
      offstage: !sichtbar,
      child: TickerMode(
        enabled: sichtbar,
        child: IgnorePointer(
          ignoring: !aktiv,
          child: AnimatedBuilder(
            animation: _c,
            child: RepaintBoundary(child: widget.children[i]),
            builder: (context, kind) {
              final t = _c.value;
              final r = _vor ? 1.0 : -1.0;
              var deckung = 1.0, x = 0.0;
              if (aktiv && _alt != null) {
                final b = ((t - _reinAb) / (1 - _reinAb)).clamp(0.0, 1.0);
                deckung = Curves.easeOut.transform(b);
                x = r * _weg * (1 - Curves.easeOutCubic.transform(b));
              } else if (raus) {
                final a = Curves.easeIn.transform((t / _rausBis).clamp(0.0, 1.0));
                deckung = 1 - a;
                x = -r * _weg * a;
              }
              return Opacity(
                key: ValueKey('seite-$i'),
                opacity: deckung,
                child: Transform.translate(offset: Offset(x, 0), child: kind),
              );
            },
          ),
        ),
      ),
    );
  }
}
