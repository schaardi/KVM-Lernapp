import 'package:flutter/material.dart';
import '../../pruefung/bereiche.dart';
import '../../pruefung/ergebnisse.dart';
import '../../services/pruef_stat.dart';
import '../ui.dart';

/// Streifen „Bestehenschance“ in der Prüfungskarte der Startseite (FR-014 5,
/// FR-015 2.4, Web `renderPruefChance`): je Teil der Wert bzw. „4/5“ mit den
/// fehlenden Bereichen, darunter „x von y Prüfungen bestanden“ und – wenn ein
/// Bereich unter 70 % liegt – der knappste. Erscheint, sobald es eine
/// gewertete Prüfung gibt; antippen öffnet die Prüfungen.
class ChanceStreifen extends StatelessWidget {
  final bool kompakt;
  final VoidCallback onTap;
  const ChanceStreifen({super.key, required this.onTap, this.kompakt = false});

  static const _hell = Color(0xFFE9F2F3);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pruefStand,
      builder: (context, _, __) {
        final st = PruefErgebnisse.instance.statistik();
        if (st.n == 0) return const SizedBox.shrink();
        final handy = MediaQuery.sizeOf(context).width <= 560;

        Widget wert(TeilStand? t, String name) {
          if (t == null) return const SizedBox.shrink();
          final offen = t.p == null;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(offen ? '${t.n - t.fehlt.length}/${t.n}' : peProzent(t.p),
                style: dispStyle(handy ? 21 : 26,
                    color: offen ? Colors.white.withValues(alpha: 0.62) : Colors.white, height: 1)),
            SizedBox(height: handy ? 2 : 3),
            Text(
              offen && !handy
                  ? '$name: Bereiche geprüft · fehlt: ${t.fehlt.map((k) => pruefBereich(k)?.kurz ?? k).join(', ')}'
                  : name,
              maxLines: handy ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.35, color: Colors.white.withValues(alpha: 0.72)),
            ),
          ]);
        }

        // Der knappste Bereich (nur mitgezählte Teile).
        BereichStand? knapp;
        for (final b in kPruefBereiche) {
          final s = st.bereiche[b.k]!;
          if (s.chance == null || (b.teil == 'hq' && st.hq == null)) continue;
          if (knapp == null || s.chance! < knapp.chance!) knapp = s;
        }
        final summe = '${st.ok} von ${st.n} ${st.n == 1 ? 'Prüfung' : 'Prüfungen'} bestanden'
            '${knapp != null && knapp.chance! < 0.7 ? ' · am knappsten: ${knapp.bereich.kurz} ${peProzent(knapp.chance)}' : ''} →';

        final werte = [wert(st.bq, 'Basisqualifikationen'), if (st.hq != null) wert(st.hq, 'Handlungsspezifisch')];
        final oben = kompakt ? 7.0 : (handy ? 9.0 : 12.0);
        final unten = kompakt ? 8.0 : (handy ? 11.0 : 14.0);

        return Semantics(
          button: true,
          label: 'Bestehenschance – Übersicht deiner Prüfungen öffnen',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12)))),
              padding: EdgeInsets.fromLTRB(handy ? 13 : 16, oben, handy ? 13 : 16, unten),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BESTEHENSCHANCE', style: monoStyle(9.5, color: _hell.withValues(alpha: 0.6), spacing: 1)),
                SizedBox(height: handy ? 5 : 7),
                if (handy)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var i = 0; i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: i < werte.length ? werte[i] : const SizedBox.shrink()),
                    ],
                  ])
                else
                  Wrap(spacing: 22, runSpacing: 8, children: werte),
                SizedBox(height: handy ? 5 : 7),
                Text(summe,
                    maxLines: handy ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, height: 1.35, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ),
          ),
        );
      },
    );
  }
}
