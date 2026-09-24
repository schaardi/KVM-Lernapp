import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models.dart';
import '../pruefung/bereiche.dart';
import '../pruefung/echt.dart';
import '../pruefung/ergebnisse.dart';
import '../pruefung/pruef_aktionen.dart';
import '../pruefung/pruef_ui.dart';
import '../services/answer_store.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/pruef_stat.dart';
import '../widgets/ui.dart';
import 'aufgabenblatt_screen.dart';

/// Übersicht der Original-IHK-Prüfungen als eigener Bildschirm – die Liste
/// selbst ist [PruefungenListe] (auch die Seite „Prüfungen“).
class PruefungenScreen extends StatelessWidget {
  const PruefungenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: Text('Original-IHK-Prüfungen', style: dispStyle(20))),
      body: const SafeArea(child: PruefungenListe()),
    );
  }
}

const _monate = {
  'Januar': 1, 'Februar': 2, 'März': 3, 'April': 4, 'Mai': 5, 'Juni': 6,
  'Juli': 7, 'August': 8, 'September': 9, 'Oktober': 10, 'November': 11, 'Dezember': 12,
};

const _monateKurz = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'];

/// „4. Sept.“ (Web `toLocaleDateString('de-DE', {day, month: 'short'})`).
String tagKurz(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day}. ${_monateKurz[d.month - 1]}';
}

/// Eine Prüfung mit den Angaben aus ihrem Titel
/// („IHK-Prüfung <Bereich> – <Datum>“).
class _Eintrag {
  final CaseStudy c;
  final String bereich;
  final String datum;
  final int sort;
  final String? punkte;
  _Eintrag(this.c, this.bereich, this.datum, this.sort, this.punkte);

  factory _Eintrag.von(CaseStudy c) {
    final m = RegExp(r'^IHK-Prüfung (.+?) – (.+)$').firstMatch(c.title);
    final bereich = m?.group(1) ?? c.sub.replaceFirst(RegExp(r'^IHK-Prüfung:\s*'), '');
    final datum = m?.group(2) ?? '';
    final d = RegExp(r'(\d{1,2})\.\s*(\S+)\s*(\d{4})').firstMatch(datum);
    final sort = d == null
        ? 0
        : int.parse(d.group(3)!) * 10000 + (_monate[d.group(2)] ?? 0) * 100 + int.parse(d.group(1)!);
    final pkt = RegExp(r'(\d+)\s*Punkte insgesamt').firstMatch(c.context)?.group(1);
    return _Eintrag(c, bereich, datum, sort, pkt);
  }

  String get termin {
    if (c.termin.isNotEmpty) return c.termin;
    return bereich;
  }
}

/// Die Liste der Original-Prüfungen (FR-003 D, FR-014 5, FR-015 3): oben
/// „Deine Ergebnisse“ mit Bestehenschance, Filterchips nach Bereich, Termine
/// zum Aufklappen und je Prüfung Fortschritt, Ergebnis und die Knöpfe zum
/// Starten, Weitermachen, unter Prüfungsbedingungen und Neu starten.
class PruefungenListe extends StatefulWidget {
  final Widget? kopf;
  const PruefungenListe({super.key, this.kopf});

  @override
  State<PruefungenListe> createState() => _PruefungenListeState();
}

class _PruefungenListeState extends State<PruefungenListe> {
  final _scroll = ScrollController();
  final _filterKey = GlobalKey();
  String _filter = '';
  final _terminOffen = <String, bool>{};
  final _aufgabenOffen = <String>{};
  bool _uebersichtOffen = true;
  AppSeite? _seite;

  @override
  void initState() {
    super.initState();
    _seite = AppState.instance.seite;
    AppState.instance.addListener(_appGeaendert);
    pruefStand.addListener(_neu);
    Echtbedingungen.instance.addListener(_neu);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_appGeaendert);
    pruefStand.removeListener(_neu);
    Echtbedingungen.instance.removeListener(_neu);
    _scroll.dispose();
    super.dispose();
  }

  void _neu() {
    if (mounted) setState(() {});
  }

  /// Beim Öffnen der Seite neu aufbauen (Stand, Ergebnisse, laufende
  /// Prüfungsbedingungen) und oben beginnen.
  void _appGeaendert() {
    final s = AppState.instance.seite;
    if (s == AppSeite.pruefungen && _seite != AppSeite.pruefungen) {
      _terminOffen.clear();
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    _seite = s;
    _neu();
  }

  void _filtern(String f) {
    setState(() {
      _filter = f;
      _terminOffen.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _filterKey.currentContext;
      if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 250));
    });
  }

  Future<void> _oeffnen(CaseStudy c, [int start = 0]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AufgabenblattScreen(fall: c, startIndex: start)));
    AppState.instance.refresh();
    _neu();
  }

  Future<void> _echt(CaseStudy c) async {
    if (await echtStartenFragen(context, c) && mounted) await _oeffnen(c);
  }

  Future<void> _neuStarten(CaseStudy c) async {
    if (await neuStartenFragen(context, c) && mounted) await _oeffnen(c);
  }

  Future<void> _kopieren(CaseStudy c) async {
    await Clipboard.setData(ClipboardData(text: pruefungExportText(c)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prüfung mit Musterlösungen kopiert – jetzt in eine KI einfügen.')));
  }

  @override
  Widget build(BuildContext context) {
    final alle = DataService.instance.cases.where((c) => c.id.startsWith('P-')).map(_Eintrag.von).toList()
      ..sort((a, b) => b.sort - a.sort);
    final kopf = widget.kopf;
    final inhalt = alle.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Es sind noch keine Original-Prüfungen hinterlegt.',
                style: TextStyle(fontSize: 13, height: 1.55, color: kMuted)),
          )
        : _liste(alle);
    return ListView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16, kopf == null ? 14 : 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (kopf != null) kopf,
              Karte(padding: const EdgeInsets.fromLTRB(14, 14, 14, 14), child: inhalt),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _liste(List<_Eintrag> alle) {
    // Nach Prüfungstermin gruppieren (Frühjahr/Herbst JJJJ); je Termin FT und OK.
    final gruppen = <String, List<_Eintrag>>{};
    final gruppenSort = <String, int>{};
    for (final x in alle) {
      gruppen.putIfAbsent(x.termin, () => []).add(x);
      if (x.sort > (gruppenSort[x.termin] ?? -1)) gruppenSort[x.termin] = x.sort;
    }
    final termine = gruppen.keys.toList()..sort((a, b) => gruppenSort[b]!.compareTo(gruppenSort[a]!));
    // Filter nach Prüfungsbereich – bei drei Dutzend Prüfungen sonst eine
    // endlose Liste.
    final bereiche = alle.map((x) => x.bereich).toSet().toList()
      ..sort((a, b) {
        final r = bereichRang(a).compareTo(bereichRang(b));
        return r != 0 ? r : a.compareTo(b);
      });
    final sichtbar = alle.where((x) => _filter.isEmpty || x.bereich == _filter).toList();
    final mitStand = AnswerStore.instance.pruefungenMitStand();
    final ergAlle = <String, List<PruefDurchgang>>{};
    for (final e in PruefErgebnisse.instance.alle) {
      ergAlle.putIfAbsent(e.id, () => []).add(e);
    }

    final kinder = <Widget>[
      Text.rich(
        TextSpan(style: TextStyle(fontSize: 13, height: 1.55, color: kMuted), children: [
          TextSpan(text: '${alle.length} Original-Prüfungen', style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
          const TextSpan(
              text: ' mit amtlichen Lösungshinweisen: Aufgaben wie auf dem Prüfungsbogen lösen – mit Rechenweg und '
                  'ausfüllbaren Anlagen –, dann die Lösung aufdecken und dir selbst Punkte geben.'),
        ]),
      ),
      const SizedBox(height: 14),
      _uebersicht(),
      const SizedBox(height: 14),
      Wrap(key: _filterKey, spacing: 6, runSpacing: 6, children: [
        _chip('Alle', '', alle.length, null),
        for (final b in bereiche) _chip(bereichKurz(b), b, alle.where((x) => x.bereich == b).length, b),
      ]),
      const SizedBox(height: 8),
    ];

    var offeneTermine = 0;
    for (final t in termine) {
      final items = gruppen[t]!.where(sichtbar.contains).toList();
      if (items.isEmpty) continue;
      // Die zwei jüngsten Termine offen, ältere eingeklappt – außer dort ist
      // eine Prüfung begonnen oder ausgewertet.
      final vorgabe = offeneTermine < 2 ||
          _filter.isNotEmpty ||
          items.any((x) => mitStand.contains(x.c.id) || ergAlle.containsKey(x.c.id));
      offeneTermine++;
      final offen = _terminOffen[t] ?? vorgabe;
      kinder.add(_terminKopf(t, items.length, offen));
      if (offen) {
        for (final x in items) {
          kinder.add(_pruefung(x, mitStand.contains(x.c.id), ergAlle[x.c.id] ?? const []));
        }
      }
    }
    if (sichtbar.isEmpty) {
      kinder.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Für dieses Fach ist noch keine Prüfung hinterlegt.',
            style: TextStyle(fontSize: 13, height: 1.55, color: kMuted)),
      ));
    }
    kinder.add(_hinweis());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kinder);
  }

  Widget _chip(String label, String wert, int n, String? voll) {
    final an = _filter == wert;
    // Auf Handys etwas enger als im Web, damit die Chips auf 390 dp in drei
    // Zeilen passen (FR-002 F).
    final eng = MediaQuery.sizeOf(context).width < 400;
    final chip = Semantics(
      button: true,
      selected: an,
      label: '${voll ?? label}, $n Prüfungen',
      excludeSemantics: true,
      child: Material(
        color: an ? kPetrol : kPaper,
        shape: StadiumBorder(side: BorderSide(color: an ? kPetrol : kLineStrong)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _filtern(wert),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: EdgeInsets.symmetric(horizontal: eng ? 10 : 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: an ? Colors.white : kInk)),
              SizedBox(width: eng ? 5 : 6),
              Text('$n',
                  style: monoStyle(10.5,
                      color: an ? Colors.white.withValues(alpha: 0.78) : kMuted, weight: FontWeight.w600, spacing: 0)),
            ]),
          ),
        ),
      ),
    );
    return voll == null ? chip : Tooltip(message: voll, child: chip);
  }

  Widget _terminKopf(String t, int n, bool offen) {
    return Semantics(
      button: true,
      expanded: offen,
      child: InkWell(
        onTap: () => setState(() => _terminOffen[t] = !offen),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
          child: Row(children: [
            Text(t.toUpperCase(), style: dispStyle(14, color: kPetrolInkDeep).copyWith(letterSpacing: 0.4)),
            const SizedBox(width: 6),
            Text('$n', style: monoStyle(10.5, color: kMuted, weight: FontWeight.w500, spacing: 0)),
            const SizedBox(width: 2),
            Icon(offen ? Icons.expand_less : Icons.expand_more, size: 18, color: kMuted),
          ]),
        ),
      ),
    );
  }

  /// „Deine Ergebnisse“: bestanden je Bereich und die Bestehenschance
  /// (FR-014 5, Web `uebersichtHTML`).
  Widget _uebersicht() {
    final st = PruefErgebnisse.instance.statistik();
    final rahmen = BoxDecoration(
      color: kPetrolSoft,
      border: Border.all(color: kPetrolLine),
      borderRadius: BorderRadius.circular(14),
    );
    final titelStil = monoStyle(11, color: kPetrolInkDeep, weight: FontWeight.w700, spacing: 1.1);
    if (st.n == 0) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: rahmen,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DEINE ERGEBNISSE', style: titelStil),
          const SizedBox(height: 4),
          Text(
            'Löse eine Prüfung, gib dir für jede Teilaufgabe Punkte und tippe auf „Zum Ergebnis“. Dann siehst du '
            'hier, ob du bestanden hast, und deine Bestehenschance je Prüfungsbereich.',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: kInkSoft),
          ),
        ]),
      );
    }
    final handy = MediaQuery.sizeOf(context).width < 560;
    final fett = monoStyle(12.5, color: kInk, weight: FontWeight.w700, spacing: 0);

    Widget teil(TeilStand? t, String name) {
      if (t == null) return const SizedBox.shrink();
      final leer = t.p == null;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: kPaper,
          border: Border.all(color: kLine),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.toUpperCase(), style: monoStyle(9.5, color: kMuted, spacing: 0.8)),
          const SizedBox(height: 3),
          Text(leer ? '${t.n - t.fehlt.length}/${t.n}' : peProzent(t.p),
              style: dispStyle(26, color: leer ? kPlaceholder : kPetrolInkDeep)),
          const SizedBox(height: 2),
          Text(
            leer
                ? 'Bereiche geprüft · für die Chance fehlt noch: '
                    '${t.fehlt.map((k) => pruefBereich(k)?.kurz ?? k).join(', ')}'
                : 'Bestehenschance',
            style: TextStyle(fontSize: 11.5, height: 1.35, color: kMuted),
          ),
        ]),
      );
    }

    final kacheln = <Widget>[
      teil(st.bq, 'Basisqualifikationen'),
      if (st.hq != null) teil(st.hq, 'Handlungsspezifisch'),
      if (st.hq != null && st.gesamt != null)
        teil(TeilStand(const [], 7, st.gesamt), 'Beide Teile'),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(handy ? 11 : 14, 12, handy ? 11 : 14, 12),
      decoration: rahmen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: _uebersichtOffen,
          child: InkWell(
            onTap: () => setState(() => _uebersichtOffen = !_uebersichtOffen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('DEINE ERGEBNISSE', style: titelStil),
                    const SizedBox(width: 2),
                    Icon(_uebersichtOffen ? Icons.expand_less : Icons.expand_more, size: 18, color: kMuted),
                  ]),
                  Text.rich(TextSpan(style: TextStyle(fontSize: 12.5, color: kInkSoft), children: [
                    TextSpan(text: '${st.ok}', style: fett),
                    const TextSpan(text: ' von '),
                    TextSpan(text: '${st.n}', style: fett),
                    TextSpan(text: ' ${st.n == 1 ? 'Prüfung' : 'Prüfungen'} bestanden · Ø ${st.schnitt} P'),
                  ])),
                ],
              ),
            ),
          ),
        ),
        if (_uebersichtOffen) ...[
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            // Wie `repeat(auto-fit, minmax(150px, 1fr))` mit 8 Abstand.
            final spalten = ((c.maxWidth + 8) / 158).floor().clamp(1, kacheln.length);
            final breite = (c.maxWidth - 8 * (spalten - 1)) / spalten;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              for (final k in kacheln) SizedBox(width: breite, child: k),
            ]);
          }),
          const SizedBox(height: 10),
          for (final b in kPruefBereiche)
            if (b.teil != 'hq' || st.hq != null) _bereichZeile(st.bereiche[b.k]!, handy),
          const SizedBox(height: 10),
          Text(
            'Bestanden heißt: mindestens 50 von 100 Punkten in jedem Prüfungsbereich. Je Prüfung zählt der erste '
            'vollständig bewertete Durchgang. Die Chance ist eine Schätzung aus deinen Selbstbewertungen: Neuere '
            'Prüfungen und solche unter Prüfungsbedingungen zählen mehr, und mit wenigen Prüfungen je Bereich ist sie '
            'noch vorsichtig. Für einen Teil muss jeder Bereich sitzen – deshalb liegt die Chance für den Teil unter '
            'der einzelner Bereiche. Mündliche Ergänzungsprüfung und Fachgespräch sind nicht eingerechnet.',
            style: TextStyle(fontSize: 11.5, height: 1.5, color: kMuted),
          ),
        ],
      ]),
    );
  }

  Widget _bereichZeile(BereichStand b, bool handy) {
    final c = b.chance;
    final stufe = chanceStufe(c);
    final (farbe, ink) = switch (stufe) {
      ChanceStufe.gut => (kOk, kOkInk),
      ChanceStufe.mittel => (kAmber, kAmberInk),
      ChanceStufe.knapp => (kErr, kErrInk),
      null => (kMuted, kMuted),
    };
    final an = _filter == b.bereich.name;
    final name = Text(b.bereich.kurz,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk));
    final ergebnisse = b.n == 0
        ? Text('noch keine Prüfung', style: TextStyle(fontSize: 11.5, color: kMuted))
        : Wrap(spacing: 3, runSpacing: 3, children: [
            for (final e in b.erst.length > 6 ? b.erst.sublist(b.erst.length - 6) : b.erst)
              Tooltip(
                message: '${e.p} Punkte',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: e.p >= 50 ? kOkSoft : kErrSoft,
                    border: Border.all(color: e.p >= 50 ? kOkLine : kErrLine),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('${e.p}',
                      style: monoStyle(10.5, color: e.p >= 50 ? kOkInk : kErrInk, weight: FontWeight.w700, spacing: 0)
                          .copyWith(height: 1)),
                ),
              ),
          ]);
    final chance = Text(c == null ? '–' : peProzent(c),
        style: monoStyle(13, color: ink, weight: FontWeight.w700, spacing: 0));
    final balken = Balken(c ?? 0, hoehe: 4, farbe: farbe);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: an,
        label: 'Nur ${b.bereich.kurz} zeigen',
        child: Material(
          color: kPaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: an ? kPetrol : Colors.transparent),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            // Antippen filtert die Liste auf den Bereich, erneut antippen hebt
            // den Filter auf.
            onTap: () => _filtern(an ? '' : b.bereich.name),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              child: handy
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [Expanded(child: name), chance]),
                      const SizedBox(height: 5),
                      ergebnisse,
                      const SizedBox(height: 5),
                      balken,
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Expanded(flex: 11, child: name),
                        const SizedBox(width: 10),
                        Expanded(flex: 20, child: ergebnisse),
                        const SizedBox(width: 10),
                        SizedBox(width: 52, child: Align(alignment: Alignment.centerRight, child: chance)),
                      ]),
                      const SizedBox(height: 3),
                      balken,
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pruefung(_Eintrag x, bool stand, List<PruefDurchgang> erg) {
    final c = x.c;
    final steps = c.steps;
    final store = AnswerStore.instance;
    // Teile gelten als bearbeitet mit Text oder Rechenweg.
    bool fertig(Question s) => store.hatAntwort(s.id);
    final bearbeitet = steps.where(fertig).length;
    var pkt = 0, bew = 0;
    for (final s in steps) {
      final p = store.points(s.id);
      if (p != null) {
        pkt += p;
        bew++;
      }
    }
    // Weiter an der ersten noch offenen Teilaufgabe
    var weiter = -1;
    if (bearbeitet > 0 && bearbeitet < steps.length) weiter = steps.indexWhere((s) => !fertig(s));
    final kurz = bereichVonId(c.id);
    final lauf = Echtbedingungen.instance.von(c.id);
    final laeuft = lauf != null && !lauf.abgegeben;
    final abgegeben = lauf != null && lauf.abgegeben;
    final min = echtMinuten(c);
    // Neu starten, sobald es etwas zu leeren gibt – auch mitten in einem
    // Durchgang unter Prüfungsbedingungen.
    final neu = stand || laeuft || abgegeben;

    final knoepfe = <Widget>[
      if (laeuft)
        _knopf(
          lauf.rest() > 0 ? 'Läuft · noch ${dauerText(lauf.rest())} – weiter →' : 'Zeit abgelaufen – auswerten →',
          () => _oeffnen(c),
          voll: true,
          icon: Icons.timer_outlined,
        )
      else if (abgegeben)
        _knopf('Abgegeben – jetzt auswerten →', () => _oeffnen(c), voll: true)
      else
        _knopf(
          weiter >= 0
              ? 'Weiter bei Aufgabe ${steps[weiter].nr} →'
              : (bearbeitet > 0 ? 'Prüfung öffnen' : 'Prüfung starten'),
          () => _oeffnen(c, weiter >= 0 ? weiter : 0),
          voll: true,
        ),
      if (neu)
        _knopf('Neu starten', () => _neuStarten(c),
            icon: Icons.restart_alt, tooltip: 'Leere Blätter: Antworten und Punkte dieser Prüfung löschen'),
      if (!laeuft && !abgegeben)
        _knopf('Unter Prüfungsbedingungen · $min min', () => _echt(c),
            icon: Icons.timer_outlined, tooltip: 'Mit Uhr über die echte Bearbeitungszeit, Lösungen erst nach der Abgabe'),
      _knopf('Für KI kopieren', () => _kopieren(c)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(color: const Color(0xFF102A32).withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(
              color: const Color(0xFF102A32).withValues(alpha: kPalette.isDark ? 0.4 : 0.22),
              blurRadius: 18,
              spreadRadius: -12,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _kuerzelFarbe(kurz), borderRadius: BorderRadius.circular(11)),
            child: Text(kurz, style: dispStyle(14, color: Colors.white, height: 1).copyWith(letterSpacing: 0.7)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.bereich, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3, color: kInk)),
              const SizedBox(height: 3),
              Text('${x.datum} · ${c.aufgaben.length} Aufgaben · ${steps.length} Teile',
                  style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          Pille(x.punkte != null ? '${x.punkte} P' : 'Prüfung',
              grund: kPetrolSoft, rand: kPetrolLine, schrift: kPetrolInkDeep, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
        ]),
        if (bearbeitet > 0 || bew > 0) ...[
          const SizedBox(height: 11),
          Row(children: [
            Expanded(
              child: Balken(steps.isEmpty ? 0 : bearbeitet / steps.length,
                  hoehe: 6, verlauf: LinearGradient(colors: [kPetrol, kOk])),
            ),
            const SizedBox(width: 9),
            Text.rich(TextSpan(style: monoStyle(11, color: kMuted, weight: FontWeight.w600, spacing: 0), children: [
              TextSpan(text: '$bearbeitet', style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
              TextSpan(text: '/${steps.length} Teile'),
              if (bew > 0) ...[
                const TextSpan(text: ' · '),
                TextSpan(text: '$pkt', style: TextStyle(color: kInk, fontWeight: FontWeight.w700)),
                const TextSpan(text: ' P'),
              ],
            ])),
          ]),
        ],
        const SizedBox(height: 11),
        Wrap(spacing: 8, runSpacing: 8, children: knoepfe),
        if (erg.isNotEmpty) _ergebnisZeile(erg),
        _aufgabenListe(c),
      ]),
    );
  }

  Color _kuerzelFarbe(String k) => switch (k) {
        'RE' => kPetrol,
        'BW' => kAmber,
        'MI' => kOk,
        'ZI' => kBlue,
        'NT' => kViolet,
        'FT' || 'OK' => kPlum,
        _ => kMuted,
      };

  Widget _knopf(String text, VoidCallback onTap, {bool voll = false, IconData? icon, String? tooltip}) {
    final stil = voll
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: kPetrolInk,
            backgroundColor: kPaper,
            side: BorderSide(color: kLine),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700),
          );
    final kind = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
      Flexible(child: Text(text)),
    ]);
    final b = voll
        ? FilledButton(onPressed: onTap, style: stil, child: kind)
        : OutlinedButton(onPressed: onTap, style: stil, child: kind);
    return tooltip == null ? b : Tooltip(message: tooltip, child: b);
  }

  /// Ergebniszeile einer Prüfung: der letzte Durchgang, bei Wiederholungen der
  /// Verlauf (Web `ergebnisHTML`).
  Widget _ergebnisZeile(List<PruefDurchgang> v) {
    final l = v.last;
    final gewertet = v.where((e) => e.gewertet).toList();
    final stil = TextStyle(fontSize: 12, height: 1.4, color: kMuted);
    final fett = TextStyle(fontWeight: FontWeight.w700, color: kInk);
    Widget status(String t, Color grund, Color rand, Color ink) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration:
              BoxDecoration(color: grund, border: Border.all(color: rand), borderRadius: BorderRadius.circular(20)),
          child: Text(t.toUpperCase(), style: monoStyle(10.5, color: ink, weight: FontWeight.w700, spacing: 0.6).copyWith(height: 1.2)),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 9, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (l.gewertet) ...[
          l.bestanden
              ? status('Bestanden', kOkSoft, kOkLine, kOkInk)
              : status('Nicht bestanden', kErrSoft, kErrLine, kErrInk),
          Text.rich(TextSpan(style: stil, children: [
            TextSpan(text: '${l.pkt} von ${l.max} P', style: fett),
            TextSpan(
                text: ' · Note ${l.note} · ${tagKurz(l.t)}'
                    '${l.echt ? ' · unter Prüfungsbedingungen${(l.dauer ?? 0) > 0 ? ', ${dauerText(l.dauer!)}' : ''}' : ''}'),
          ])),
        ] else ...[
          status('Noch nicht gewertet', kAmberSoft, kAmberLine, kAmberInk),
          Text(
              '${(l.teile ?? 0) > 0 ? '${l.bew ?? 0} von ${l.teile} Teilen bewertet · ' : ''}${tagKurz(l.t)}',
              style: stil),
        ],
        if (gewertet.length > 1)
          Tooltip(
            message: 'Gewertete Durchgänge, ältester zuerst. Für die Bestehenschance zählt der erste.',
            child: Text('${gewertet.length} Durchgänge: ${gewertet.map((e) => e.pkt).join(' → ')} P',
                style: monoStyle(11, color: kInkSoft, weight: FontWeight.w500, spacing: 0)),
          ),
      ]),
    );
  }

  /// „Einzelne Aufgabe öffnen“: die Aufgaben mit ihren Teilaufgaben – tippen
  /// öffnet das Aufgabenblatt direkt bei dieser Aufgabe.
  Widget _aufgabenListe(CaseStudy c) {
    if (c.aufgaben.isEmpty) return const SizedBox.shrink();
    final offen = _aufgabenOffen.contains(c.id);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: kLine))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: offen,
          child: InkWell(
            onTap: () => setState(() => offen ? _aufgabenOffen.remove(c.id) : _aufgabenOffen.add(c.id)),
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text('Einzelne Aufgabe öffnen',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kPetrolInk)),
                ),
                const SizedBox(width: 2),
                Icon(offen ? Icons.expand_less : Icons.expand_more, size: 18, color: kPetrolInk),
              ]),
            ),
          ),
        ),
        if (offen)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LayoutBuilder(builder: (context, box) {
              // Wie `repeat(auto-fill, minmax(168px, 1fr))` mit 6 Abstand.
              final spalten = ((box.maxWidth + 6) / 174).floor().clamp(1, 6);
              final breite = (box.maxWidth - 6 * (spalten - 1)) / spalten;
              return Wrap(spacing: 6, runSpacing: 6, children: [
                for (final a in c.aufgaben) SizedBox(width: breite, child: _aufgabeKnopf(c, a)),
              ]);
            }),
          ),
      ]),
    );
  }

  Widget _aufgabeKnopf(CaseStudy c, Aufgabe a) {
    final teile = c.steps.where((s) => s.nr == a.nr).toList();
    final erste = c.steps.indexWhere((s) => s.nr == a.nr);
    return Material(
      color: kPaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: BorderSide(color: kLine)),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => _oeffnen(c, erste < 0 ? 0 : erste),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text('Aufgabe ${a.nr}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kInk))),
              Text('${a.pts > 0 ? a.pts : '–'} P.', style: monoStyle(10.5, color: kMuted, weight: FontWeight.w500, spacing: 0)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 3, runSpacing: 3, children: [
              for (final s in teile)
                Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AnswerStore.instance.hatAntwort(s.id) ? kOkSoft : kBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(s.teil,
                      style: monoStyle(9.5,
                              color: AnswerStore.instance.hatAntwort(s.id) ? kOkInk : kMuted,
                              weight: FontWeight.w700,
                              spacing: 0)
                          .copyWith(height: 1)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _hinweis() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: kAmberSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: kAmber, width: 3)),
      ),
      child: Text.rich(TextSpan(style: TextStyle(fontSize: 12.5, height: 1.5, color: kInk), children: const [
        TextSpan(text: 'Zu den Lösungen:', style: TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(
            text: ' Hinterlegt sind die amtlichen Lösungshinweise der IHK samt VO-Bezug und – wo angegeben – '
                'Punkteverteilung. „Für KI kopieren“ liefert die ganze Prüfung als Text, etwa um eigene Antworten '
                'von einer KI bewerten zu lassen.'),
      ])),
    );
  }
}

/// Vollständiger Prüfauftrag für eine KI – identisch zur Web-Fassung
/// (`exportText` im Prüfungsmodul).
String pruefungExportText(CaseStudy c) {
  final amtlich = c.steps.any((s) => s.amtlich);
  final b = StringBuffer()
    ..writeln('PRÜFAUFTRAG')
    ..writeln()
    ..writeln('Du bist erfahrener Prüfer und Dozent für die Fortbildung '
        '"Geprüfte/-r Meister/-in für Kraftverkehr (IHK)". Unten steht eine '
        'Original-Prüfungsaufgabe der IHK sowie zu jeder Teilaufgabe '
        '${amtlich ? 'der amtliche Lösungshinweis der IHK.' : 'eine Musterlösung, die NICHT von der IHK stammt, sondern nachträglich erarbeitet wurde.'}')
    ..writeln()
    ..writeln(amtlich
        ? 'Prüfe je Teilaufgabe knapp und gib eine Punkteempfehlung:'
        : 'Prüfe jede Musterlösung und antworte je Teilaufgabe knapp:')
    ..writeln('- Bewertung: korrekt / teilweise korrekt / fehlerhaft')
    ..writeln('- Fachliche Fehler konkret benennen (falsche Aussage, falsche '
        'Rechnung, veraltete Rechtsgrundlage) - oder "keine".')
    ..writeln('- Vollständigkeit: Reicht der Umfang für die angegebene '
        'Punktzahl? Faustregel: etwa 2 Punkte je verlangtem Element.')
    ..writeln('- Ergänzung: Was würde ein Prüfer zusätzlich erwarten?')
    ..writeln()
    ..writeln('Achte besonders auf: (1) Rechenaufgaben eigenständig nachrechnen '
        'und Abweichungen mit eigenem Rechenweg nennen; (2) Rechtsgrundlagen auf '
        'Aktualität prüfen (ArbSchG, ArbZG, StVO, StVZO, BetrVG, DGUV, '
        'VO (EG) 561/2006, VO (EU) 165/2014, BKrFQG, GGVSEB/ADR, '
        'DIN EN ISO 9001); (3) Behördenbezeichnungen (BALM, früher BAG).')
    ..writeln()
    ..writeln('==============================')
    ..writeln(c.title)
    ..writeln('==============================')
    ..writeln()
    ..writeln('AUSGANGSSITUATION')
    ..writeln(c.context)
    ..writeln();
  for (final roh in c.steps) {
    // Mit der Aufgabe verbinden: Kopf und Ausgangslage stehen dort, damit der
    // Export dieselbe Form behält wie vor dem Umbau auf Aufgabenblätter.
    final s = roh.withCase(CaseContext(c.title, c.context, 0, c.steps.length), c.aufgabeVon(roh.nr));
    final teile = TaskParts.of(s).volltext.split('\n\n');
    b
      ..writeln('------------------------------')
      ..writeln(teile.isNotEmpty ? teile.first : '')
      ..writeln()
      ..writeln(teile.skip(1).join('\n\n'));
    final tabs = s.tabsEffektiv;
    if (tabs.isNotEmpty) {
      b
        ..writeln()
        ..writeln(tabs.map((t) => t.asText()).join('\n\n'));
    }
    final anlage = DataService.instance.anlage(s.bildEffektiv);
    if (anlage != null) {
      b.writeln('[Zur Aufgabe gehört eine Abbildung: ${anlage.titel.isNotEmpty ? anlage.titel : 'Anlage zur Aufgabe'}]');
    }
    b
      ..writeln()
      ..writeln(s.amtlich ? 'AMTLICHER LÖSUNGSHINWEIS (IHK):' : 'MUSTERLÖSUNG (zu prüfen):')
      ..writeln(s.a ?? '');
    if (s.vo != null && s.vo!.isNotEmpty) b.writeln('VO-Bezug: ${s.vo}');
    if (s.bewertung.isNotEmpty) b.writeln('Punkteverteilung: ${s.bewertung.join(' + ')} Punkte');
    if (s.e.isNotEmpty) {
      b
        ..writeln()
        ..writeln('Merksatz: ${s.e}');
    }
    b.writeln();
  }
  b
    ..writeln('==============================')
    ..writeln('Ende. Nenne abschließend, welche Teilaufgaben überarbeitet werden müssen.');
  return b.toString();
}
