import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/lerntage_service.dart';
import '../services/progress_service.dart';
import '../services/pruef_stat.dart';
import '../services/sync_service.dart';
import '../util/format.dart';
import '../widgets/ui.dart';
import 'bausteine.dart';
import 'gruppen_ansicht.dart';
import 'lernende_blatt.dart';
import 'modelle.dart';
import 'rangliste_tabelle.dart';
import 'vergleich_dienst.dart';
import 'werte.dart';

/// „x dabei“ rechts neben dem Seitentitel.
String? vergleichScope(VergleichDienst d) {
  final st = d.stand;
  if (!d.quelle.bereit || d.verfuegbar != true || st == null) return null;
  if (st.dabei && d.bearbeiten) return null;
  if (st.dabei || st.teilnehmende > 0) return '${fmtN(st.teilnehmende)} dabei';
  return null;
}

/// Inhalt der Seite „Vergleich“ (Web `vgZeigen`): abgemeldet, lädt,
/// Beitritt mit Spitznamen oder die Rangliste mit Reitern.
class VergleichInhalt extends StatelessWidget {
  const VergleichInhalt({super.key});

  @override
  Widget build(BuildContext context) {
    final d = VergleichDienst.instance;
    return ListenableBuilder(listenable: d, builder: (context, _) => _zustand(d));
  }

  Widget _zustand(VergleichDienst d) {
    if (!d.quelle.bereit) return const Karte(child: _Abgemeldet());
    final st = d.stand;
    if (st == null || d.verfuegbar != true) return Karte(child: lead('Rangliste wird geladen …'));
    if (!st.dabei || d.bearbeiten) {
      return Karte(child: _Beitritt(key: ValueKey('beitritt-${st.dabei}-${d.bearbeiten}'), d: d, st: st));
    }
    return Karte(child: _Dabei(d: d, st: st));
  }
}

// ---------------------------------------------------------------------------
// Abgemeldet (Sicherheitsnetz – in der App ist die Anmeldung Pflicht)

class _Abgemeldet extends StatelessWidget {
  const _Abgemeldet();

  Future<void> _anmelden() async {
    try {
      final ok = await AuthService.instance.signInWithGoogle();
      if (ok) await SyncService.instance.pullMergePush();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      absatz([
        'Wie stehst du im Vergleich zu anderen? Mit Konto kannst du einer freiwilligen ',
        const F('Wochenrangliste'),
        ' beitreten und siehst, wo du mit deiner Prüfungsreife stehst.',
      ]),
      const SizedBox(height: 12),
      VgKnopf('Mit Google anmelden', art: KnopfArt.voll, onPressed: AuthService.instance.ready ? _anmelden : null),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Beitreten bzw. Spitzname ändern

class _Beitritt extends StatefulWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _Beitritt({super.key, required this.d, required this.st});

  @override
  State<_Beitritt> createState() => _BeitrittState();
}

class _BeitrittState extends State<_Beitritt> {
  late final TextEditingController _name;
  bool _busy = false;
  String? _fehler;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.d.bearbeiten ? widget.st.name ?? '' : '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _fehler = null;
    });
    final f = await widget.d.spitznameSpeichern(_name.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _fehler = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final st = widget.st;
    final leute = d.leuteOk == true;
    final feld = TextField(
      controller: _name,
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      inputFormatters: [LengthLimitingTextInputFormatter(20)],
      onSubmitted: (_) => _speichern(),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kInk),
      decoration: feldStil('Spitzname, z. B. Lkw_Profi'),
    );
    final knoepfe = [
      VgKnopf(st.dabei ? 'Speichern' : 'Mitmachen', art: KnopfArt.voll, onPressed: _busy ? null : _speichern),
      if (st.dabei) VgKnopf('Abbrechen', art: KnopfArt.leise, onPressed: _busy ? null : d.bearbeitenAbbrechen),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!st.dabei) ...[
        lead('Vergleiche dich mit anderen Lernenden – freiwillig und nur mit Spitznamen:'),
        const SizedBox(height: 8),
        Punkte([
          const [F('Wochenrangliste'), ' nach beantworteten Fragen, jeden Montag neu'],
          const ['wie viele bei der ', F('Prüfungsreife'), ' hinter dir liegen'],
          const [F('Prüfungsrangliste'), ' nach bestandenen Original-Prüfungen – mit Bestehenschance'],
          const ['auf Wunsch ', F('Lerngruppen'), ' mit deinem Kurs – per Code'],
          if (leute) const [F('Freunde'), ' finden und ihren Lernstand je Fach sehen – und sie deinen'],
        ]),
      ] else
        lead('Neuer Spitzname für die Rangliste:'),
      const SizedBox(height: 12),
      FeldMitKnoepfen(feld: feld, knoepfe: knoepfe),
      if (_fehler != null) fehlerZeile(_fehler!),
      const SizedBox(height: 8),
      hinweis([
        'Sichtbar für andere sind nur dein Spitzname, deine Prüfungsreife, deine Antworten dieser Woche, '
            'deine Lerntage in Folge und deine Prüfungsergebnisse (bestanden, Ø-Punkte, Bestehenschance).',
        if (leute) ' Deinen Lernstand je Fach sehen nur deine Freunde – das kannst du im Profil ändern.',
        ' Austreten geht jederzeit – dein Eintrag',
        if (leute) ' samt Profil und Freundschaften',
        ' wird dann gelöscht.',
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Dabei: Kennzahlen, Band, Reiter, Umschalter, Liste, Fuß

class _Dabei extends StatelessWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _Dabei({required this.d, required this.st});

  @override
  Widget build(BuildContext context) {
    final pm = d.pruefModus;
    final kinder = <Widget>[
      pm ? _PruefKennzahlen(ps: d.pstand) : _WocheKennzahlen(st: st),
      const SizedBox(height: 14),
      if (d.anfragenOffen) _AnfragenBand(anfragen: d.fstand!.anfragen),
      if (d.gruppenOk == true || d.leuteOk == true) ...[
        _reiter(context),
        const SizedBox(height: 12),
      ],
      if (d.pruefOk == true && !d.gform) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: Umschalter<RanglistenModus>(
            werte: const [(RanglistenModus.woche, 'Diese Woche'), (RanglistenModus.pruef, 'Prüfungen')],
            gewaehlt: pm ? RanglistenModus.pruef : RanglistenModus.woche,
            onWahl: d.waehleModus,
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (d.gform)
        const GruppenFormular()
      else if (d.ansicht == 'freunde')
        _FreundeAnsicht(d: d, st: st)
      else if (d.ansicht != null)
        GruppenAnsicht(d: d)
      else if (pm)
        _PruefAlle(d: d, st: st)
      else
        _WocheAlle(d: d, st: st),
      const SizedBox(height: 10),
      _Fuss(d: d, st: st),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kinder);
  }

  Widget _reiter(BuildContext context) {
    return ReiterLeiste([
      Reiter('Alle', gewaehlt: d.ansicht == null && !d.gform, onTap: () => d.waehleAnsicht(null)),
      if (d.leuteOk == true)
        Reiter('Freunde', gewaehlt: d.ansicht == 'freunde' && !d.gform, onTap: () => d.waehleAnsicht('freunde')),
      if (d.gruppenOk == true) ...[
        for (final g in d.gruppen)
          Reiter(g.name, gewaehlt: d.ansicht == g.id && !d.gform, onTap: () => d.waehleAnsicht(g.id)),
        Reiter('+ Gruppe', gewaehlt: d.gform, gestrichelt: true, onTap: d.gformUmschalten),
      ],
    ]);
  }
}

class _WocheKennzahlen extends StatelessWidget {
  final RanglisteStand st;
  const _WocheKennzahlen({required this.st});

  @override
  Widget build(BuildContext context) {
    final andere = st.teilnehmende - 1 < 0 ? 0 : st.teilnehmende - 1;
    final vor = andere > 0 ? (st.reifeVor / andere * 100).round() : 0;
    final platz = st.meinPlatz;
    return _obenKacheln([
      VgKpi(
        wert: andere > 0 ? '$vor %' : '–',
        text: andere == 0
            ? 'Noch bist du allein – lade andere ein, dann gibt es einen Vergleich.'
            : (vor > 0
                ? 'der anderen liegen bei der Prüfungsreife hinter dir'
                : 'Noch liegen alle vor dir – jede gemeisterte Frage bringt dich nach vorn.'),
        balken: andere > 0 ? vor / 100 : null,
      ),
      VgKpi(
        wert: platz != null && platz > 0 ? '$platz.' : '–',
        text: platz != null && platz > 0
            ? 'Platz diese Woche von ${fmtN(st.wocheTeilnehmende)} · ${fmtN(st.meineAntworten ?? 0)} Antworten'
            : 'Diese Woche noch ohne Antwort – ab der ersten bist du in der Wochenliste.',
      ),
    ]);
  }
}

class _PruefKennzahlen extends StatelessWidget {
  final PruefRangliste? ps;
  const _PruefKennzahlen({required this.ps});

  @override
  Widget build(BuildContext context) {
    PruefStatistik st;
    try {
      st = pruefStatistik();
    } catch (_) {
      st = PruefStatistik.leer;
    }
    final (k1, k2) = pruefKennzahlen(st, mitHandlungsspezifisch(), ps);
    return _obenKacheln([
      VgKpi(wert: k1.wert, text: k1.text),
      VgKpi(wert: k2.wert, text: k2.text),
    ]);
  }
}

/// Zwei Kennzahlen nebeneinander; auf schmalen Handys untereinander, damit
/// lange Wörter („Basisqualifikationen“) nicht mitten im Wort brechen.
Widget _obenKacheln(List<Widget> kacheln) => LayoutBuilder(
      builder: (context, c) => KpiRaster(spalten: c.maxWidth < 300 ? 1 : 2, abstand: 10, kacheln: kacheln),
    );

class _AnfragenBand extends StatelessWidget {
  final List<ProfilKarte> anfragen;
  const _AnfragenBand({required this.anfragen});

  @override
  Widget build(BuildContext context) {
    return Band(
      text: absatz(
        anfragen.length == 1
            ? [F(anfragen.first.name), ' möchte mit dir befreundet sein.']
            : [F('${anfragen.length}'), ' Freundschaftsanfragen warten auf dich.'],
        groesse: 13,
        hoehe: 1.45,
        farbe: kInk,
      ),
      knoepfe: [
        VgKnopf('Ansehen', art: KnopfArt.voll, onPressed: () => oeffneLernende(context, tab: 'freunde')),
      ],
    );
  }
}

class _WocheAlle extends StatelessWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _WocheAlle({required this.d, required this.st});

  @override
  Widget build(BuildContext context) {
    final l = st.liste;
    final eigene = st.meinPlatz != null && st.meinPlatz! > 0 && !l.any((e) => e.ich)
        ? TabellenZeile(
            platz: st.meinPlatz!,
            name: st.name ?? '',
            a: fmtN(st.meineAntworten ?? 0),
            r: '${(ProgressService.instance.overallReife() * 100).round()} %',
            ich: true,
          )
        : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      unterkopf('Wochenrangliste · ${kwText(d.kw)}'),
      if (l.isEmpty)
        LeerKasten(gestrichelt: false, kinder: [leerText('Diese Woche hat noch niemand geantwortet. Fang an!')])
      else
        RanglisteTabelle(
          zeilen: [for (final e in l) TabellenZeile.woche(e)],
          eigeneNachLuecke: eigene,
          onName: profilOeffner(context, d),
        ),
    ]);
  }
}

class _PruefAlle extends StatelessWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _PruefAlle({required this.d, required this.st});

  @override
  Widget build(BuildContext context) {
    final ps = d.pstand;
    final kopf = unterkopf('Prüfungsrangliste · bestandene Original-Prüfungen');
    if (ps == null) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [kopf, lead('Wird geladen …')]);
    if (ps.liste.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        kopf,
        LeerKasten(gestrichelt: false, kinder: [
          leerText('Noch hat niemand eine Prüfung gewertet. Löse eine Original-Prüfung und bewerte dich – '
              'dann stehst du hier.'),
        ]),
      ]);
    }
    final ich = ps.ich;
    final eigene = ich != null && ich.platz > 0 && !ps.liste.any((e) => e.ich)
        ? TabellenZeile.pruef(PruefEintrag(
            platz: ich.platz,
            name: st.name ?? '',
            n: ich.n,
            ok: ich.ok,
            schnitt: ich.schnitt,
            chance: ich.chance,
            ich: true))
        : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      kopf,
      RanglisteTabelle(
        pruefung: true,
        zeilen: [for (final e in ps.liste) TabellenZeile.pruef(e)],
        eigeneNachLuecke: eigene,
        onName: profilOeffner(context, d),
      ),
      const SizedBox(height: 6),
      hinweis([kPruefFussnote]),
    ]);
  }
}

/// Reiter „Freunde“: du und deine Freunde nach Antworten dieser Woche bzw.
/// nach Prüfungen (lokal sortiert).
class _FreundeAnsicht extends StatelessWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _FreundeAnsicht({required this.d, required this.st});

  @override
  Widget build(BuildContext context) {
    final fs = d.fstand;
    if (fs == null) return lead('Freunde werden geladen …');
    final name = st.name ?? '';
    final ohneFreunde = fs.freunde.isEmpty;
    final leer = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        hinweis(['Noch keine Freunde. ']),
        VgKnopf('Lernende finden', art: KnopfArt.leise, onPressed: () => oeffneLernende(context, tab: 'alle')),
      ]),
    );
    if (d.pruefModus) {
      PruefStatistik stat;
      try {
        stat = pruefStatistik();
      } catch (_) {
        stat = PruefStatistik.leer;
      }
      final l = pruefSortiert([
        for (final k in fs.freunde)
          PruefEintrag(name: k.name, n: k.pruefN, ok: k.pruefOk, schnitt: k.pruefSchnitt, chance: k.chance),
        pruefIch(stat, name),
      ]);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        unterkopf('Du und deine Freunde · Prüfungen'),
        RanglisteTabelle(
            pruefung: true, zeilen: [for (final e in l) TabellenZeile.pruef(e)], onName: profilOeffner(context, d)),
        const SizedBox(height: 6),
        hinweis([kPruefFussnote]),
        if (ohneFreunde) leer,
      ]);
    }
    final l = wocheSortiert([
      for (final k in fs.freunde) WochenEintrag(platz: 0, name: k.name, antworten: k.antworten, reife: k.reife),
      WochenEintrag(
        platz: 0,
        name: name,
        // lokal gezählt oder vom Server – der höhere Stand
        antworten: math.max(LerntageService.instance.dieseWoche(), st.meineAntworten ?? 0),
        reife: (ProgressService.instance.overallReife() * 100).round(),
        ich: true,
      ),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      unterkopf('Du und deine Freunde · ${kwText(d.kw)}'),
      RanglisteTabelle(zeilen: [for (final e in l) TabellenZeile.woche(e)], onName: profilOeffner(context, d)),
      if (ohneFreunde) leer,
    ]);
  }
}

// ---------------------------------------------------------------------------
// Fuß: Du bist dabei als …, Lernende & Freunde, Spitzname ändern, Austreten

class _Fuss extends StatefulWidget {
  final VergleichDienst d;
  final RanglisteStand st;
  const _Fuss({required this.d, required this.st});

  @override
  State<_Fuss> createState() => _FussState();
}

class _FussState extends State<_Fuss> {
  bool _busy = false;

  Future<void> _austreten() async {
    final d = widget.d;
    final leute = d.leuteOk == true;
    final ok = await bestaetigen(
      context,
      titel: 'Aus der Rangliste austreten?',
      text: 'Dein Eintrag wird gelöscht${leute ? ' – samt Profil und Freundschaften.' : '.'}',
      ja: 'Austreten',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await d.austreten();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: absatz(['Du bist dabei als ', F(widget.st.name ?? '')], groesse: 12.5, farbe: kMuted),
        ),
        if (d.leuteOk == true) VgKnopf('Lernende & Freunde', onPressed: () => oeffneLernende(context)),
        VgKnopf('Spitzname ändern', art: KnopfArt.leise, onPressed: d.bearbeitenStarten),
        VgKnopf('Austreten', art: KnopfArt.leise, onPressed: _busy ? null : _austreten),
      ],
    );
  }
}
