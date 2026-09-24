import 'package:flutter/material.dart';
import '../constants.dart';
import '../features/melden.dart';
import '../models.dart';
import '../services/answer_store.dart';
import '../widgets/anlage_bild.dart';
import '../widgets/anlage_tabelle.dart';
import '../widgets/ui.dart';
import 'pruef_text.dart';
import 'pruef_ui.dart';
import 'rechenweg.dart';
import 'skizze.dart';

/// Rechenaufgabe: verlangt eine Berechnung, und der Lösungshinweis rechnet.
/// Dort steht der Rechenweg gleich offen; sonst ist er einen Tipp entfernt
/// (Web `blRechenteil`).
bool istRechenteil(Question q) {
  if (!RegExp(r'\b(berechn|errechn|ermittel|kalkulier|rechnerisch|Rechenweg)', caseSensitive: false).hasMatch(q.q)) {
    return false;
  }
  return (q.a ?? '').split('\n').any((l) => RegExp(r'\d').hasMatch(l) && l.contains('=') && RegExp(r'[+\-−–·÷×:/]').hasMatch(l));
}

/// Eine Teilaufgabe als eigene Karte (FR-003 C.5): Statusstreifen links,
/// Kopf mit Buchstabe, Punkten und „baut auf … auf“, Frage als Prüfungstext,
/// Antwortbereich mit Rechenweg und Skizze – nach dem Aufdecken eigene
/// Antwort, amtliche Lösung und Selbstbewertung.
class TeilKarte extends StatelessWidget {
  final Question frage;
  final bool aufgedeckt;
  final bool bearbeitet;
  final bool? ergebnis;
  final String? vorher;
  final bool echtLaeuft;
  final bool rechenweg;
  final bool skizze;
  final bool rechenwegFokus;
  final TextEditingController controller;
  final FocusNode fokus;

  /// Bild-Anlage der Teilaufgabe oder ihrer Aufgabe (Skizze „Auf der Anlage“).
  final String? anlageRef;

  /// „Aufgabe 2 b)“ – für den Melde-Dialog.
  final String bezug;
  final ValueChanged<String> onAntwort;
  final VoidCallback onAenderung;
  final VoidCallback onAufdecken;
  final ValueChanged<int> onPunkte;
  final ValueChanged<bool> onGewusst;
  final VoidCallback onRechenweg;
  final VoidCallback onSkizze;
  final ValueChanged<String> onBraucht;
  final ValueChanged<AktivesFeld> onFokus;

  const TeilKarte({
    super.key,
    required this.frage,
    required this.aufgedeckt,
    required this.bearbeitet,
    required this.ergebnis,
    required this.vorher,
    required this.echtLaeuft,
    required this.rechenweg,
    required this.skizze,
    required this.rechenwegFokus,
    required this.controller,
    required this.fokus,
    required this.anlageRef,
    required this.bezug,
    required this.onAntwort,
    required this.onAenderung,
    required this.onAufdecken,
    required this.onPunkte,
    required this.onGewusst,
    required this.onRechenweg,
    required this.onSkizze,
    required this.onBraucht,
    required this.onFokus,
  });

  @override
  Widget build(BuildContext context) {
    final q = frage;
    final schmal = MediaQuery.sizeOf(context).width <= 520;
    final streifen = aufgedeckt ? kPetrol : (bearbeitet ? kOk : kLineStrong);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(color: const Color(0xFF102A32).withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(
              color: const Color(0xFF102A32).withValues(alpha: kPalette.isDark ? 0.4 : 0.18),
              blurRadius: 22,
              spreadRadius: -12,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          left: 0,
          top: 16,
          bottom: 16,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: streifen,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(schmal ? 14 : 18, 15, schmal ? 12 : 16, schmal ? 14 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _kopf(context),
            if (vorher != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(9)),
                child: Text.rich(TextSpan(style: TextStyle(fontSize: 12.5, height: 1.5, color: kInkSoft), children: [
                  for (final (i, teil) in vorher!.split('\n\n').indexed) ...[
                    if (i > 0) const TextSpan(text: '\n\n'),
                    TextSpan(
                        text: teil.split('\n').first,
                        style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                    TextSpan(text: '\n${teil.split('\n').skip(1).join('\n')}'),
                  ],
                ])),
              ),
            ],
            PruefText(q.q,
                stil: TextStyle(fontSize: 15.5, height: 1.55, fontWeight: FontWeight.w600, color: kInk)),
            for (var i = 0; i < q.tabs.length; i++)
              AnlageTabelle(q.tabs[i],
                  speicherKey: '${q.id}#s$i',
                  loesung: (aufgedeckt && q.tabs[i].passtZu(q.tabL)) ? q.tabL : null,
                  onEingabe: onAenderung,
                  onFokus: onFokus),
            if (q.bild != null) AnlageBild(q.bild),
            const SizedBox(height: 12),
            if (aufgedeckt) _Loesung(this) else ..._antwort(context),
          ]),
        ),
      ]),
    );
  }

  Widget _kopf(BuildContext context) {
    final q = frage;
    final badgeGrund = aufgedeckt ? kPetrol : (bearbeitet ? kOk : kInk);
    final badgeSchrift = (aufgedeckt || bearbeitet) ? Colors.white : kPaper;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (q.teil.isNotEmpty) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: badgeGrund, shape: BoxShape.circle),
                child: Text(q.teil, style: dispStyle(17, color: badgeSchrift, height: 1)),
              ),
              Text('Teilaufgabe ${q.teil})',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kMuted)),
            ],
            if (q.pts > 0)
              Pille('${q.pts} ${q.pts == 1 ? 'Punkt' : 'Punkte'}',
                  grund: kPetrolSoft, rand: kPetrolLine, schrift: kPetrolInkDeep),
            if (q.braucht.isNotEmpty)
              Material(
                color: kGoldSoft,
                shape: StadiumBorder(side: BorderSide(color: kGoldLine)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onBraucht(q.braucht.first),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    child: Text('baut auf ${q.braucht.join('), ')}) auf',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGoldInk)),
                  ),
                ),
              ),
          ]),
        ),
        MeldenKnopf(frageId: q.id, bezug: bezug, kontext: const {'modus': 'scrBlatt'}, kompakt: true),
      ]),
    );
  }

  List<Widget> _antwort(BuildContext context) {
    final q = frage;
    final klein = rechenweg || skizze;
    return [
      if (rechenweg)
        RechenwegFeld(
          key: ValueKey('rw-${q.id}'),
          id: q.id,
          autofokus: rechenwegFokus,
          onAenderung: onAenderung,
          onFokus: onFokus,
        ),
      if (skizze) SkizzeFeld(key: ValueKey('sk-${q.id}'), frage: q, anlageRef: anlageRef, onAenderung: onAenderung),
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: kopfLabel(klein ? 'Erläuterung · optional' : 'Deine Antwort · wie in der Prüfung', groesse: 10),
      ),
      TextField(
        controller: controller,
        focusNode: fokus,
        maxLines: null,
        minLines: klein ? 2 : 3,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: onAntwort,
        style: TextStyle(fontSize: 14.5, height: 1.5, color: kInk),
        decoration: InputDecoration(
          hintText: skizze && !rechenweg
              ? 'Erläuterung zur Skizze, z. B. gewählte Diagrammart …'
              : (rechenweg ? 'Begründung, Beurteilung oder Antwortsatz …' : 'Antwort schreiben …'),
          filled: true,
          fillColor: kPaper,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kLine)),
          enabledBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kLineStrong)),
          focusedBorder:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPetrol, width: 1.6)),
        ),
      ),
      const SizedBox(height: 11),
      Wrap(spacing: 9, runSpacing: 9, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (!echtLaeuft)
          FilledButton.icon(
            onPressed: onAufdecken,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
            ),
            label: Text('Lösung${q.teil.isNotEmpty ? ' zu ${q.teil})' : ''} aufdecken'),
          ),
        if (!rechenweg) _werkzeug(Icons.calculate_outlined, 'Rechenweg', onRechenweg),
        if (!skizze) _werkzeug(Icons.draw_outlined, 'Skizze', onSkizze),
      ]),
    ];
  }

  Widget _werkzeug(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPetrolInk,
          side: BorderSide(color: kLineStrong),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        label: Text(label),
      );
}

/// Nach dem Aufdecken (FR-003 C.6): „Deine Antwort“ und „Amtliche
/// Lösungshinweise“, darunter die Selbstbewertung.
class _Loesung extends StatelessWidget {
  final TeilKarte k;
  const _Loesung(this.k);

  @override
  Widget build(BuildContext context) {
    final q = k.frage;
    final store = AnswerStore.instance;
    final text = store.get(q.id).trim();
    final rw = store.calcText(q.id);
    final sk = store.hatSkizze(q.id);
    final leer = text.isEmpty && rw.isEmpty && !sk;
    final max = q.maxPoints;
    // Die ausgefüllte Anlage steht nur dann hier, wenn sie nicht schon oben in
    // der Anlage selbst gezeigt wird (dort mit den eigenen Eingaben daneben).
    final tabUnten = q.tabL != null &&
        !q.tabs.any((t) => t.passtZu(q.tabL)) &&
        !(q.aufgabe?.tabs ?? const <Anlage>[]).any((t) => t.passtZu(q.tabL));
    final fuss = [
      if ((q.vo ?? '').isNotEmpty) 'VO-Bezug: ${q.vo}',
      if (q.bewertung.isNotEmpty) 'Punkteverteilung: ${q.bewertung.join(' + ')} Punkte',
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _block(
        titel: 'Deine Antwort',
        loesung: false,
        kind: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
          child: leer
              ? Text('— leer abgegeben —',
                  style: TextStyle(fontSize: 13.5, height: 1.55, fontStyle: FontStyle.italic, color: kMuted))
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (sk) ...[SkizzeBild(id: q.id, anlageRef: k.anlageRef), const SizedBox(height: 10)],
                  if (rw.isNotEmpty) ...[
                    PtRechenkasten(rw.split('\n'), TextStyle(fontSize: 13.5, height: 1.55, color: kInkSoft)),
                    const SizedBox(height: 8),
                  ],
                  if (text.isNotEmpty) Text(text, style: TextStyle(fontSize: 13.5, height: 1.55, color: kInkSoft)),
                ]),
        ),
      ),
      const SizedBox(height: 12),
      _block(
        titel: q.amtlich ? 'Amtliche Lösungshinweise · IHK' : 'Musterlösung · nicht amtlich',
        loesung: true,
        kind: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PruefText(q.a ?? q.e, stil: TextStyle(fontSize: 14, height: 1.6, color: kInk)),
              if (q.bildL != null) AnlageBild(q.bildL, fallbackTitel: 'Lösungsskizze der IHK'),
              if (tabUnten) AnlageTabelle(q.tabL!),
            ]),
          ),
          if (fuss.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 0, 13, 11),
              child: Text(fuss.join(' · '), style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (max > 0)
        PunkteWahl(max: max, wert: store.points(q.id), onWahl: k.onPunkte)
      else
        _gewusst(),
    ]);
  }

  Widget _block({required String titel, required bool loesung, required Widget kind}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: loesung ? kPetrolLine : kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: loesung ? kPetrolSoft : kSurface,
            border: Border(bottom: BorderSide(color: loesung ? kPetrolLine : kLine)),
          ),
          child: kopfLabel(titel, farbe: loesung ? kPetrolInkDeep : kMuted),
        ),
        kind,
      ]),
    );
  }

  /// Fallaufgaben ohne IHK-Punkte: die Selbsteinschätzung zählt fürs Ergebnis
  /// und für den Lernfortschritt.
  Widget _gewusst() {
    Widget knopf(String t, bool wert, Color farbe, Color ink, Color soft) => Expanded(
          child: OutlinedButton(
            onPressed: () => k.onGewusst(wert),
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: k.ergebnis == wert ? soft : kPaper,
              side: BorderSide(color: farbe, width: k.ergebnis == wert ? 2 : 1),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: Text(t),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        kopfLabel('Konntest du die Aufgabe?', groesse: 10),
        const SizedBox(height: 9),
        Row(children: [
          knopf('Nicht gewusst', false, kErr, kErrInk, kErrSoft),
          const SizedBox(width: 9),
          knopf('Gewusst', true, kOk, kOkInk, kOkSoft),
        ]),
      ]),
    );
  }
}
