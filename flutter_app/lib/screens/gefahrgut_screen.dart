import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import '../werkzeuge/adr_daten.dart';
import '../werkzeuge/gefahrzettel.dart';

/// Gefahrgut-Symbole (ADR) – wie im Web (`#mADR`): Übersicht der
/// Gefahrzettel, Quiz und Warntafel-Decoder.
class GefahrgutScreen extends StatelessWidget {
  /// Zufall fürs Quiz (Tests); sonst ein neuer.
  final math.Random? zufall;

  /// Reiter beim Öffnen: 0 Übersicht, 1 Quiz, 2 Warntafel.
  final int reiter;
  const GefahrgutScreen({super.key, this.zufall, this.reiter = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: reiter,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPaper,
          title: Text('Gefahrgut-Symbole (ADR)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
          bottom: TabBar(
            labelColor: kPetrolInk,
            unselectedLabelColor: kMuted,
            indicatorColor: kPetrol,
            indicatorWeight: 2.5,
            dividerColor: kLine,
            labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 13.5),
            tabs: const [Tab(text: 'Übersicht'), Tab(text: 'Quiz'), Tab(text: 'Warntafel')],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(children: [
            const _Uebersicht(),
            _AdrQuiz(zufall: zufall),
            const _WarntafelReiter(),
          ]),
        ),
      ),
    );
  }
}

/// Text mit fetten Stellen in Petrol (Web `.adr-decoded b`).
Text _mitFett(List<TextTeil> teile, TextStyle stil) => Text.rich(
      TextSpan(children: [
        for (final t in teile)
          TextSpan(
            text: t.text,
            style: t.fett ? TextStyle(fontWeight: FontWeight.w700, color: kPetrolInk) : null,
          ),
      ]),
      style: stil,
    );

// ─────────────────────────── Übersicht ───────────────────────────

class _Uebersicht extends StatelessWidget {
  const _Uebersicht();

  Widget _karte(AdrKlasse k) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: kLine),
      ),
      child: Column(children: [
        Gefahrzettel(k),
        const SizedBox(height: 6),
        Text('Klasse ${k.klasse}',
            style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolInk)),
        const SizedBox(height: 2),
        Text(k.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: kInk)),
        const SizedBox(height: 3),
        Text(k.beispiele, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.35, color: kMuted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const abstand = 12.0;
      final breite = box.maxWidth - 32;
      // Wie `repeat(auto-fill, minmax(150px, 1fr))`: so viele Spalten, wie 150 breit passen.
      final spalten = math.max(2, ((breite + abstand) / (150 + abstand)).floor());
      final reihen = <Widget>[];
      for (var i = 0; i < kAdrKlassen.length; i += spalten) {
        final zeile = <Widget>[];
        for (var j = 0; j < spalten; j++) {
          if (j > 0) zeile.add(const SizedBox(width: abstand));
          zeile.add(Expanded(
              child: i + j < kAdrKlassen.length ? _karte(kAdrKlassen[i + j]) : const SizedBox.shrink()));
        }
        reihen
          ..add(IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: zeile)))
          ..add(const SizedBox(height: abstand));
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ...reihen,
          Text(
            'Der Gefahrzettel (Placard, mind. 25 × 25 cm am Fahrzeug) zeigt die Gefahrgutklasse über '
            'Farbe, Symbol und Klassenzahl (unten). Bei Klasse 2 steht unten die „2“, die konkrete '
            'Untergruppe (2.1/2.2/2.3) ergibt sich aus Farbe und Symbol.',
            style: TextStyle(fontSize: 12, height: 1.5, color: kMuted),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────── Quiz ───────────────────────────

class _AdrQuiz extends StatefulWidget {
  final math.Random? zufall;
  const _AdrQuiz({this.zufall});

  @override
  State<_AdrQuiz> createState() => _AdrQuizState();
}

class _AdrQuizState extends State<_AdrQuiz> with AutomaticKeepAliveClientMixin {
  late final math.Random _zufall = widget.zufall ?? math.Random();
  int _richtig = 0;
  int _gesamt = 0;
  late AdrKlasse _frage;
  late List<AdrKlasse> _optionen;
  AdrKlasse? _gewaehlt;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _naechste();
  }

  /// Neue Frage (Web `nextQuiz`): ein Zettel, dazu drei andere Klassen.
  void _naechste() {
    _frage = kAdrKlassen[_zufall.nextInt(kAdrKlassen.length)];
    final andere = kAdrKlassen.where((k) => k.name != _frage.name).toList()..shuffle(_zufall);
    final optionen = [_frage];
    for (final k in andere) {
      if (optionen.length >= 4) break;
      if (optionen.every((o) => o.name != k.name)) optionen.add(k);
    }
    _optionen = optionen..shuffle(_zufall);
    _gewaehlt = null;
  }

  void _antworten(AdrKlasse k) {
    if (_gewaehlt != null) return;
    setState(() {
      _gewaehlt = k;
      _gesamt++;
      if (k.name == _frage.name) _richtig++;
    });
  }

  Widget _option(AdrKlasse k) {
    final beantwortet = _gewaehlt != null;
    final richtig = beantwortet && k.name == _frage.name;
    final falsch = beantwortet && identical(k, _gewaehlt) && !richtig;
    final rand = richtig ? kOk : (falsch ? kErr : kLineStrong);
    final grund = richtig ? kOkSoft : (falsch ? kErrSoft : kPaper);
    final r = BorderRadius.circular(10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Semantics(
        button: true,
        enabled: !beantwortet,
        child: Material(
          color: grund,
          shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: rand, width: 1.5)),
          child: InkWell(
            borderRadius: r,
            onTap: beantwortet ? null : () => _antworten(k),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                child: Row(children: [
                  Expanded(
                    child: Text('Klasse ${k.klasse} – ${k.name}',
                        style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: kInk)),
                  ),
                  if (richtig) Icon(Icons.check_circle, size: 20, color: kOkInk),
                  if (falsch) Icon(Icons.cancel, size: 20, color: kErrInk),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(children: [
          Expanded(
            child: Text('Welche Gefahrgutklasse zeigt dieser Gefahrzettel?',
                style: TextStyle(fontSize: 13, height: 1.4, color: kMuted)),
          ),
          const SizedBox(width: 10),
          Text('$_richtig / $_gesamt',
              style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w600, color: kPetrolInk)),
        ]),
        const SizedBox(height: 8),
        Center(child: Gefahrzettel(_frage, groesse: 130)),
        const SizedBox(height: 14),
        for (final k in _optionen) _option(k),
        if (_gewaehlt != null) ...[
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => setState(_naechste),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Nächste'),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── Warntafel ───────────────────────────

class _WarntafelReiter extends StatefulWidget {
  const _WarntafelReiter();

  @override
  State<_WarntafelReiter> createState() => _WarntafelReiterState();
}

class _WarntafelReiterState extends State<_WarntafelReiter> with AutomaticKeepAliveClientMixin {
  int _i = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final e = kAdrBeispiele[_i];
    final text = TextStyle(fontSize: 13.5, height: 1.5, color: kInk);
    final zeilen = kemlerDeuten(e.kemler);
    final tabelle = <(String, String)>[
      for (final d in const ['2', '3', '4', '5', '6', '7', '8', '9']) (d, kKemler[d]!),
      ('00 / 0', 'Auffüllziffer ohne weitere Bedeutung'),
      ('Ziffer×2', 'Verdoppelung = Verstärkung der Hauptgefahr (z. B. 33, 66)'),
      ('X…', 'Vorangestelltes X: Stoff reagiert gefährlich mit Wasser'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _mitFett(const [
          TextTeil('Die orange Warntafel kennzeichnet den Transport. Oben die '),
          TextTeil('Gefahrnummer', fett: true),
          TextTeil(' (Kemler-Zahl), unten die '),
          TextTeil('UN-Nummer', fett: true),
          TextTeil(' (4-stellige Stoffnummer).'),
        ], TextStyle(fontSize: 12, height: 1.5, color: kMuted)),
        const SizedBox(height: 10),
        Row(children: [
          Text('Beispielstoff:', style: TextStyle(fontSize: 13.5, color: kInk)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              value: _i,
              isExpanded: true,
              dropdownColor: kPaper,
              style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13.5, color: kInk),
              items: [
                for (var j = 0; j < kAdrBeispiele.length; j++)
                  DropdownMenuItem(
                    value: j,
                    child: Text('${kAdrBeispiele[j].stoff}  (${kAdrBeispiele[j].kemler} / ${kAdrBeispiele[j].un})',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (j) => setState(() => _i = j ?? 0),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Center(child: Warntafel(kemler: e.kemler, un: e.un)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kLine),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _mitFett([TextTeil(e.stoff, fett: true), TextTeil(' · UN ${e.un}')], text),
            const SizedBox(height: 6),
            _mitFett([const TextTeil('Gefahrnummer '), TextTeil(e.kemler, fett: true), const TextTeil(':')], text),
            const SizedBox(height: 4),
            for (final z in zeilen)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('•  ', style: text),
                  Expanded(child: _mitFett(z, text)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: kLine),
          columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            for (final (code, bedeutung) in tabelle)
              TableRow(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(code,
                      style: TextStyle(
                          fontFamily: 'IBMPlexMono', fontSize: 12.5, fontWeight: FontWeight.w600, color: kPetrolInk)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(bedeutung, style: TextStyle(fontSize: 12.5, height: 1.4, color: kInk)),
                ),
              ]),
          ],
        ),
      ],
    );
  }
}
