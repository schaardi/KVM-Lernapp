import 'package:flutter/material.dart';
import '../../constants.dart';

/// Eine Funktionskachel der Startseite (FR-015 2.5).
class Funktion {
  final IconData icon;
  final Color farbe;
  final String titel;
  final String text;
  final VoidCallback onTap;
  const Funktion(this.icon, this.farbe, this.titel, this.text, this.onTap);
}

/// 3 × 2 Kacheln. Bis 1199 dp Symbol über dem Titel (ohne Text auf dem
/// Handy), ab 1200 dp Symbol links mit Kurzbeschreibung.
class FunktionsKacheln extends StatelessWidget {
  final List<Funktion> funktionen;
  final bool kompakt;
  const FunktionsKacheln({super.key, required this.funktionen, this.kompakt = false});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final quer = w >= 1200;
    final mitText = quer || (w > 560 && w < 900);
    final schmal = w < 380;
    final abstand = w < 340 ? 5.0 : (kompakt ? 6.0 : 8.0);
    final zeilen = <Widget>[];
    for (var i = 0; i < funktionen.length; i += 3) {
      if (i > 0) zeilen.add(SizedBox(height: abstand));
      zeilen.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = i; j < i + 3; j++) ...[
            if (j > i) SizedBox(width: abstand),
            Expanded(
              child: j < funktionen.length
                  ? _kachel(funktionen[j], quer: quer, mitText: mitText, schmal: schmal, klein: w < 340)
                  : const SizedBox.shrink(),
            ),
          ],
        ]),
      ));
    }
    return Column(children: zeilen);
  }

  Widget _kachel(Funktion f, {required bool quer, required bool mitText, required bool schmal, required bool klein}) {
    final symbol = Container(
      width: quer ? 36 : (kompakt ? 26 : 32),
      height: quer ? 36 : (kompakt ? 26 : 32),
      decoration: BoxDecoration(color: f.farbe, borderRadius: BorderRadius.circular(10)),
      child: Icon(f.icon, color: Colors.white, size: quer ? 20 : (kompakt ? 15 : 18)),
    );
    final titel = Text(f.titel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: klein ? 10.5 : (schmal ? 11.5 : (quer ? 13.5 : 12.5)),
            fontWeight: FontWeight.w700,
            color: kInk,
            height: 1.2));
    final text = Text(f.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, height: 1.3, color: kMuted));
    final innen = quer
        ? Row(children: [
            symbol,
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                titel,
                const SizedBox(height: 1),
                text,
              ]),
            ),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            symbol,
            SizedBox(height: kompakt ? 3 : 5),
            titel,
            if (mitText) ...[const SizedBox(height: 2), text],
          ]);
    return Material(
      color: kPaper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: f.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: quer ? 62 : (kompakt ? 52 : 58)),
          padding: EdgeInsets.fromLTRB(klein ? 5 : (schmal ? 7 : 9), kompakt ? 7 : 8, klein ? 5 : (schmal ? 7 : 9), kompakt ? 6 : 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine),
            boxShadow: kSoftShadow,
          ),
          child: innen,
        ),
      ),
    );
  }
}
