import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../pruefung/bereiche.dart';
import '../pruefung/echt.dart';
import '../pruefung/ergebnisse.dart';
import '../pruefung/pruef_aktionen.dart';
import '../services/answer_store.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/round_builder.dart';
import '../widgets/ui.dart';
import 'aufgabenblatt_screen.dart';
import 'quiz_screen.dart';

/// Ergebnis einer Runde, einer Fallaufgabe oder einer Original-Prüfung.
///
/// Bei einer Original-Prüfung ([fall] mit `P-…`) wird der Durchgang gemerkt
/// (FR-014): ohne Punkte für jede Teilaufgabe zählt er noch nicht als
/// bestanden oder nicht bestanden. Unter Prüfungsbedingungen ([echt], nach
/// der Abgabe) kommt die Bearbeitungszeit dazu (FR-007).
class ResultScreen extends StatefulWidget {
  final RoundMode mode;
  final List<Question> pool;
  final List<bool?> results;
  final List<Question> wrong;
  final bool timeUp;
  final CaseStudy? fall;
  final EchtLauf? echt;
  const ResultScreen({
    super.key,
    required this.mode,
    required this.pool,
    required this.results,
    required this.wrong,
    this.timeUp = false,
    this.fall,
    this.echt,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

/// Was nach dem Merken eines Durchgangs zu sagen ist.
class _Wertung {
  final PruefDurchgang d;
  final bool erster;
  final BereichStand? bereich;
  final double? vorher;
  const _Wertung(this.d, this.erster, this.bereich, this.vorher);
}

class _ResultScreenState extends State<ResultScreen> {
  _Wertung? _wertung;
  late final int _possible;
  late final int _achieved;

  bool get _pointBased => _possible > 0;
  bool get _pruef =>
      widget.mode == RoundMode.cases && widget.fall != null && widget.fall!.id.startsWith('P-') && _pointBased;

  @override
  void initState() {
    super.initState();
    // Punkte-Ergebnis: bei Prüfungen mit Punktangaben zählen die selbst
    // vergebenen Punkte, nicht die Zahl der Aufgaben.
    var possible = 0, achieved = 0;
    for (final q in widget.pool) {
      final m = q.maxPoints;
      if (m > 0) {
        possible += m;
        achieved += AnswerStore.instance.points(q.id) ?? 0;
      }
    }
    _possible = possible;
    _achieved = achieved;
    if (_pruef) {
      // Original-Prüfung: Durchgang merken – mehrmals „Zum Ergebnis“ ändert
      // denselben Durchgang.
      final pe = PruefErgebnisse.instance;
      final fall = widget.fall!;
      final k = bereichVonId(fall.id);
      final vorher = pe.statistik().bereiche[k]?.chance;
      final d = pe.merken(pe.durchgang(fall, echt: widget.echt));
      final st = pe.statistik();
      final erster = d.gewertet && pe.erstversuche().any((e) => e.k == d.k);
      _wertung = _Wertung(d, erster, st.bereiche[k], vorher);
    }
    // Der Durchgang unter Prüfungsbedingungen ist ausgewertet.
    if (widget.echt != null && widget.echt!.abgegeben && _pointBased) Echtbedingungen.instance.setzen(null);
  }

  void _zurSeite(AppSeite s) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    AppState.instance.geheZu(s);
  }

  Future<void> _nochmal() async {
    final fall = widget.fall;
    if (_pruef && fall != null) {
      // Bei einer Original-Prüfung dieselbe Prüfung mit leeren Blättern –
      // nicht eine zufällige andere.
      if (!await neuStartenFragen(context, fall) || !mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AufgabenblattScreen(fall: fall)));
      return;
    }
    if (widget.mode == RoundMode.cases) {
      final faelle = DataService.instance.cases;
      if (faelle.isEmpty) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AufgabenblattScreen(fall: faelle[Random().nextInt(faelle.length)])));
      return;
    }
    // Nach einer Wiederholungsrunde ein Training.
    final m = widget.mode == RoundMode.retry ? RoundMode.train : widget.mode;
    final st = AppState.instance;
    final pool = RoundBuilder.build(m, st.fach, st.sub, const []);
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Für diesen Modus gibt es gerade keine passenden Fragen.')));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => QuizScreen(mode: m, pool: pool, fach: st.fach, sub: st.sub),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pool = widget.pool;
    final total = pool.length;
    final right = widget.results.where((r) => r == true).length;
    final pct = _pointBased
        ? (_achieved / _possible * 100).round()
        : (total == 0 ? 0 : (right / total * 100).round());
    final isSim = widget.mode == RoundMode.sim;
    final grade = ihkGrade(pct);
    final pass = pct >= 50;
    final w = _wertung;
    final offen = w != null && !w.d.gewertet;

    final title = switch (widget.mode) {
      RoundMode.sim => 'Prüfungssimulation',
      RoundMode.weak => 'Schwächen-Training',
      RoundMode.all => 'Alle Themen',
      RoundMode.due => 'Heute fällig',
      RoundMode.cases => _pointBased ? 'Ergebnis' : 'Fallaufgabe',
      _ => 'Trainingsrunde',
    };

    // Aufschlüsselung je Themenbereich
    final subs = <String>[];
    for (final q in pool) {
      if (!subs.contains(q.sub)) subs.add(q.sub);
    }
    subs.sort((a, b) => subOrderIndex(a).compareTo(subOrderIndex(b)));

    final uniqueWrong = <Question>[];
    for (final q in widget.wrong) {
      if (!uniqueWrong.contains(q)) uniqueWrong.add(q);
    }

    final ring = pct >= 80 ? kOk : (pct >= 50 ? kPetrol : kAmber);
    final fett = TextStyle(fontWeight: FontWeight.w700, color: kInk);
    final echt = widget.echt;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: 124,
                      height: 124,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 116,
                          height: 116,
                          child: CircularProgressIndicator(
                            value: pct / 100,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor: kTrack,
                            color: ring,
                          ),
                        ),
                        Text('$pct %', style: dispStyle(28)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isSim || _pointBased)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _Abzeichen(
                          offen
                              ? 'Noch nicht vollständig bewertet'
                              : '${pass ? 'Bestanden' : 'Nicht bestanden'} · Note ${grade.note} (${grade.label})',
                          art: offen ? 0 : (pass ? 1 : -1),
                        ),
                      ),
                    ),
                  Center(child: Text(title.toUpperCase(), style: dispStyle(26))),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(style: TextStyle(color: kMuted, fontSize: 13.5, height: 1.45), children: [
                      if (_pointBased) ...[
                        TextSpan(text: '$_achieved', style: fett),
                        const TextSpan(text: ' von '),
                        TextSpan(text: '$_possible', style: fett),
                        TextSpan(
                            text: ' Punkten${widget.timeUp ? ' · Zeit abgelaufen' : ''} · Note ${grade.note} (${grade.label})'),
                        if (echt != null && echt.abgegeben)
                          TextSpan(
                              text: ' · Bearbeitungszeit ${dauerText(echt.dauer)} von ${dauerText(echt.min * 60000)}'
                                  '${echt.zeitUm ? ' (Zeit abgelaufen)' : ''}'),
                      ] else ...[
                        TextSpan(text: '$right', style: fett),
                        const TextSpan(text: ' von '),
                        TextSpan(text: '$total', style: fett),
                        TextSpan(
                            text: ' richtig${widget.timeUp ? ' · Zeit abgelaufen' : ''}'
                                '${isSim ? ' · $pct von 100 Punkten (IHK-Schlüssel)' : ''}'),
                      ],
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  if (w != null) ...[
                    const SizedBox(height: 16),
                    _chanceHinweis(w),
                  ],
                  const SizedBox(height: 18),
                  if (subs.isNotEmpty)
                    Karte(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 2),
                          child: Text('Nach Themenbereich',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk)),
                        ),
                        for (final sub in subs) _subRow(sub),
                      ]),
                    ),
                  if (_pointBased) ...[
                    const SizedBox(height: 14),
                    _taskPoints(),
                  ],
                  const SizedBox(height: 18),
                  _aktionen(uniqueWrong),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hinweis unter dem Kopf (FR-014 5): Bestehenschance, Wiederholung oder
  /// „Noch nicht gewertet“ – mit dem Link zur Übersicht.
  Widget _chanceHinweis(_Wertung w) {
    final fett = TextStyle(fontWeight: FontWeight.w700, color: kInk);
    final teile = <InlineSpan>[];
    if (!w.d.gewertet) {
      teile.addAll([
        TextSpan(text: 'Noch nicht gewertet:', style: fett),
        TextSpan(
            text: ' ${w.d.bew ?? 0} von ${w.d.teile ?? 0} Teilaufgaben haben Punkte. Vergib für jede Teilaufgabe '
                'Punkte (auch 0) und geh noch einmal auf „Zum Ergebnis“. Dann zählt die Prüfung für deine Übersicht '
                'und deine Bestehenschance.'),
      ]);
    } else if (w.bereich != null) {
      final b = w.bereich!;
      final jetzt = peProzent(b.chance);
      if (w.erster) {
        teile.add(TextSpan(text: 'Bestehenschance ${b.bereich.kurz}: $jetzt', style: fett));
        if (w.vorher != null && peProzent(w.vorher) != jetzt) {
          teile.add(TextSpan(text: ' (vorher ${peProzent(w.vorher)})'));
        }
        teile.add(TextSpan(text: ' · aus ${b.n} ${b.n == 1 ? 'Prüfung' : 'Prüfungen'} in diesem Bereich.'));
      } else {
        teile.addAll([
          TextSpan(text: 'Wiederholung:', style: fett),
          TextSpan(
              text: ' Sie steht in deiner Übersicht, zählt aber nicht für die Bestehenschance, denn die Lösungen '
                  'kanntest du schon. Bestehenschance ${b.bereich.kurz}: '),
          TextSpan(text: jetzt, style: fett),
          const TextSpan(text: '.'),
        ]);
      }
    }
    if (teile.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kPetrolSoft,
        border: Border.all(color: kPetrolLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(style: TextStyle(fontSize: 13, height: 1.5, color: kInkSoft), children: teile)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _zurSeite(AppSeite.pruefungen),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Zur Übersicht',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kPetrolInk,
                    decoration: TextDecoration.underline,
                    decorationColor: kPetrolInk)),
          ),
        ),
      ]),
    );
  }

  Widget _aktionen(List<Question> uniqueWrong) {
    final knoepfe = <Widget>[
      if (uniqueWrong.isNotEmpty)
        OutlinedButton(
          onPressed: () {
            final pool2 = RoundBuilder.build(RoundMode.retry, 0, '*', uniqueWrong);
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => QuizScreen(mode: RoundMode.retry, pool: pool2, fach: 0, sub: '*'),
            ));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: kAmberInk,
            backgroundColor: kAmberSoft,
            side: BorderSide(color: kAmber, width: 1.5),
            minimumSize: const Size(0, 48),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: Text('Nur Fehler wiederholen (${uniqueWrong.length})'),
        ),
      FilledButton(
        onPressed: _nochmal,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        child: Text(_pruef ? 'Prüfung neu starten' : 'Neue Runde starten'),
      ),
      if (_pruef)
        OutlinedButton(
          onPressed: () => _zurSeite(AppSeite.pruefungen),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text('Alle Prüfungen'),
        ),
      OutlinedButton(
        onPressed: () => _zurSeite(AppSeite.start),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        child: const Text('Zur Startseite'),
      ),
    ];
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 640) {
        return Row(children: [
          for (var i = 0; i < knoepfe.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: knoepfe[i]),
          ],
        ]);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < knoepfe.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          knoepfe[i],
        ],
      ]);
    });
  }

  Widget _subRow(String sub) {
    final pool = widget.pool;
    final idxs = <int>[];
    for (var i = 0; i < pool.length; i++) {
      if (pool[i].sub == sub) idxs.add(i);
    }
    var subPos = 0, subAch = 0;
    var hasPts = false;
    for (final i in idxs) {
      final m = pool[i].maxPoints;
      if (m > 0) {
        hasPts = true;
        subPos += m;
        subAch += AnswerStore.instance.points(pool[i].id) ?? 0;
      }
    }
    final int p;
    final String numTxt;
    if (hasPts) {
      p = subPos == 0 ? 0 : (subAch / subPos * 100).round();
      numTxt = '$subAch/$subPos P · $p %';
    } else {
      final r = idxs.where((i) => widget.results[i] == true).length;
      p = idxs.isEmpty ? 0 : (r / idxs.length * 100).round();
      numTxt = '$r/${idxs.length} · $p %';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(sub, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: kInk))),
          const SizedBox(width: 10),
          Text(numTxt, style: monoStyle(12, color: kMuted, weight: FontWeight.w500, spacing: 0)),
        ]),
        const SizedBox(height: 4),
        Balken(p / 100, hoehe: 8, farbe: p >= 50 ? kOk : kAmber),
      ]),
    );
  }

  /// Punkte je Aufgabe (nur Prüfungen): nach Aufgabe gruppiert, darunter die
  /// Teilaufgaben – eine Prüfung hat bis zu 23 Teile.
  Widget _taskPoints() {
    final gruppen = <({int nr, String titel, List<(String, int, int)> teile})>[];
    for (final q in widget.pool) {
      final mx = q.maxPoints;
      if (mx == 0) continue;
      var i = gruppen.indexWhere((g) => g.nr == q.nr);
      if (i < 0) {
        final t = q.nr > 0 ? 'Aufgabe ${q.nr}' : (TaskParts.of(q).nr.isEmpty ? 'Aufgabe' : TaskParts.of(q).nr);
        gruppen.add((nr: q.nr, titel: t, teile: []));
        i = gruppen.length - 1;
      }
      gruppen[i].teile.add((q.teil, AnswerStore.instance.points(q.id) ?? 0, mx));
    }
    return Karte(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text('DEINE PUNKTE JE AUFGABE', style: monoStyle(10, spacing: 1.2)),
        ),
        for (final g in gruppen) _gruppe(g.titel, g.teile),
      ]),
    );
  }

  Widget _gruppe(String titel, List<(String, int, int)> teile) {
    final got = teile.fold<int>(0, (s, t) => s + t.$2);
    final max = teile.fold<int>(0, (s, t) => s + t.$3);
    final pc = max == 0 ? 0 : (got / max * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(titel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: kInk))),
          Text('$got/$max P', style: monoStyle(12, color: kMuted, weight: FontWeight.w500, spacing: 0)),
        ]),
        const SizedBox(height: 4),
        Balken(pc / 100, hoehe: 8, farbe: pc >= 50 ? kOk : kAmber),
        if (teile.length > 1) ...[
          const SizedBox(height: 7),
          Wrap(spacing: 5, runSpacing: 5, children: [
            for (final t in teile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t.$2 * 2 >= t.$3 ? kOkSoft : kPaper,
                  border: Border.all(color: t.$2 * 2 >= t.$3 ? kOkLine : kLine),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${t.$1}) ${t.$2}/${t.$3}',
                    style: monoStyle(10.5,
                        color: t.$2 * 2 >= t.$3 ? kOkInk : kMuted, weight: FontWeight.w500, spacing: 0)),
              ),
          ]),
        ],
      ]),
    );
  }
}

/// Abzeichen „Bestanden · Note 2 (gut)“ (art 1), „Nicht bestanden …“ (-1) oder
/// „Noch nicht vollständig bewertet“ (0).
class _Abzeichen extends StatelessWidget {
  final String text;
  final int art;
  const _Abzeichen(this.text, {required this.art});

  @override
  Widget build(BuildContext context) {
    final (grund, rand, schrift) = switch (art) {
      1 => (kOkSoft, kOkLine, kOkInk),
      -1 => (kErrSoft, kErrLine, kErrInk),
      _ => (kAmberSoft, kAmberLine, kAmberInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: grund, border: Border.all(color: rand), borderRadius: BorderRadius.circular(14)),
      child: Text(text.toUpperCase(),
          textAlign: TextAlign.center, style: monoStyle(11, color: schrift, weight: FontWeight.w600, spacing: 1.1)),
    );
  }
}
