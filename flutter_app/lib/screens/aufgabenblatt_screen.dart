import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models.dart';
import '../pruefung/echt.dart';
import '../pruefung/pruef_text.dart';
import '../pruefung/pruef_ui.dart';
import '../pruefung/skizze_daten.dart';
import '../pruefung/teil_karte.dart';
import '../services/answer_store.dart';
import '../services/data_service.dart';
import '../services/letzte_pruefung.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../widgets/anlage_bild.dart';
import '../widgets/anlage_tabelle.dart';
import '../widgets/ui.dart';
import '../werkzeuge/rechner_modell.dart';
import '../widgets/werkzeug_dock.dart';
import 'result_screen.dart';

/// Eine Original-IHK-Prüfung als Aufgabenblatt (FR-003 C).
///
/// Gezeigt wird immer eine **ganze Aufgabe**: ihre Ausgangslage, ihre Anlagen
/// und alle Teilaufgaben a–x untereinander – so, wie das Blatt in der Prüfung
/// vor einem liegt. Wer a) beantwortet, sieht damit auch, was b) und c)
/// verlangen; daran hängt, wie ausführlich die Antwort ausfallen muss. Oben
/// läuft eine Leiste mit den Aufgaben der Prüfung und dem Bearbeitungsstand
/// mit, unter Prüfungsbedingungen (FR-007) dazu die Uhr.
///
/// Der `QuizScreen` bleibt für Auswahl-, Rechen- und offene Einzelfragen
/// zuständig. Beide schreiben in denselben [AnswerStore], die Schritt-IDs sind
/// dieselben wie zuvor – gespeicherte Antworten bleiben gültig.
class AufgabenblattScreen extends StatefulWidget {
  final CaseStudy fall;

  /// Teilaufgabe, bei der geöffnet werden soll (Index in `fall.steps`).
  final int startIndex;

  const AufgabenblattScreen({super.key, required this.fall, this.startIndex = 0});

  @override
  State<AufgabenblattScreen> createState() => _AufgabenblattScreenState();
}

class _AufgabenblattScreenState extends State<AufgabenblattScreen> {
  late final List<Question> _pool;
  late final List<int> _nummern;
  late int _nr;

  final _aufgedeckt = <String>{};

  /// Bearbeitete Teilaufgaben – hält Leiste und Karten aktuell, ohne bei jedem
  /// Tastendruck das ganze Blatt neu zu bauen.
  final _bearbeitet = <String>{};
  final _ctrl = <String, TextEditingController>{};
  final _fokus = <String, FocusNode>{};
  late final List<bool?> _results;
  final _wrong = <Question>[];
  final _scroll = ScrollController();
  final _karten = <String, GlobalKey>{};
  final _pillen = <int, GlobalKey>{};

  /// Ausgangssituation: offen beim Start (an der ersten Teilaufgabe), beim
  /// Wechsel zu – es sei denn, man hat sie selbst aufgeklappt (FR-002 G).
  late bool _ctxOffen;
  bool _ctxBeruehrt = false;

  final _rwOffen = <String>{};
  final _skOffen = <String>{};
  String? _rwFokus;

  /// Zuletzt angetippte Teilaufgabe – Ziel für Vorlagen aus dem Formelbuch.
  String? _ziel;

  /// Zuletzt fokussiertes Eingabefeld – Ziel für „Übernehmen“ aus dem Rechner.
  AktivesFeld? _aktiv;

  bool get _pruef => widget.fall.id.startsWith('P-');
  EchtLauf? get _echt => Echtbedingungen.instance.von(widget.fall.id);
  bool get _laeuft => Echtbedingungen.instance.laeuft(widget.fall.id);

  @override
  void initState() {
    super.initState();
    _pool = widget.fall.asPool();
    _results = List<bool?>.filled(_pool.length, null);
    _nummern = widget.fall.aufgaben.map((a) => a.nr).toList();
    for (final q in _pool) {
      if (_hatAntwort(q)) _bearbeitet.add(q.id);
    }
    final start = (widget.startIndex >= 0 && widget.startIndex < _pool.length) ? _pool[widget.startIndex] : null;
    _nr = start?.nr ?? (_nummern.isNotEmpty ? _nummern.first : 0);
    _ctxOffen = widget.startIndex <= 0;
    // Nach der Abgabe sind alle Lösungen offen.
    if (_echt?.abgegeben ?? false) _aufgedeckt.addAll(_pool.map((q) => q.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // „Zuletzt geöffnet“ erst nach dem Aufbau merken – die Startseite hört
      // darauf und darf nicht mitten im Bauen neu zeichnen.
      LetztePruefung.instance.merken(widget.fall.id, _nr);
      if (!mounted) return;
      // Einstieg: an der ersten Teilaufgabe bleibt die Seite oben
      // (Ausgangslage sichtbar); nur zu späteren Teilen wird gescrollt.
      final teile = _teile(_nr);
      if (start != null && teile.isNotEmpty && teile.first.id != start.id) _zeige(start.id);
      _pilleZeigen();
      // Beim Wiederöffnen nach Ablauf gilt die Prüfung als abgegeben.
      final e = _echt;
      if (e != null && !e.abgegeben && e.rest() <= 0) _abgeben(zeitUm: true);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final n in _fokus.values) {
      n.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  List<Question> _teile(int nr) => _pool.where((q) => q.nr == nr).toList();
  Aufgabe? get _aufgabe => widget.fall.aufgabeVon(_nr);
  int get _pos => _nummern.indexOf(_nr);

  /// Speicherschlüssel einer ausfüllbaren Anlage. Er hängt an der ID der ersten
  /// Teilaufgabe, damit die Eintragungen einen Neustart überdauern.
  String _tabKey(int nr, int i) {
    final t = _teile(nr);
    return '${t.isEmpty ? 'nr$nr' : t.first.id}#t$i';
  }

  /// Die Lösungstabelle einer Aufgabe steht an der Teilaufgabe und wird erst
  /// nach dem Aufdecken gezeigt.
  Anlage? _tabLoesung(int nr, Anlage tab) {
    for (final q in _teile(nr)) {
      if (q.tabL != null && _aufgedeckt.contains(q.id) && tab.passtZu(q.tabL)) return q.tabL;
    }
    return null;
  }

  /// Bearbeitet: Text, Rechenweg, Skizze oder Eintragungen in einer Anlage.
  /// Eine Anlage zum Ausfüllen gehört der ganzen Aufgabe; als Antwort zählt sie
  /// bei der ersten Teilaufgabe – sonst bliebe eine Aufgabe, die man ganz in
  /// den Betriebsabrechnungsbogen schreibt, unbearbeitet.
  bool _hatAntwort(Question q) {
    final s = AnswerStore.instance;
    if (s.get(q.id).trim().isNotEmpty || s.hatCalc(q.id) || s.hatSkizze(q.id)) return true;
    for (var i = 0; i < q.tabs.length; i++) {
      if (s.tabGefuellt('${q.id}#s$i')) return true;
    }
    final teile = _teile(q.nr);
    if (teile.isEmpty || teile.first.id != q.id) return false;
    final auf = widget.fall.aufgabeVon(q.nr);
    for (var i = 0; i < (auf?.tabs.length ?? 0); i++) {
      if (s.tabGefuellt(_tabKey(q.nr, i))) return true;
    }
    return false;
  }

  /// Neu gezeichnet wird nur, wenn sich der Stand der Teilaufgabe ändert.
  void _standPruefen(Question q) {
    final hat = _hatAntwort(q);
    if (hat == _bearbeitet.contains(q.id)) return;
    setState(() {
      if (hat) {
        _bearbeitet.add(q.id);
      } else {
        _bearbeitet.remove(q.id);
      }
    });
  }

  TextEditingController _controller(Question q) =>
      _ctrl.putIfAbsent(q.id, () => TextEditingController(text: AnswerStore.instance.get(q.id)));

  FocusNode _knoten(Question q) => _fokus.putIfAbsent(q.id, () {
        final n = FocusNode();
        n.addListener(() {
          if (!n.hasFocus) return;
          _ziel = q.id;
          _feldAktiv(AktivesFeld(_controller(q), () => _antwort(q, _controller(q).text), teilId: q.id));
        });
        return n;
      });

  void _antwort(Question q, String text) {
    AnswerStore.instance.set(q.id, text);
    _ziel = q.id;
    _standPruefen(q);
  }

  void _aenderung(Question q) {
    _ziel = q.id;
    _standPruefen(q);
  }

  void _wechsle(int nr) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _nr = nr;
      if (!_ctxBeruehrt) _ctxOffen = false;
      _feldAktiv(null);
      _rwFokus = null;
    });
    LetztePruefung.instance.merken(widget.fall.id, nr);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pilleZeigen());
  }

  /// Die aktuelle Aufgabe in der Leiste sichtbar halten (viele Aufgaben).
  void _pilleZeigen() {
    final c = _pillen[_nr]?.currentContext;
    if (c != null) Scrollable.ensureVisible(c, alignment: 0.5, duration: const Duration(milliseconds: 200));
  }

  void _zeige(String id, {bool weich = false}) {
    final c = _karten[id]?.currentContext;
    if (c != null) {
      Scrollable.ensureVisible(c, alignment: 0.5, duration: weich ? const Duration(milliseconds: 300) : Duration.zero);
    }
  }

  void _aufdecken(Question q) => setState(() => _aufgedeckt.add(q.id));

  /// Selbstbewertung: zählt fürs Ergebnis und für den Lernfortschritt.
  void _bewerten(Question q, int punkte) {
    AnswerStore.instance.setPoints(q.id, punkte);
    _merken(q, punkte * 2 >= q.maxPoints);
  }

  void _merken(Question q, bool korrekt) {
    final i = _pool.indexOf(q);
    if (i < 0) return;
    setState(() {
      _results[i] = korrekt;
      if (!korrekt && !_wrong.contains(q)) _wrong.add(q);
    });
    ProgressService.instance.record(q.id, korrekt);
  }

  void _zumErgebnis() {
    final e = _echt;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        mode: RoundMode.cases,
        pool: _pool,
        results: _results,
        wrong: _wrong,
        fall: widget.fall,
        echt: (e != null && e.abgegeben) ? e : null,
      ),
    ));
  }

  // ─────────────── Prüfung unter Echtbedingungen (FR-007) ───────────────

  void _abgeben({bool zeitUm = false}) {
    if (!_laeuft) return;
    Echtbedingungen.instance.abgeben(widget.fall.id, zeitUm: zeitUm);
    setState(() => _aufgedeckt.addAll(_pool.map((q) => q.id)));
    if (_nummern.isNotEmpty) _wechsle(_nummern.first);
  }

  Future<void> _abgebenFragen() async {
    final leer = _pool.where((q) => !_hatAntwort(q)).length;
    final ok = await nachfragen(
      context,
      titel: 'Jetzt abgeben?',
      text: '${leer > 0 ? '$leer Teilaufgabe${leer == 1 ? ' ist' : 'n sind'} noch leer.\n\n' : ''}'
          'Danach siehst du die Lösungen und bewertest dich selbst.',
      ja: 'Abgeben',
    );
    if (ok && mounted) _abgeben();
  }

  Future<bool> _verlassenErlaubt() async {
    if (!_laeuft) return true;
    return nachfragen(
      context,
      titel: 'Prüfung verlassen?',
      text: 'Die Uhr läuft weiter – wie in der echten Prüfung. Über die Prüfungsliste geht es weiter.',
      ja: 'Verlassen',
    );
  }

  Future<void> _verlassen() async {
    if (await _verlassenErlaubt() && mounted) Navigator.of(context).pop();
  }

  // ─────────────── Werkzeug-Dock: Übernehmen (FR-002 C, FR-005 D) ───────────────

  /// Ziel für eine Vorlage aus dem Formelbuch: die zuletzt angetippte
  /// Teilaufgabe der aufgeschlagenen Aufgabe, sonst die erste noch nicht
  /// aufgedeckte.
  Question? _antwortZiel() {
    final teile = _teile(_nr).where((q) => !_aufgedeckt.contains(q.id)).toList();
    if (teile.isEmpty) return null;
    for (final q in teile) {
      if (q.id == _ziel) return q;
    }
    return teile.first;
  }

  /// Zuletzt benutztes Eingabefeld – Ziel für „Übernehmen“ aus dem Rechner
  /// (FR-005 D). [AktivesFeld.ziel] ist die Beschriftung des Rechner-Knopfs
  /// („Rechnung in den Rechenweg · Z2“), [AktivesFeld.leereRechnung] sagt,
  /// ob dort die ganze Rechnung hingehört.
  void _feldAktiv(AktivesFeld? f) {
    _aktiv = f;
    rechnerZiel.value = f?.ziel;
  }

  String _bezug(Question q) => 'Aufgabe ${q.nr} ${q.teil})';

  /// Übernehmen aus Rechner und Formelbuch (FR-002 C, FR-005 D): Eine
  /// mehrzeilige Vorlage aus dem Formelbuch kommt an die Antwort der
  /// Teilaufgabe (Web `blAntwortAnhaengen`), ein Wert aus dem Rechner an die
  /// Schreibmarke des zuletzt benutzten Felds. Gibt die Teilaufgabe zurück
  /// („Aufgabe 1 a)“), damit der Hinweis sie nennt – `null` ohne Ziel, dann
  /// geht der Text in die Zwischenablage.
  String? _uebernehmen(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final vorlage = t.contains('\n');
    final a = _aktiv;
    final gueltig = a != null &&
        (a.teilId == null || (!_aufgedeckt.contains(a.teilId) && _teile(_nr).any((q) => q.id == a.teilId)));
    if (!vorlage && gueltig) {
      // In eine leere Rechenweg-Zeile gehört die ganze Rechnung, damit der
      // Rechenweg sie nachrechnet (Web `rkUebernehmen`).
      final rechnung = a.leereRechnung ? RechnerModell.instance.rechnungText : '';
      a.einsetzen(rechnung.isNotEmpty ? rechnung : t);
      final q = _pool.where((x) => x.id == a.teilId);
      return q.isEmpty ? 'Aufgabe $_nr' : _bezug(q.first);
    }
    final q = _antwortZiel();
    if (q == null) return null;
    final c = _controller(q);
    final alt = c.text.replaceFirst(RegExp(r'\s+$'), '');
    final neu = alt.isEmpty ? t : (vorlage ? '$alt\n\n$t' : '$alt $t');
    c.value = TextEditingValue(text: neu, selection: TextSelection.collapsed(offset: neu.length));
    _antwort(q, neu);
    aufleuchten(c);
    return _bezug(q);
  }

  // ─────────────────────────── Aufbau ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final auf = _aufgabe;
    final teile = _teile(_nr);
    final tastatur = MediaQuery.viewInsetsOf(context).bottom > 0;
    final breite = MediaQuery.sizeOf(context).width;
    final rand = breite <= 520 ? 12.0 : 16.0;
    return PopScope(
      canPop: !_laeuft,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _verlassenErlaubt() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _leiste(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(rand, 14, rand, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _kopf(auf, teile),
                      if (widget.fall.hinweis.isNotEmpty) _hinweis(widget.fall.hinweis),
                      if (_echt != null) _echtBand(_echt!),
                      if (_hatAusgangssituation) _ausgangssituation(),
                      if ((auf?.sit ?? '').isNotEmpty) _ausgangslage(auf!.sit, breite),
                      if (auf != null) ..._anlagen(auf),
                      for (final q in teile) _teilKarte(q),
                      _fuss(teile, breite),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
        // Beim Schreiben räumt das Dock den Platz über der Tastatur (FR-003 C.9).
        bottomNavigationBar: tastatur ? null : WerkzeugDock(onUebernehmen: _uebernehmen),
      ),
    );
  }

  /// Die allgemeine Ausgangssituation der Basisqualifikationen sagt nur, dass
  /// jede Aufgabe ihre eigene hat – sie wird nicht als Karte gezeigt.
  bool get _hatAusgangssituation =>
      widget.fall.context.isNotEmpty &&
      !widget.fall.context.startsWith('In dieser Prüfung hat jede Aufgabe ihre eigene Ausgangssituation');

  Widget _leiste() {
    final e = _echt;
    final n = _pool.length;
    var auf = 0, bea = 0, pkt = 0, bew = 0;
    for (final q in _pool) {
      if (_aufgedeckt.contains(q.id)) {
        auf++;
      } else if (_bearbeitet.contains(q.id)) {
        bea++;
      }
      final p = AnswerStore.instance.points(q.id);
      if (p != null) {
        pkt += p;
        bew++;
      }
    }
    final zahl = monoStyle(11, color: kMuted, weight: FontWeight.w600, spacing: 0);
    final fett = TextStyle(color: kInk, fontWeight: FontWeight.w700);
    return Container(
      decoration: BoxDecoration(
        color: kPaper,
        border: Border(bottom: BorderSide(color: kLine)),
        boxShadow: [BoxShadow(color: const Color(0xFF102A32).withValues(alpha: 0.12), blurRadius: 16, spreadRadius: -12, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 5),
          child: Row(children: [
            IconButton(
              tooltip: 'Prüfung verlassen',
              onPressed: _verlassen,
              icon: Icon(Icons.close, color: kInkSoft),
            ),
            Expanded(
              child: _nummern.length < 2
                  ? const SizedBox(height: 42)
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                      child: Row(children: [
                        for (var i = 0; i < _nummern.length; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          _pille(_nummern[i]),
                        ],
                      ]),
                    ),
            ),
            if (e != null) ...[
              const SizedBox(width: 8),
              _Uhr(lauf: e, onAblauf: () => _abgeben(zeitUm: true)),
            ],
            if (e != null && !e.abgegeben) ...[
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _abgebenFragen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: const Text('Abgeben'),
              ),
            ],
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 9),
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: ColoredBox(
                    color: kTrack,
                    child: Row(children: [
                      if (auf > 0) Expanded(flex: auf, child: ColoredBox(color: kPetrol)),
                      if (bea > 0) Expanded(flex: bea, child: ColoredBox(color: kOk)),
                      if (n - auf - bea > 0) Spacer(flex: n - auf - bea),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(style: zahl, children: [
                TextSpan(text: '${auf + bea}', style: fett),
                TextSpan(text: '/$n Teile'),
                if (bew > 0) ...[const TextSpan(text: ' · '), TextSpan(text: '$pkt', style: fett), const TextSpan(text: ' P')],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _pille(int nr) {
    final teile = _teile(nr);
    final auf = widget.fall.aufgabeVon(nr);
    final beantwortet = teile.where((q) => _bearbeitet.contains(q.id)).length;
    final offen = teile.where((q) => _aufgedeckt.contains(q.id)).length;
    final cur = nr == _nr;
    String stand = 'noch offen';
    Color? punkt;
    var grund = kPaper, rand = kLineStrong, schrift = kInkSoft, klein = kMuted;
    if (offen == teile.length && teile.isNotEmpty) {
      stand = 'Lösungen aufgedeckt';
      punkt = kPetrol;
      grund = kPetrolSoft;
      rand = kPetrolLine;
      schrift = kPetrolInkDeep;
    } else if (beantwortet == teile.length && teile.isNotEmpty) {
      stand = 'alle Teile bearbeitet';
      punkt = kOk;
    } else if (beantwortet > 0 || offen > 0) {
      stand = '${beantwortet > offen ? beantwortet : offen} von ${teile.length} Teilen bearbeitet';
      punkt = kAmber;
    }
    if (cur) {
      grund = kPetrol;
      rand = kPetrol;
      schrift = Colors.white;
      klein = Colors.white.withValues(alpha: 0.82);
    }
    final pts = auf?.pts ?? 0;
    return Semantics(
      key: _pillen.putIfAbsent(nr, GlobalKey.new),
      button: true,
      selected: cur,
      label: 'Aufgabe $nr${pts > 0 ? ', $pts Punkte' : ''}, $stand',
      excludeSemantics: true,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: cur
                ? [BoxShadow(color: kPetrol.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: -2, offset: const Offset(0, 4))]
                : null,
          ),
          child: Material(
            color: grund,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: BorderSide(color: rand)),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: () => _wechsle(nr),
              child: Container(
                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$nr', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1, color: schrift)),
                  if (pts > 0) ...[
                    const SizedBox(height: 3),
                    Text('$pts P',
                        style: monoStyle(9, color: klein, weight: FontWeight.w600, spacing: 0).copyWith(height: 1)),
                  ],
                ]),
              ),
            ),
          ),
        ),
        if (punkt != null)
          Positioned(
            top: 4,
            right: 4,
            child: IgnorePointer(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: punkt,
                  shape: BoxShape.circle,
                  border: cur ? Border.all(color: Colors.white, width: 1.5) : null,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _kopf(Aufgabe? auf, List<Question> teile) {
    final f = widget.fall;
    final datum = RegExp(r'–\s*([^–]+)$').firstMatch(f.title)?.group(1)?.trim() ?? f.termin;
    final fach = f.sub.replaceFirst(RegExp(r'^IHK-Prüfung:\s*'), '');
    final eyebrow = _pruef ? '$fach${datum.isNotEmpty ? ' · $datum' : ''}' : 'Fallaufgabe · $fach';
    final titel = (_pruef || _nummern.length > 1) ? 'Aufgabe $_nr' : (f.title.isEmpty ? 'Fallaufgabe' : f.title);
    final n = teile.length;
    final bea = teile.where((q) => _bearbeitet.contains(q.id) || _aufgedeckt.contains(q.id)).length;
    final bewertet = teile.where((q) => AnswerStore.instance.points(q.id) != null).toList();
    final w = MediaQuery.sizeOf(context).width;

    Widget chip(String t, {Color? grund, Color? randF, Color? schrift}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: grund ?? kSurface2,
            border: Border.all(color: randF ?? kLine),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.2, color: schrift ?? kInkSoft)),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(), style: monoStyle(10.5, color: kPetrolInk, spacing: 1.2).copyWith(height: 1.4)),
        const SizedBox(height: 6),
        Text(titel.toUpperCase(), style: dispStyle((w * 0.074).clamp(30.0, 40.0), height: 0.95)),
        const SizedBox(height: 11),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if ((auf?.pts ?? 0) > 0) chip('${auf!.pts} Punkte', grund: kPetrolSoft, randF: kPetrolLine, schrift: kPetrolInkDeep),
          chip('$n Teilaufgabe${n == 1 ? '' : 'n'}'),
          if (bea == n && n > 0)
            chip('✓ $bea von $n bearbeitet', grund: kOkSoft, randF: kOkLine, schrift: kOkInk)
          else
            chip('$bea von $n bearbeitet'),
          if (bewertet.isNotEmpty)
            chip(
              'Deine Punkte: ${bewertet.fold<int>(0, (s, q) => s + (AnswerStore.instance.points(q.id) ?? 0))} / '
              '${(auf?.pts ?? 0) > 0 ? auf!.pts : teile.fold<int>(0, (s, q) => s + q.maxPoints)}',
              grund: kGoldSoft,
              randF: kGoldLine,
              schrift: kGoldInk,
            ),
        ]),
      ]),
    );
  }

  Widget _hinweis(String text) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          color: kAmberSoft,
          border: Border(left: BorderSide(color: kAmber, width: 3)),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
        ),
        child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.5, color: kInkSoft)),
      );

  Widget _echtBand(EchtLauf e) {
    final fertig = e.abgegeben;
    final fett = TextStyle(fontWeight: FontWeight.w700, color: kPetrolInkDeep);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: fertig ? kOkSoft : kPetrolSoft,
        border: Border.all(color: fertig ? kOkLine : kPetrolLine),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.timer_outlined, size: 18, color: kPetrolInk),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(style: TextStyle(fontSize: 13, height: 1.5, color: kInk), children: [
              if (fertig) ...[
                if (e.zeitUm) ...[
                  TextSpan(text: 'Zeit abgelaufen', style: fett),
                  const TextSpan(text: ' – deine Antworten sind abgegeben. '),
                ] else ...[
                  TextSpan(text: 'Abgegeben', style: fett),
                  TextSpan(text: ' nach ${dauerText(e.dauer)}. '),
                ],
                const TextSpan(
                    text: 'Sieh dir jetzt die Lösungen an und vergib dir je Teilaufgabe Punkte. Danach „Zum Ergebnis“ '
                        '– mit Note und Bearbeitungszeit.'),
              ] else ...[
                TextSpan(text: 'Unter Prüfungsbedingungen:', style: fett),
                TextSpan(
                    text: ' ${dauerText(e.min * 60000)} Bearbeitungszeit, Lösungen erst nach der Abgabe. '
                        'Die Uhr läuft weiter, auch wenn du die Prüfung verlässt.'),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  /// Ausgangssituation der ganzen Prüfung – einmal lesen, dann zu.
  Widget _ausgangssituation() {
    final f = widget.fall;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: _ctxOffen,
          child: InkWell(
            onTap: () => setState(() {
              _ctxOffen = !_ctxOffen;
              _ctxBeruehrt = true;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
              child: LayoutBuilder(builder: (context, c) {
                final tag = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: kPetrol, borderRadius: BorderRadius.circular(4)),
                  child: Text(_pruef ? 'AUSGANGSSITUATION' : 'FALL',
                      style: monoStyle(10, color: Colors.white, weight: FontWeight.w600, spacing: 0.8)),
                );
                final titel = Text((_pruef ? 'Gilt für alle Aufgaben dieser Prüfung' : f.title).toUpperCase(),
                    style: dispStyle(14, height: 1.15));
                final mehr = Container(
                  padding: const EdgeInsets.fromLTRB(10, 3, 6, 3),
                  decoration: BoxDecoration(
                    color: kPaper,
                    border: Border.all(color: kPetrolLine),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_pruef ? 'LESEN' : 'AUSGANGSLAGE',
                        style: monoStyle(10, color: kPetrolInk, weight: FontWeight.w600, spacing: 0.6)),
                    Icon(_ctxOffen ? Icons.expand_less : Icons.expand_more, size: 16, color: kPetrolInk),
                  ]),
                );
                // Schmal: der Titel rutscht unter das Etikett (Web `flex-wrap`).
                if (c.maxWidth < 420) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    tag,
                    const SizedBox(height: 7),
                    Row(children: [Expanded(child: titel), const SizedBox(width: 9), mehr]),
                  ]);
                }
                return Row(children: [
                  tag,
                  const SizedBox(width: 9),
                  Expanded(child: titel),
                  const SizedBox(width: 9),
                  mehr,
                ]);
              }),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _ctxOffen
              ? Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: kLine))),
                  padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                  child: PruefText(f.context, stil: TextStyle(fontSize: 14, height: 1.55, color: kInk)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }

  Widget _ausgangslage(String sit, double breite) {
    final handy = breite <= 520;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.fromLTRB(handy ? 12 : 15, 13, handy ? 12 : 15, handy ? 13 : 15),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('AUSGANGSLAGE', style: monoStyle(10, color: kMuted, spacing: 1.2)),
        const SizedBox(height: 10),
        PruefText(sit, stil: TextStyle(fontSize: handy ? 14 : 14.5, height: 1.62, color: kInk)),
      ]),
    );
  }

  /// Anlagen der ganzen Aufgabe: Tabellen zum Ausfüllen und Abbildungen.
  List<Widget> _anlagen(Aufgabe auf) {
    final teile = _teile(auf.nr);
    final erste = teile.isEmpty ? null : teile.first;
    return [
      for (var i = 0; i < auf.tabs.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AnlageTabelle(
            auf.tabs[i],
            key: ValueKey('${_tabKey(auf.nr, i)}-${_tabLoesung(auf.nr, auf.tabs[i]) != null}'),
            speicherKey: _tabKey(auf.nr, i),
            loesung: _tabLoesung(auf.nr, auf.tabs[i]),
            onEingabe: () {
              if (erste != null) _aenderung(erste);
            },
            onFokus: (f) => _feldAktiv(f.fuer(erste?.id)),
          ),
        ),
      if (auf.bild != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: AnlageBild(auf.bild)),
    ];
  }

  /// Zwischenergebnis einer früheren Teilaufgabe – nur wenn sie aufgedeckt ist.
  /// So schleppt sich ein Fehler aus a) nicht durch die ganze Aufgabe.
  String? _vorher(Question q) {
    if (q.braucht.isEmpty) return null;
    final teile = _teile(q.nr);
    final stuecke = <String>[];
    for (final lab in q.braucht) {
      final v = teile.where((x) => x.teil == lab);
      if (v.isEmpty || !_aufgedeckt.contains(v.first.id)) continue;
      final zeilen = (v.first.a ?? '').split('\n').where((z) => z.trim().isNotEmpty).take(2).join('\n');
      if (zeilen.isNotEmpty) stuecke.add('Zwischenergebnis aus $lab)\n$zeilen');
    }
    return stuecke.isEmpty ? null : stuecke.join('\n\n');
  }

  Widget _teilKarte(Question q) {
    final rw = istRechenteil(q) || AnswerStore.instance.calc(q.id).isNotEmpty || _rwOffen.contains(q.id);
    final sk = skZeichenteil(q.q) || AnswerStore.instance.hatSkizze(q.id) || _skOffen.contains(q.id);
    return KeyedSubtree(
      key: _karten.putIfAbsent(q.id, GlobalKey.new),
      child: TeilKarte(
        key: ValueKey('teil-${q.id}'),
        frage: q,
        aufgedeckt: _aufgedeckt.contains(q.id),
        bearbeitet: _bearbeitet.contains(q.id),
        ergebnis: _results[_pool.indexOf(q)],
        vorher: _vorher(q),
        echtLaeuft: _laeuft,
        rechenweg: rw,
        skizze: sk,
        rechenwegFokus: _rwFokus == q.id,
        controller: _controller(q),
        fokus: _knoten(q),
        anlageRef: _skizzenAnlage(q),
        bezug: _bezug(q),
        onAntwort: (t) => _antwort(q, t),
        onAenderung: () => _aenderung(q),
        onAufdecken: () => _aufdecken(q),
        onPunkte: (p) => _bewerten(q, p),
        onGewusst: (ok) => _merken(q, ok),
        onRechenweg: () => setState(() {
          _rwOffen.add(q.id);
          _rwFokus = q.id;
        }),
        onSkizze: () => setState(() => _skOffen.add(q.id)),
        onBraucht: (lab) {
          final ziel = _teile(q.nr).where((x) => x.teil == lab);
          if (ziel.isNotEmpty) _zeige(ziel.first.id, weich: true);
        },
        onFokus: (f) {
          _ziel = q.id;
          _feldAktiv(f.teilId == null ? f.fuer(q.id) : f);
        },
      ),
    );
  }

  /// Bild-Anlage für „Auf der Anlage“ – nur, wenn es sie als Bild gibt.
  String? _skizzenAnlage(Question q) {
    final ref = q.bildEffektiv;
    return DataService.instance.anlage(ref) == null ? null : ref;
  }

  Widget _fuss(List<Question> teile, double breite) {
    final alleOffen = teile.every((q) => _aufgedeckt.contains(q.id));
    final letzte = _pos >= _nummern.length - 1;
    final laeuft = _laeuft;
    final handy = breite <= 520;
    final stil = OutlinedButton.styleFrom(
      foregroundColor: kPetrolInk,
      side: BorderSide(color: kLineStrong),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700),
    );
    final neben = <Widget>[
      if (_pos > 0)
        OutlinedButton(onPressed: () => _wechsle(_nummern[_pos - 1]), style: stil, child: Text('← Aufgabe ${_nummern[_pos - 1]}')),
      // Unter Prüfungsbedingungen gibt es vor der Abgabe nichts aufzudecken.
      if (!laeuft)
        alleOffen
            ? OutlinedButton(onPressed: () => _kopieren(teile), style: stil, child: const Text('Von einer KI prüfen lassen'))
            : OutlinedButton(
                onPressed: () => setState(() => _aufgedeckt.addAll(teile.map((q) => q.id))),
                style: stil,
                child: const Text('Alle Lösungen aufdecken'),
              ),
    ];
    final haupt = FilledButton(
      onPressed: () {
        if (letzte) {
          laeuft ? _abgebenFragen() : _zumErgebnis();
        } else {
          _wechsle(_nummern[_pos + 1]);
        }
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
      child: Text(letzte ? (laeuft ? 'Abgeben' : 'Zum Ergebnis →') : 'Aufgabe ${_nummern[_pos + 1]} →'),
    );
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 15),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: kLine))),
      child: handy
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (neben.isNotEmpty) ...[
                Wrap(spacing: 9, runSpacing: 9, children: neben),
                const SizedBox(height: 9),
              ],
              haupt,
            ])
          : Row(children: [
              for (final b in neben) ...[b, const SizedBox(width: 9)],
              const Spacer(),
              haupt,
            ]),
    );
  }

  /// Die ganze Aufgabe als Prüfauftrag – mit allen Teilen, damit die KI den
  /// Zusammenhang sieht, auf den die Teilaufgaben aufbauen (Web `blExport`).
  Future<void> _kopieren(List<Question> teile) async {
    final f = widget.fall;
    final auf = _aufgabe;
    final amtlich = teile.any((q) => q.amtlich);
    final l = <String>[
      'PRÜFAUFTRAG – Aufgabe $_nr einer Original-IHK-Prüfung',
      '',
      'Unten stehen eine vollständige Prüfungsaufgabe mit allen Teilaufgaben, MEINE eigenen Antworten und '
          '${amtlich ? 'die AMTLICHEN Lösungshinweise der IHK.' : 'Musterlösungen, die NICHT von der IHK stammen.'}',
      '',
      'Bewerte je Teilaufgabe MEINE Antwort:',
      '1. Wie viele der jeweils möglichen Punkte würdest du vergeben? Begründe kurz.',
      '2. Was fehlt zur vollen Punktzahl? Nenne die fehlenden Elemente konkret.',
      '3. Welche fachlichen Fehler enthält meine Antwort (falsche Aussage, falsche Rechnung, veraltete Rechtsgrundlage)?',
      'Bei Rechenaufgaben: rechne eigenständig nach und zeige deinen Rechenweg.',
      '',
      '==============================',
      f.title,
      '==============================',
      '',
    ];
    if (f.context.isNotEmpty) l.addAll(['AUSGANGSSITUATION', f.context, '']);
    l.add('AUFGABE $_nr${(auf?.pts ?? 0) > 0 ? ' · ${auf!.pts} Punkte' : ''}');
    if ((auf?.sit ?? '').isNotEmpty) l.addAll(['', auf!.sit]);
    if (auf != null && auf.tabs.isNotEmpty) l.addAll(['', auf.tabs.map((t) => t.asText()).join('\n\n')]);
    for (var i = 0; i < (auf?.tabs.length ?? 0); i++) {
      final t = auf!.tabs[i];
      final w = AnswerStore.instance.tabWerte(_tabKey(auf.nr, i));
      if (w.isEmpty) continue;
      l.addAll(['', 'Eigene Eintragungen in „${t.titel.isEmpty ? 'Anlage' : t.titel}“:']);
      for (final rc in w.keys.toList()..sort()) {
        final p = rc.split('-');
        final ri = int.tryParse(p.first) ?? 0, ci = int.tryParse(p.last) ?? 0;
        final zeile = ri < t.zeilen.length ? t.zeilen[ri] : const <String>[];
        final z = zeile.isNotEmpty && zeile.first.isNotEmpty ? zeile.first : 'Zeile ${ri + 1}';
        final k = ci < t.kopf.length && t.kopf[ci].isNotEmpty ? t.kopf[ci] : 'Spalte ${ci + 1}';
        l.add('– $z / $k: ${w[rc]}');
      }
    }
    final ab = DataService.instance.anlage(auf?.bild);
    if (ab != null) l.addAll(['', '[Zur Aufgabe gehört eine Abbildung: ${ab.titel.isNotEmpty ? ab.titel : 'Anlage zur Aufgabe'}]']);
    l.add('');
    for (final q in teile) {
      l.addAll(['------------------------------', '${q.teil}) · ${q.pts} ${q.pts == 1 ? 'Punkt' : 'Punkte'}', '', q.q]);
      if (q.tabs.isNotEmpty) l.addAll(['', q.tabs.map((t) => t.asText()).join('\n\n')]);
      final b = DataService.instance.anlage(q.bild);
      if (b != null) l.addAll(['', '[Zur Teilaufgabe gehört eine Abbildung: ${b.titel.isNotEmpty ? b.titel : 'Anlage'}]']);
      final eigene = AnswerStore.instance.antwortText(q.id);
      l.addAll([
        '',
        'MEINE ANTWORT:',
        eigene.isEmpty ? '— leer abgegeben —' : eigene,
        '',
        q.amtlich ? 'AMTLICHER LÖSUNGSHINWEIS (IHK):' : 'MUSTERLÖSUNG (zu prüfen):',
        q.a ?? q.e,
      ]);
      if ((q.vo ?? '').isNotEmpty) l.add('VO-Bezug: ${q.vo}');
      if (q.bewertung.isNotEmpty) l.add('Punkteverteilung: ${q.bewertung.join(' + ')} Punkte');
      l.add('');
    }
    l.addAll(['==============================', 'Nenne abschließend die Gesamtpunktzahl, die du für Aufgabe $_nr vergeben würdest.']);

    await Clipboard.setData(ClipboardData(text: l.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aufgabe mit deinen Antworten kopiert – jetzt in eine KI einfügen.')));
  }
}

/// Uhr unter Prüfungsbedingungen: Restzeit „1:29:45“, ab 10 Minuten rot; nach
/// der Abgabe die Bearbeitungszeit („1 h 12 min“).
class _Uhr extends StatefulWidget {
  final EchtLauf lauf;
  final VoidCallback onAblauf;
  const _Uhr({required this.lauf, required this.onAblauf});

  @override
  State<_Uhr> createState() => _UhrState();
}

class _UhrState extends State<_Uhr> {
  Timer? _takt;

  @override
  void initState() {
    super.initState();
    _starten();
  }

  @override
  void didUpdateWidget(covariant _Uhr alt) {
    super.didUpdateWidget(alt);
    if (alt.lauf.abgegeben != widget.lauf.abgegeben || alt.lauf.start != widget.lauf.start) _starten();
  }

  void _starten() {
    _takt?.cancel();
    if (widget.lauf.abgegeben) return;
    _takt = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.lauf.rest() <= 0) {
        _takt?.cancel();
        widget.onAblauf();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _takt?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.lauf;
    final rest = e.rest();
    final knapp = !e.abgegeben && rest <= 10 * 60000;
    return Semantics(
      label: e.abgegeben ? 'Bearbeitungszeit' : 'Verbleibende Zeit',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: knapp ? kErrSoft : kPetrolSoft,
          border: Border.all(color: knapp ? kErrLine : kPetrolLine),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(e.abgegeben ? dauerText(e.dauer) : uhrText(rest),
            style: monoStyle(13, color: knapp ? kErrInk : kPetrolInkDeep, weight: FontWeight.w600, spacing: 0)),
      ),
    );
  }
}
