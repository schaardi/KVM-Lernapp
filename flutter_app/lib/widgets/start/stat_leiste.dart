import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/data_service.dart';
import '../../services/erfolge.dart';
import '../../services/lerntage_service.dart';
import '../../services/progress_service.dart';
import '../../util/format.dart';
import '../radar_chart.dart';
import '../ui.dart';

/// Statistikleiste der Startseite (FR-015 2.2): vier Kennzahlen in einer Zeile,
/// zum Aufziehen per Antippen oder Wischen. Aufgeklappt: Prüfungsreife je Fach,
/// Aktivität der letzten 14 Tage, Erfolge und „Lernstand zurücksetzen“.
class StatLeiste extends StatefulWidget {
  final VoidCallback onZuruecksetzen;
  const StatLeiste({super.key, required this.onZuruecksetzen});

  @override
  State<StatLeiste> createState() => _StatLeisteState();
}

class _StatLeisteState extends State<StatLeiste> {
  bool _offen = false;
  double _dy = 0;
  DateTime _gewischt = DateTime(2000);

  void _umschalten() {
    // Ein Tippen direkt nach dem Wischen zählt nicht (sonst schlösse es gleich).
    if (DateTime.now().difference(_gewischt).inMilliseconds < 500) return;
    setState(() => _offen = !_offen);
  }

  void _wischen(DragUpdateDetails d) {
    _dy += d.delta.dy;
    if (_dy > 36 && !_offen) {
      setState(() => _offen = true);
      _dy = 0;
      _gewischt = DateTime.now();
    } else if (_dy < -36 && _offen) {
      setState(() => _offen = false);
      _dy = 0;
      _gewischt = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prog = ProgressService.instance;
    final aktiv = DataService.instance.activeQuestions().length;
    final gemeistert = prog.masteredCount();
    final gesehen = prog.seenCount();
    final breit = MediaQuery.sizeOf(context).width;
    final klein = breit < 340;

    final kopf = Semantics(
      button: true,
      expanded: _offen,
      label: 'Statistik ${_offen ? 'zuklappen' : 'aufklappen'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _umschalten,
        onVerticalDragStart: (_) => _dy = 0,
        onVerticalDragUpdate: _wischen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    // Spalten so breit wie ihr Inhalt, gleichmäßig verteilt – so
                    // bleibt „Tage in Folge“ ganz sichtbar (FR-015 2.2).
                    // Spalten nach Inhalt gewichtet, gleichmäßig verteilt – so bleibt
                    // „Tage in Folge“ ganz sichtbar (FR-015 2.2); zu lange Texte
                    // werden kleiner statt abgeschnitten.
                    child: Row(children: [
                      Expanded(flex: 10, child: _kpi(fmtN(gemeistert), 'gemeistert', klein)),
                      Expanded(flex: 9, child: _kpi(fmtN(gesehen), 'gesehen', klein)),
                      Expanded(flex: 8, child: _kpi(fmtN(aktiv - gesehen), 'offen', klein)),
                      Expanded(flex: 12, child: _kpi(fmtN(LerntageService.instance.serie()), 'Tage in Folge', klein)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (!klein) Text('STATISTIK', style: monoStyle(8.5, color: kPetrolInk, spacing: 0.5)),
                AnimatedRotation(
                  turns: _offen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 20, color: kPetrolInk),
                ),
              ]),
            ]),
            const SizedBox(height: 7),
            Balken(aktiv == 0 ? 0 : gemeistert / aktiv,
                hoehe: 4,
                verlauf: LinearGradient(colors: [kPetrol, kAmber])),
          ]),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(children: [
          kopf,
          if (_offen)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: kLineSoft))),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: _inhalt(),
            ),
        ]),
      ),
    );
  }

  Widget _kpi(String zahl, String label, bool klein) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(zahl, maxLines: 1, style: dispStyle(klein ? 15 : 19, color: kPetrolInkDeep, height: 1)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, maxLines: 1, style: TextStyle(fontSize: klein ? 9.5 : 10.5, height: 1.2, color: kMuted)),
          ),
        ],
      );

  Widget _inhalt() {
    final data = DataService.instance;
    final prog = ProgressService.instance;
    final facher = data.activeFacher();
    final werte = facher.map(prog.fachReife).toList();
    final gesamt = prog.overallReife();
    final tage = LerntageService.instance.letzte(14);
    final summe = tage.fold<int>(0, (s, t) => s + t.anzahl);
    final aktivTage = tage.where((t) => t.anzahl > 0).length;
    final erfolge = erfolgeListe();
    final geschafft = erfolge.where((e) => e.geschafft).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Abschnitt('Prüfungsreife je Fach',
          rechts: Text(fmtProzent(gesamt), style: monoStyle(13, color: kPetrolInk, spacing: 0)),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8)),
      LayoutBuilder(builder: (context, c) {
        final legende = Column(children: [
          for (var i = 0; i < facher.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: kFachColor[facher[i]], shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('${facher[i]}. ${kFachKurz[facher[i]]}',
                      style: TextStyle(fontSize: 13, color: kInkSoft)),
                ),
                Text(fmtProzent(werte[i]),
                    softWrap: false,
                    style: monoStyle(12.5, color: kMuted, spacing: 0)),
              ]),
            ),
        ]);
        final radar = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
          child: RadarChart(facher: facher, values: werte),
        );
        if (c.maxWidth < 420) {
          return Column(children: [Center(child: radar), const SizedBox(height: 8), legende]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Center(child: radar)),
          const SizedBox(width: 16),
          Expanded(child: legende),
        ]);
      }),
      const SizedBox(height: 6),
      Text(
        'Reife = Anteil gemeisterter Fragen je Fach, gewichtet nach Leitner-Box. '
        'Ziel: alle Zacken möglichst weit nach außen.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, height: 1.4, color: kMuted),
      ),
      Abschnitt('Aktivität · 14 Tage',
          zusatz: '${fmtN(summe)} Antworten · $aktivTage ${aktivTage == 1 ? 'Tag' : 'Tage'}',
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8)),
      AktivitaetDiagramm(tage: tage),
      Abschnitt('Erfolge',
          zusatz: '$geschafft von ${erfolge.length}',
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8)),
      SizedBox(
        height: 138,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: erfolge.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ErfolgMedaille(erfolg: erfolge[i]),
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: widget.onZuruecksetzen,
          style: OutlinedButton.styleFrom(
            foregroundColor: kMuted,
            side: BorderSide(color: kLineStrong),
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: const Text('Lernstand zurücksetzen'),
        ),
      ),
    ]);
  }
}

const _wochentage = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// 14 Säulen aus `kvm_tage`: Höhe relativ zum Maximum, leere Tage als Strich,
/// heute fett in Petrol (FR-003 E.8).
class AktivitaetDiagramm extends StatelessWidget {
  final List<({int tag, int anzahl})> tage;
  const AktivitaetDiagramm({super.key, required this.tage});

  @override
  Widget build(BuildContext context) {
    final maxWert = tage.fold<int>(1, (m, t) => t.anzahl > m ? t.anzahl : m);
    final heute = LerntageService.heute();
    return SizedBox(
      height: 96,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final t in tage)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Tooltip(
                      message: '${fmtN(t.anzahl)} Antworten',
                      child: t.anzahl == 0
                          ? Container(
                              height: 3,
                              decoration: BoxDecoration(color: kTrack, borderRadius: BorderRadius.circular(2)))
                          : FractionallySizedBox(
                              heightFactor: 0.08 + 0.92 * t.anzahl / maxWert,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [kPetrol, kPetrolDeep]),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _wochentage[(DateTime.fromMillisecondsSinceEpoch(t.tag * 86400000, isUtc: true).weekday - 1) % 7],
                  style: monoStyle(9.5,
                      color: t.tag == heute ? kPetrolInk : kMuted,
                      weight: t.tag == heute ? FontWeight.w600 : FontWeight.w500,
                      spacing: 0),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Medaille 54 dp: verdient mit Goldverlauf, offen gedämpft mit Balken.
class ErfolgMedaille extends StatelessWidget {
  final Erfolg erfolg;
  const ErfolgMedaille({super.key, required this.erfolg});

  @override
  Widget build(BuildContext context) {
    final ok = erfolg.geschafft;
    return Tooltip(
      message: ok
          ? '${erfolg.text} – geschafft'
          : '${erfolg.text} – ${fmtN(erfolg.wert < erfolg.ziel ? erfolg.wert : erfolg.ziel)} von ${fmtN(erfolg.ziel)}',
      child: Container(
        width: 104,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Column(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ok
                  ? const RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      colors: [Color(0xFFFBD88A), Color(0xFFE3A032), Color(0xFFB96C06)],
                      stops: [0, 0.6, 1])
                  : null,
              color: ok ? null : kSurface2,
              border: ok ? null : Border.all(color: kLine),
            ),
            child: Icon(erfolg.icon, size: 22, color: ok ? Colors.white : kPlaceholder),
          ),
          const SizedBox(height: 6),
          Text(erfolg.titel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ok ? kInk : kInkSoft)),
          const SizedBox(height: 2),
          Expanded(
            child: Text(erfolg.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, height: 1.25, color: kMuted)),
          ),
          if (!ok) Balken(erfolg.anteil, hoehe: 4, farbe: kAmber),
        ]),
      ),
    );
  }
}
