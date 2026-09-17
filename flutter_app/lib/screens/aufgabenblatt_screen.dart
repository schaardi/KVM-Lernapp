import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models.dart';
import '../services/answer_store.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../widgets/anlage_bild.dart';
import '../widgets/anlage_tabelle.dart';
import 'result_screen.dart';

/// Eine Original-IHK-Prüfung als Aufgabenblatt.
///
/// Gezeigt wird immer eine **ganze Aufgabe**: ihre Ausgangslage, ihre Anlagen
/// und alle Teilaufgaben a–x untereinander – so, wie das Blatt in der Prüfung
/// vor einem liegt. Wer a) beantwortet, sieht damit auch, was b) und c)
/// verlangen; daran hängt, wie ausführlich die Antwort ausfallen muss.
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
  /// Teilaufgaben mit einer eigenen Antwort – hält den Stepper aktuell, ohne
  /// bei jedem Tastendruck die ganze Liste neu zu bauen.
  final _beantwortet = <String>{};
  final _ctrl = <String, TextEditingController>{};
  late final List<bool?> _results;
  final _wrong = <Question>[];
  final _scroll = ScrollController();
  bool _ctxOffen = true;

  @override
  void initState() {
    super.initState();
    _pool = widget.fall.asPool();
    _results = List<bool?>.filled(_pool.length, null);
    _nummern = widget.fall.aufgaben.map((a) => a.nr).toList();
    for (final q in _pool) {
      if (AnswerStore.instance.get(q.id).trim().isNotEmpty) _beantwortet.add(q.id);
    }
    final start = (widget.startIndex >= 0 && widget.startIndex < _pool.length)
        ? _pool[widget.startIndex]
        : null;
    _nr = start?.nr ?? (_nummern.isNotEmpty ? _nummern.first : 0);
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  List<Question> _teile(int nr) => _pool.where((q) => q.nr == nr).toList();
  Aufgabe? get _aufgabe => widget.fall.aufgabeVon(_nr);
  int get _pos => _nummern.indexOf(_nr);

  TextEditingController _controller(Question q) => _ctrl.putIfAbsent(
      q.id, () => TextEditingController(text: AnswerStore.instance.get(q.id)));

  void _wechsle(int nr) {
    setState(() => _nr = nr);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _aufdecken(Question q) => setState(() => _aufgedeckt.add(q.id));

  /// Antwort sichern; neu gezeichnet wird nur, wenn sich der Zustand der
  /// Teilaufgabe ändert (leer ↔ beantwortet).
  void _antwort(Question q, String text) {
    AnswerStore.instance.set(q.id, text);
    final hat = text.trim().isNotEmpty;
    if (hat == _beantwortet.contains(q.id)) return;
    setState(() {
      if (hat) {
        _beantwortet.add(q.id);
      } else {
        _beantwortet.remove(q.id);
      }
    });
  }

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
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        mode: RoundMode.cases,
        pool: _pool,
        results: _results,
        wrong: _wrong,
      ),
    ));
  }

  // ---------------------------------------------------------------- Aufbau

  @override
  Widget build(BuildContext context) {
    final auf = _aufgabe;
    final teile = _teile(_nr);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPaper,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.fall.sub.replaceFirst('IHK-Prüfung: ', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: kInk)),
          Text(
            'Aufgabe $_nr von ${_nummern.length}'
            '${(auf?.pts ?? 0) > 0 ? ' · ${auf!.pts} Punkte' : ''}',
            style: const TextStyle(fontSize: 11.5, color: kMuted),
          ),
        ]),
      ),
      body: SafeArea(
        child: Column(children: [
          _stepper(),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (widget.fall.hinweis.isNotEmpty) _hinweis(),
                if (widget.fall.context.isNotEmpty) _ausgangslage(),
                _aufgabenkopf(auf, teile.length),
                for (final q in teile) _TeilKarte(
                  key: ValueKey(q.id),
                  frage: q,
                  controller: _controller(q),
                  aufgedeckt: _aufgedeckt.contains(q.id),
                  ergebnis: _results[_pool.indexOf(q)],
                  vorher: _vorher(q),
                  beantwortet: _beantwortet.contains(q.id),
                  onAntwort: (t) => _antwort(q, t),
                  onAufdecken: () => _aufdecken(q),
                  onPunkte: (p) => _bewerten(q, p),
                  onGewusst: (ok) => _merken(q, ok),
                ),
                const SizedBox(height: 8),
                _fussleiste(teile),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stepper() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: kPaper,
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        for (final nr in _nummern) _pille(nr),
      ]),
    );
  }

  Widget _pille(int nr) {
    final teile = _teile(nr);
    final beantwortet = teile.where((q) => _beantwortet.contains(q.id)).length;
    final offen = teile.where((q) => _aufgedeckt.contains(q.id)).length;
    final aktiv = nr == _nr;

    Color rand = kLine, grund = kPaper, schrift = kMuted;
    if (offen == teile.length && teile.isNotEmpty) {
      rand = kPetrol;
      grund = kPetrolSoft;
      schrift = kPetrolDeep;
    } else if (beantwortet == teile.length && teile.isNotEmpty) {
      rand = const Color(0xFFB9DCC5);
      grund = const Color(0xFFE4F2E9);
      schrift = kInk;
    } else if (beantwortet > 0) {
      rand = const Color(0xFFD9C79A);
      grund = const Color(0xFFFDF8EC);
      schrift = kInk;
    }
    if (aktiv) {
      rand = kPetrol;
      grund = kPetrol;
      schrift = Colors.white;
    }

    return InkWell(
      onTap: () => _wechsle(nr),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: grund,
          border: Border.all(color: rand),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('$nr',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: schrift)),
      ),
    );
  }

  Widget _hinweis() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
        decoration: BoxDecoration(
          color: kAmber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: const Border(left: BorderSide(color: kAmber, width: 3)),
        ),
        child: Text(widget.fall.hinweis,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: kInkSoft)),
      );

  Widget _ausgangslage() => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF2F8),
            border: Border.all(color: const Color(0xFFE6C9DE)),
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: ExpansionTile(
            initiallyExpanded: _ctxOffen,
            onExpansionChanged: (v) => _ctxOffen = v,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(widget.fall.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
            subtitle: const Text('Ausgangssituation zu allen Aufgaben',
                style: TextStyle(fontSize: 11, color: kMuted)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.fall.context,
                    style: const TextStyle(fontSize: 13.5, height: 1.6, color: kInk)),
              ),
            ],
          ),
        ),
      );

  Widget _aufgabenkopf(Aufgabe? auf, int anzahlTeile) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('Aufgabe $_nr',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
        const SizedBox(width: 9),
        if ((auf?.pts ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: kPetrolSoft, borderRadius: BorderRadius.circular(6)),
            child: Text('${auf!.pts} Punkte',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: kPetrolDeep)),
          ),
        const Spacer(),
        Text('$anzahlTeile Teilaufgabe${anzahlTeile == 1 ? '' : 'n'}',
            style: const TextStyle(fontSize: 11.5, color: kMuted)),
      ]),
      if ((auf?.sit ?? '').isNotEmpty) ...[
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.only(left: 11),
          decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: kLine, width: 2))),
          child: Text(auf!.sit,
              style: const TextStyle(fontSize: 14, height: 1.65, color: kInk)),
        ),
      ],
      if (auf?.tab != null) AnlageTabelle(auf!.tab!),
      if (auf?.bild != null) AnlageBild(auf!.bild),
      const SizedBox(height: 16),
    ]);
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
      final zeilen = (v.first.a ?? '')
          .split('\n')
          .where((z) => z.trim().isNotEmpty)
          .take(2)
          .join('\n');
      if (zeilen.isNotEmpty) stuecke.add('Zwischenergebnis aus $lab)\n$zeilen');
    }
    return stuecke.isEmpty ? null : stuecke.join('\n\n');
  }

  Widget _fussleiste(List<Question> teile) {
    final alleOffen = teile.every((q) => _aufgedeckt.contains(q.id));
    final letzte = _pos >= _nummern.length - 1;
    return Column(children: [
      if (!alleOffen)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(
                () => _aufgedeckt.addAll(teile.map((q) => q.id))),
            style: OutlinedButton.styleFrom(
                foregroundColor: kPetrol,
                side: const BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('Alle Lösungen dieser Aufgabe aufdecken',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        )
      else
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _kopieren(teile),
            icon: const Icon(Icons.content_copy, size: 15),
            style: OutlinedButton.styleFrom(
                foregroundColor: kPetrol,
                side: const BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            label: const Text('Diese Aufgabe von einer KI prüfen lassen',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ),
      const SizedBox(height: 9),
      Row(children: [
        if (_pos > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => _wechsle(_nummern[_pos - 1]),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kPetrol,
                  side: const BorderSide(color: kLine),
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text('← Aufgabe ${_nummern[_pos - 1]}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ),
        if (_pos > 0) const SizedBox(width: 9),
        Expanded(
          child: FilledButton(
            onPressed: () =>
                letzte ? _zumErgebnis() : _wechsle(_nummern[_pos + 1]),
            style: FilledButton.styleFrom(
                backgroundColor: kPetrol,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            child: Text(
                letzte ? 'Zum Ergebnis →' : 'Aufgabe ${_nummern[_pos + 1]} →',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ),
      ]),
    ]);
  }

  /// Die ganze Aufgabe als Prüfauftrag – mit allen Teilen, damit die KI den
  /// Zusammenhang sieht, auf den die Teilaufgaben aufbauen.
  Future<void> _kopieren(List<Question> teile) async {
    final auf = _aufgabe;
    final amtlich = teile.any((q) => q.amtlich);
    final b = StringBuffer()
      ..writeln('PRÜFAUFTRAG – Aufgabe $_nr einer Original-IHK-Prüfung')
      ..writeln()
      ..writeln('Unten stehen eine vollständige Prüfungsaufgabe mit allen '
          'Teilaufgaben, MEINE eigenen Antworten und '
          '${amtlich ? 'die AMTLICHEN Lösungshinweise der IHK.' : 'Musterlösungen, die NICHT von der IHK stammen.'}')
      ..writeln()
      ..writeln('Bewerte je Teilaufgabe MEINE Antwort:')
      ..writeln('1. Wie viele der jeweils möglichen Punkte würdest du vergeben? '
          'Begründe kurz.')
      ..writeln('2. Was fehlt zur vollen Punktzahl? Nenne die fehlenden '
          'Elemente konkret.')
      ..writeln('3. Welche fachlichen Fehler enthält meine Antwort (falsche '
          'Aussage, falsche Rechnung, veraltete Rechtsgrundlage)?')
      ..writeln('Bei Rechenaufgaben: rechne eigenständig nach und zeige deinen '
          'Rechenweg.')
      ..writeln()
      ..writeln('==============================')
      ..writeln(widget.fall.title)
      ..writeln('==============================')
      ..writeln();
    if (widget.fall.context.isNotEmpty) {
      b
        ..writeln('AUSGANGSSITUATION')
        ..writeln(widget.fall.context)
        ..writeln();
    }
    b.writeln('AUFGABE $_nr${(auf?.pts ?? 0) > 0 ? ' · ${auf!.pts} Punkte' : ''}');
    if ((auf?.sit ?? '').isNotEmpty) {
      b
        ..writeln()
        ..writeln(auf!.sit);
    }
    if (auf?.tab != null) {
      b
        ..writeln()
        ..writeln(auf!.tab!.asText());
    }
    b.writeln();
    for (final q in teile) {
      b
        ..writeln('------------------------------')
        ..writeln('${q.teil}) · ${q.pts} ${q.pts == 1 ? 'Punkt' : 'Punkte'}')
        ..writeln()
        ..writeln(q.q)
        ..writeln()
        ..writeln('MEINE ANTWORT:')
        ..writeln(AnswerStore.instance.get(q.id).trim().isEmpty
            ? '— leer abgegeben —'
            : AnswerStore.instance.get(q.id).trim())
        ..writeln()
        ..writeln(q.amtlich
            ? 'AMTLICHER LÖSUNGSHINWEIS (IHK):'
            : 'MUSTERLÖSUNG (zu prüfen):')
        ..writeln(q.a ?? q.e);
      if ((q.vo ?? '').isNotEmpty) b.writeln('VO-Bezug: ${q.vo}');
      if (q.bewertung.isNotEmpty) {
        b.writeln('Punkteverteilung: ${q.bewertung.join(' + ')} Punkte');
      }
      b.writeln();
    }
    b
      ..writeln('==============================')
      ..writeln('Nenne abschließend die Gesamtpunktzahl, die du für Aufgabe '
          '$_nr vergeben würdest.');

    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aufgabe mit deinen Antworten kopiert – jetzt in eine '
            'KI einfügen.')));
  }
}

/// Eine Teilaufgabe a–x: Fragestellung, eigenes Antwortfeld und – nach dem
/// Aufdecken – der amtliche Lösungshinweis samt Selbstbewertung.
class _TeilKarte extends StatelessWidget {
  final Question frage;
  final TextEditingController controller;
  final bool aufgedeckt;
  final bool beantwortet;
  final bool? ergebnis;
  final String? vorher;
  final void Function(String) onAntwort;
  final VoidCallback onAufdecken;
  final void Function(int) onPunkte;
  final void Function(bool) onGewusst;

  const _TeilKarte({
    super.key,
    required this.frage,
    required this.controller,
    required this.aufgedeckt,
    required this.beantwortet,
    required this.ergebnis,
    required this.vorher,
    required this.onAntwort,
    required this.onAufdecken,
    required this.onPunkte,
    required this.onGewusst,
  });

  @override
  Widget build(BuildContext context) {
    final q = frage;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(
            color: aufgedeckt
                ? kPetrol
                : (beantwortet ? const Color(0xFFB9DCC5) : kLine)),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: aufgedeckt ? kPetrol : kBgTint,
                borderRadius: BorderRadius.circular(8)),
            child: Text(q.teil,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: aufgedeckt ? Colors.white : kInk)),
          ),
          const SizedBox(width: 9),
          Text('${q.pts} ${q.pts == 1 ? 'Punkt' : 'Punkte'}',
              style: const TextStyle(fontSize: 11, color: kMuted)),
          if (q.braucht.isNotEmpty) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFFDF8EC),
                  border: Border.all(color: const Color(0xFFD9C79A)),
                  borderRadius: BorderRadius.circular(999)),
              child: Text('baut auf ${q.braucht.join('), ')}) auf',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A6D1F))),
            ),
          ],
        ]),
        if (vorher != null) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: kBgTint, borderRadius: BorderRadius.circular(8)),
            child: Text(vorher!,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.5, color: kInkSoft)),
          ),
        ],
        const SizedBox(height: 9),
        Text(q.q,
            style: const TextStyle(
                fontSize: 15, height: 1.55, fontWeight: FontWeight.w600, color: kInk)),
        if (q.tab != null) AnlageTabelle(q.tab!),
        if (q.bild != null) AnlageBild(q.bild),
        const SizedBox(height: 11),
        if (!aufgedeckt) ..._antwortfeld() else ..._loesung(context),
      ]),
    );
  }

  List<Widget> _antwortfeld() => [
        const Text('DEINE ANTWORT · WIE IN DER PRÜFUNG',
            style: TextStyle(
                fontSize: 10,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
                color: kMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onAntwort,
          decoration: InputDecoration(
            hintText: 'Antwort schreiben …',
            filled: true,
            fillColor: kPaper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kLine)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kLine)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPetrol)),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onAufdecken,
            style: FilledButton.styleFrom(
                backgroundColor: kPetrol,
                padding: const EdgeInsets.symmetric(vertical: 11)),
            child: Text('Lösung zu ${frage.teil}) aufdecken',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ),
      ];

  List<Widget> _loesung(BuildContext context) {
    final q = frage;
    final eigene = AnswerStore.instance.get(q.id).trim();
    final max = q.maxPoints;
    return [
      const Divider(color: kLine, height: 18),
      const Text('DEINE ANTWORT',
          style: TextStyle(
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
              color: kPetrolDeep)),
      const SizedBox(height: 5),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration:
            BoxDecoration(color: kBgTint, borderRadius: BorderRadius.circular(8)),
        child: Text(eigene.isEmpty ? '— leer abgegeben —' : eigene,
            style: TextStyle(
                fontSize: 13,
                height: 1.55,
                fontStyle: eigene.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: eigene.isEmpty ? kMuted : kInk)),
      ),
      const SizedBox(height: 11),
      Text(
          q.amtlich
              ? 'AMTLICHE LÖSUNGSHINWEISE · IHK'
              : 'MUSTERLÖSUNG · NICHT AMTLICH',
          style: const TextStyle(
              fontSize: 10,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
              color: kPetrolDeep)),
      const SizedBox(height: 5),
      Text(q.a ?? q.e,
          style: const TextStyle(fontSize: 13.5, height: 1.6, color: kInk)),
      if ((q.vo ?? '').isNotEmpty) ...[
        const SizedBox(height: 7),
        Text('VO-Bezug: ${q.vo}',
            style: const TextStyle(fontSize: 11.5, color: kMuted)),
      ],
      if (q.bildL != null) AnlageBild(q.bildL, fallbackTitel: 'Lösungsskizze der IHK'),
      if (q.bewertung.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text('Punkteverteilung: ${q.bewertung.join(' + ')} Punkte',
            style: const TextStyle(fontSize: 11.5, color: kMuted)),
      ],
      const SizedBox(height: 12),
      if (max > 0) ..._punkteWahl(max) else ..._gewusstWahl(),
    ];
  }

  List<Widget> _punkteWahl(int max) {
    final cur = AnswerStore.instance.points(frage.id);
    return [
      const Text('Wie viele Punkte hättest du bekommen?',
          style: TextStyle(fontSize: 12, color: kMuted)),
      const SizedBox(height: 7),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var p = 0; p <= max; p++)
          _punkteKnopf('$p', cur == p, () => onPunkte(p)),
      ]),
      const SizedBox(height: 6),
      Text(
          cur != null
              ? 'Bewertet: $cur von $max Punkten'
              : 'Vergib dir 0–$max Punkte – so zählt die Aufgabe am Ende zum '
                  'Gesamtergebnis.',
          style: const TextStyle(fontSize: 11.5, color: kMuted)),
    ];
  }

  List<Widget> _gewusstWahl() => [
        const Text('Konntest du die Aufgabe?',
            style: TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onGewusst(false),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kErr,
                  backgroundColor:
                      ergebnis == false ? kErr.withValues(alpha: .12) : null,
                  side: BorderSide(color: kErr, width: ergebnis == false ? 2 : 1),
                  padding: const EdgeInsets.symmetric(vertical: 11)),
              child: const Text('Nicht gewusst',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onGewusst(true),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kOk,
                  backgroundColor:
                      ergebnis == true ? kOk.withValues(alpha: .12) : null,
                  side: BorderSide(color: kOk, width: ergebnis == true ? 2 : 1),
                  padding: const EdgeInsets.symmetric(vertical: 11)),
              child: const Text('Gewusst',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ]),
      ];

  Widget _punkteKnopf(String text, bool gewaehlt, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 38),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: gewaehlt ? kPetrol : kPaper,
            border: Border.all(color: gewaehlt ? kPetrol : kLine),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: gewaehlt ? Colors.white : kInk)),
        ),
      );
}
