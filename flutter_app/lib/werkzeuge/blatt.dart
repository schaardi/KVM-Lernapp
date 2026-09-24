import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/ui.dart';

/// ✕ mit Rahmen wie im Web (`.sheet-head .x`, `.fw-head .x`).
class SchliessenKnopf extends StatelessWidget {
  final VoidCallback onTap;
  final double groesse;
  final String semantik;
  const SchliessenKnopf({super.key, required this.onTap, this.groesse = 40, this.semantik = 'Schließen'});

  @override
  Widget build(BuildContext context) {
    return RahmenKnopf(
      onTap: onTap,
      groesse: groesse,
      semantik: semantik,
      child: Icon(Icons.close, size: groesse * 0.42, color: kMuted),
    );
  }
}

/// Kleiner Knopf mit Rahmen (Schließen, Einklappen).
class RahmenKnopf extends StatelessWidget {
  final VoidCallback onTap;
  final double groesse;
  final String semantik;
  final Widget child;
  const RahmenKnopf({super.key, required this.onTap, required this.child, required this.semantik, this.groesse = 34});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(groesse >= 40 ? 10 : 8);
    return Semantics(
      button: true,
      label: semantik,
      excludeSemantics: true,
      child: Tooltip(
        message: semantik,
        child: Material(
          color: kPaper,
          shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: kLineStrong)),
          child: InkWell(
            borderRadius: r,
            canRequestFocus: false,
            onTap: onTap,
            child: SizedBox(width: groesse, height: groesse, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

/// Kopf eines Werkzeug-Blatts wie im Web (`.sheet-head`): Titel in Barlow
/// Condensed, Großbuchstaben, rechts ✕.
class BlattKopf extends StatelessWidget {
  final String titel;
  final VoidCallback? onSchliessen;
  const BlattKopf(this.titel, {super.key, this.onSchliessen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(titel.toUpperCase(),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: dispStyle(19)),
          ),
        ),
        const SizedBox(width: 10),
        SchliessenKnopf(onTap: onSchliessen ?? () => Navigator.maybePop(context)),
      ]),
    );
  }
}

/// Öffnet ein Werkzeug als Blatt von unten: Formelbuch, Rechenblatt …
/// [hoehe] = Anteil der Bildschirmhöhe; ohne [ziehbar] lässt sich das Blatt
/// nicht nach unten wischen (Zeichenfläche).
Future<T?> zeigeWerkzeugBlatt<T>(
  BuildContext context, {
  required String titel,
  required Widget inhalt,
  double hoehe = 0.85,
  bool ziehbar = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: ziehbar,
    backgroundColor: kPaper,
    constraints: const BoxConstraints(maxWidth: 760),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final tastatur = mq.viewInsets.bottom;
      final h = math.max(200.0, math.min(mq.size.height * hoehe, mq.size.height - tastatur - 24));
      return Padding(
        padding: EdgeInsets.only(bottom: tastatur),
        child: SizedBox(
          height: h,
          child: Column(children: [
            BlattKopf(titel),
            Expanded(child: inhalt),
          ]),
        ),
      );
    },
  );
}
