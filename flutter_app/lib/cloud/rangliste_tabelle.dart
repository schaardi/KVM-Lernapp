import 'package:flutter/material.dart';
import '../constants.dart';
import '../util/format.dart';
import '../widgets/ui.dart';
import 'modelle.dart';
import 'werte.dart';

/// Eine Zeile der Tabelle: Platz, Spitzname und zwei Werte rechts.
class TabellenZeile {
  final int platz;
  final String name;
  final String a;
  final String r;
  final bool ich;
  final String? erklaerung; // Tooltip der Spalte a
  const TabellenZeile({
    required this.platz,
    required this.name,
    required this.a,
    required this.r,
    this.ich = false,
    this.erklaerung,
  });

  /// Wochenrangliste: Antworten und Reife.
  factory TabellenZeile.woche(WochenEintrag e) =>
      TabellenZeile(platz: e.platz, name: e.name, a: fmtN(e.antworten), r: '${e.reife} %', ich: e.ich);

  /// Prüfungsrangliste: bestanden/gewertet und Chance.
  factory TabellenZeile.pruef(PruefEintrag e) => TabellenZeile(
        platz: e.platz,
        name: e.name,
        a: '${e.ok}/${e.n}',
        r: chanceText(e.chance),
        ich: e.ich,
        erklaerung: '${e.ok} von ${e.n} gewerteten Prüfungen bestanden'
            '${e.schnitt != null ? ', Ø ${e.schnitt} Punkte' : ''}',
      );
}

/// Medaillen für die Plätze 1–3 wie im Web (fest, in beiden Darstellungen).
const Map<int, List<Color>> _medaillen = {
  1: [Color(0xFFFBD88A), Color(0xFFE3A032), Color(0xFFB96C06)],
  2: [Color(0xFFF1F4F5), Color(0xFFB8C3C7), Color(0xFF8A979C)],
  3: [Color(0xFFF3C9A0), Color(0xFFC98A52), Color(0xFF9A5E2C)],
};

/// Rangliste als Tabelle (Web `.vg-liste`): Kopfzeile, Plätze 1–3 als
/// Medaille, eigene Zeile markiert („· du“), außerhalb der Liste nach „⋯“.
class RanglisteTabelle extends StatelessWidget {
  final bool pruefung;
  final List<TabellenZeile> zeilen;
  final TabellenZeile? eigeneNachLuecke;

  /// Namen anderer öffnen das Profil (nur mit Profilen).
  final void Function(String name)? onName;

  const RanglisteTabelle({
    super.key,
    required this.zeilen,
    this.pruefung = false,
    this.eigeneNachLuecke,
    this.onName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Schmale Handys: engere Wertespalten, damit die Namen Platz haben.
      final m = _Mass(pruefung, kompakt: c.maxWidth < 320);
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _kopf(m),
          for (final z in zeilen) _zeile(z, m),
          if (eigeneNachLuecke != null) ...[
            // „⋯“ als Symbol – das Zeichen fehlt in den gebündelten Schriften.
            Container(
              height: 22,
              decoration: BoxDecoration(border: Border(top: BorderSide(color: kLineSoft))),
              alignment: Alignment.center,
              child: ExcludeSemantics(child: Icon(Icons.more_horiz, size: 18, color: kMuted)),
            ),
            _zeile(eigeneNachLuecke!, m),
          ],
        ]),
      );
    });
  }

  Widget _kopf(_Mass m) {
    final stil = monoStyle(10, spacing: 0.8);
    Widget label(String t, {bool rechts = false}) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: rechts ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(t, maxLines: 1, softWrap: false, style: stil),
        );
    return ExcludeSemantics(
      child: Container(
        color: kSurface2,
        padding: EdgeInsets.symmetric(horizontal: m.rand, vertical: 7),
        child: Row(children: [
          SizedBox(width: m.platz, child: label('PL.')),
          SizedBox(width: m.luecke),
          Expanded(child: label('SPITZNAME')),
          SizedBox(width: m.luecke),
          SizedBox(width: m.a, child: label(pruefung ? 'BESTANDEN' : 'ANTW.', rechts: true)),
          SizedBox(width: m.luecke),
          SizedBox(width: m.r, child: label(pruefung ? 'CHANCE' : 'REIFE', rechts: true)),
        ]),
      ),
    );
  }

  Widget _zeile(TabellenZeile z, _Mass m) {
    final medaille = _medaillen[z.platz];
    final name = Text.rich(
      TextSpan(children: [
        TextSpan(text: z.name),
        if (z.ich) TextSpan(text: ' · du', style: TextStyle(fontWeight: FontWeight.w500, color: kPetrolInk)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk),
    );
    final klick = onName != null && !z.ich && z.name.isNotEmpty;
    Widget a = Text(z.a,
        textAlign: TextAlign.right,
        maxLines: 1,
        style: monoStyle(13, color: kInk, weight: FontWeight.w600, spacing: 0));
    if (z.erklaerung != null) a = Tooltip(message: z.erklaerung!, child: a);
    return Container(
      decoration: BoxDecoration(
        color: z.ich ? kPetrolSoft : null,
        border: Border(top: BorderSide(color: kLineSoft)),
      ),
      padding: EdgeInsets.symmetric(horizontal: m.rand, vertical: 8),
      child: Row(children: [
        SizedBox(
          width: m.platz,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: medaille == null
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.4), colors: medaille, stops: const [0, 0.6, 1]),
                    ),
              child: Text('${z.platz}',
                  style: monoStyle(12,
                      color: medaille == null ? kMuted : Colors.white, weight: FontWeight.w600, spacing: 0)),
            ),
          ),
        ),
        SizedBox(width: m.luecke),
        Expanded(
          child: klick
              ? Semantics(
                  button: true,
                  hint: 'Profil ansehen',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => onName!(z.name),
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: name),
                  ),
                )
              : name,
        ),
        SizedBox(width: m.luecke),
        SizedBox(width: m.a, child: a),
        SizedBox(width: m.luecke),
        SizedBox(
          width: m.r,
          child: Text(z.r,
              textAlign: TextAlign.right,
              maxLines: 1,
              style: monoStyle(11.5, color: kMuted, weight: FontWeight.w600, spacing: 0)),
        ),
      ]),
    );
  }
}

/// Spaltenbreiten wie im Web (30 · Name · 64/78 · 48/58), auf schmalen
/// Handys enger.
class _Mass {
  final double rand, platz, luecke, a, r;
  _Mass(bool pruefung, {required bool kompakt})
      : rand = kompakt ? 10 : 12,
        platz = kompakt ? 26 : 30,
        luecke = kompakt ? 6 : 8,
        a = pruefung ? (kompakt ? 58 : 78) : (kompakt ? 50 : 64),
        r = pruefung ? (kompakt ? 46 : 58) : (kompakt ? 42 : 48);
}
