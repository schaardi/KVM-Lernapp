import 'package:flutter/material.dart';

/// Die Seiten der Startansicht übereinander (FR-015): Alle bleiben erhalten
/// (Zustand, Scrollposition), sichtbar ist eine. Beim Wechsel gleitet die neue
/// Seite in Laufrichtung herein und die alte blendet hinaus – wie im Web
/// (weiter rechts in der Leiste = von rechts). Ohne Animationen (Einstellung
/// „Animationen entfernen“) wird sofort gewechselt.
class SeitenStapel extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const SeitenStapel({super.key, required this.index, required this.children});

  @override
  State<SeitenStapel> createState() => _SeitenStapelState();
}

class _SeitenStapelState extends State<SeitenStapel> with SingleTickerProviderStateMixin {
  /// So weit (dp) kommt die neue Seite von der Seite herein.
  static const double _weg = 44;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 340), value: 1);

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
                deckung = Curves.easeOut.transform((t / 0.75).clamp(0.0, 1.0));
                x = r * _weg * (1 - Curves.easeOutCubic.transform(t));
              } else if (raus) {
                final a = Curves.easeIn.transform((t / 0.55).clamp(0.0, 1.0));
                deckung = 1 - a;
                x = -r * _weg * 0.7 * a;
              }
              return Opacity(opacity: deckung, child: Transform.translate(offset: Offset(x, 0), child: kind));
            },
          ),
        ),
      ),
    );
  }
}
