import 'package:flutter/material.dart';
import '../constants.dart';
import '../util/format.dart';
import '../widgets/start/stat_leiste.dart' show AktivitaetDiagramm;
import '../widgets/ui.dart';
import 'bausteine.dart';
import 'modelle.dart';
import 'werte.dart';

/// Lernstand im Detail (Web `lernstandHTML`): Reife je Fach, Aktivität der
/// letzten 14 Tage (bis heute nachgerückt), Prüfungen je Bereich und Kacheln.
class LernstandAnsicht extends StatelessWidget {
  final Map<String, dynamic> details;
  final String name;
  final DateTime? am;
  const LernstandAnsicht({super.key, required this.details, required this.name, this.am});

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width > 560;
    final teile = <Widget>[];

    final f = objekt(details['f']) ?? const <String, dynamic>{};
    final faecher = [for (var x = 1; x <= 5; x++) if (f['$x'] is Map) x];
    if (faecher.isNotEmpty) {
      teile.add(unterkopf('Prüfungsreife je Fach'));
      for (final x in faecher) {
        teile.add(_FachZeile(fach: x, e: objekt(f['$x'])!, breit: breit));
      }
      teile.add(const SizedBox(height: 10));
    }

    final tage = aktivitaetAus(details['t14'], am);
    if (tage.isNotEmpty) {
      final summe = tage.fold<int>(0, (s, t) => s + t.anzahl);
      final aktiv = tage.where((t) => t.anzahl > 0).length;
      teile.addAll([
        unterkopf('Aktivität · 14 Tage',
            zusatz: summe > 0 ? '${fmtN(summe)} Antworten · $aktiv ${aktiv == 1 ? 'Tag' : 'Tage'}' : 'keine Antworten'),
        AktivitaetDiagramm(tage: tage),
        const SizedBox(height: 18),
      ]);
    }

    final pr = objekt(details['pr']) ?? const <String, dynamic>{};
    final bereiche = [for (final k in kBereiche) if (pr[k] is Map) k];
    if (bereiche.isNotEmpty) {
      final pc = objekt(details['pc']) ?? const <String, dynamic>{};
      final g = ganzOderNull(pc['g']), bq = ganzOderNull(pc['bq']);
      final kopf = g != null
          ? 'Bestehenschance ${chanceText(g)}'
          : (bq != null ? 'Basisqualifikationen ${chanceText(bq)}' : null);
      teile.add(unterkopf('Prüfungen je Bereich', zusatz: kopf));
      for (final k in bereiche) {
        teile.add(_BereichZeile(kurz: kBereichKurz[k] ?? k, e: objekt(pr[k])!, breit: breit));
      }
      teile.add(const SizedBox(height: 12));
    }

    final echt = objekt(details['echt']);
    final echtN = ganz(echt?['n']);
    final kacheln = <Widget>[
      if (details['tage'] != null) VgKpi(wert: fmtN(ganz(details['tage'])), text: 'Lerntage in 120 Tagen', wertGroesse: 23),
      if (echtN > 0) ...[
        VgKpi(wert: fmtN(echtN), text: 'Prüfungen unter Echtbedingungen', wertGroesse: 23),
        VgKpi(wert: '${ganz(echt?['best'])} %', text: 'bestes Ergebnis dabei', wertGroesse: 23),
      ],
    ];
    if (kacheln.isNotEmpty) teile.add(KpiRaster(kacheln: kacheln, spalten: breit ? 4 : 2));

    if (teile.isEmpty) {
      return hinweis(['Noch keine Details – sie erscheinen, sobald ${name.isEmpty ? 'die Person' : name} wieder lernt.']);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: teile);
  }
}

/// „Recht“ – Balken in der Fachfarbe – „64 %“, darunter „150 von 260 gemeistert · 200 gesehen“.
class _FachZeile extends StatelessWidget {
  final int fach;
  final Map<String, dynamic> e;
  final bool breit;
  const _FachZeile({required this.fach, required this.e, required this.breit});

  @override
  Widget build(BuildContext context) {
    final r = ganz(e['r']).clamp(0, 100);
    final farbe = kFachColor[fach] ?? kPetrol;
    final name = Row(children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: farbe, shape: BoxShape.circle)),
      const SizedBox(width: 7),
      Flexible(
        child: Text(kFachKurz[fach] ?? '$fach',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
      ),
    ]);
    final balken = Semantics(
      label: '${kFachKurz[fach]}: $r Prozent',
      child: ExcludeSemantics(child: Balken(r / 100, hoehe: 8, farbe: farbe)),
    );
    final wert = Text('$r %', textAlign: TextAlign.right, style: monoStyle(12.5, color: kInk, weight: FontWeight.w600, spacing: 0));
    final zahlen = Text('${fmtN(ganz(e['m']))} von ${fmtN(ganz(e['n']))} gemeistert · ${fmtN(ganz(e['g']))} gesehen',
        style: TextStyle(fontSize: 11, color: kMuted));
    if (breit) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 150, child: name),
            const SizedBox(width: 10),
            Expanded(child: balken),
            const SizedBox(width: 10),
            SizedBox(width: 46, child: wert),
          ]),
          Padding(padding: const EdgeInsets.only(left: 160, top: 3), child: zahlen),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: name), const SizedBox(width: 10), wert]),
        const SizedBox(height: 4),
        balken,
        const SizedBox(height: 4),
        zahlen,
      ]),
    );
  }
}

/// „Recht – 2 von 3 bestanden · Ø 61 P – 71 %“.
class _BereichZeile extends StatelessWidget {
  final String kurz;
  final Map<String, dynamic> e;
  final bool breit;
  const _BereichZeile({required this.kurz, required this.e, required this.breit});

  @override
  Widget build(BuildContext context) {
    final s = ganzOderNull(e['s']);
    final name = Text(kurz,
        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk));
    final zahlen = Text('${ganz(e['ok'])} von ${ganz(e['n'])} bestanden${s != null ? ' · Ø $s P' : ''}',
        style: TextStyle(fontSize: 12, color: kMuted));
    final chance = Text(chanceText(ganzOderNull(e['c'])),
        textAlign: TextAlign.right, style: monoStyle(12.5, color: kPetrolInkDeep, weight: FontWeight.w600, spacing: 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLineSoft),
      ),
      child: breit
          ? Row(children: [
              Expanded(flex: 9, child: name),
              const SizedBox(width: 8),
              Expanded(flex: 20, child: zahlen),
              const SizedBox(width: 8),
              SizedBox(width: 58, child: chance),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [Expanded(child: name), const SizedBox(width: 8), chance]),
              const SizedBox(height: 2),
              zahlen,
            ]),
    );
  }
}
