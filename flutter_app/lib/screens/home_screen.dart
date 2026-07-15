import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../services/round_builder.dart';
import '../widgets/radar_chart.dart';
import '../widgets/formula_book.dart';
import '../widgets/calculator.dart';
import '../widgets/drawing_pad.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _fach = 1;
  String _sub = '*';

  @override
  void initState() {
    super.initState();
    final counts = DataService.instance.fachCounts();
    for (var f = 1; f <= 5; f++) {
      if ((counts[f] ?? 0) > 0) {
        _fach = f;
        break;
      }
    }
  }

  String _scopeLabel() =>
      _sub == '*' ? '${kFachKurz[_fach]} – alle Bereiche' : _sub;

  Future<void> _start(RoundMode mode) async {
    final pool = RoundBuilder.build(mode, _fach, _sub, const []);
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Für diesen Modus gibt es gerade keine passenden Fragen.')));
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(mode: mode, pool: pool, fach: _fach, sub: _sub),
    ));
    setState(() {}); // Fortschritt aktualisieren nach der Runde
  }

  void _openTool(String title, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kPaper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = DataService.instance;
    final prog = ProgressService.instance;
    final total = data.questions.length;
    final mastered = prog.masteredCount();
    final seen = prog.seenCount();
    final dueN = prog.dueCount();
    final counts = data.fachCounts();
    final subs = data.subsOfFach(_fach);
    final reifeVals = [1, 2, 3, 4, 5].map((f) => prog.fachReife(f)).toList();
    final overall = (prog.overallReife() * 100).round();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kopf
            const Text('KVM-TRAINER · IHK-PRÜFUNGSVORBEREITUNG',
                style: TextStyle(
                    color: kPetrol,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('Kraftverkehrsmeister\nBasisqualifikationen',
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, color: kInk)),
            const SizedBox(height: 4),
            Text('$total Wissensfragen in 5 Fächern · Fahrschul-Prinzip mit Fortschrittsspeicherung',
                style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 18),

            // Fortschritt
            _section('DEIN LERNFORTSCHRITT', trailing: TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Zurücksetzen?'),
                    content: const Text(
                        'Deinen gesamten Lernfortschritt auf diesem Gerät wirklich zurücksetzen?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zurücksetzen')),
                    ],
                  ),
                );
                if (ok == true) setState(() => prog.reset());
              },
              child: const Text('Zurücksetzen'),
            )),
            Row(children: [
              _stat(mastered.toString(), 'Gemeistert'),
              _stat(seen.toString(), 'Gesehen'),
              _stat((total - seen).toString(), 'Offen'),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : mastered / total,
                minHeight: 8,
                backgroundColor: kLine,
                color: kPetrol,
              ),
            ),
            const SizedBox(height: 22),

            // Prüfungsreife-Radar
            _section('PRÜFUNGSREIFE', trailing: Text('$overall %',
                style: const TextStyle(
                    color: kPetrol, fontWeight: FontWeight.w700))),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  RadarChart(values: reifeVals),
                  const SizedBox(height: 8),
                  for (var f = 1; f <= 5; f++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: kFachColor[f], shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('$f. ${kFachKurz[f]}', style: const TextStyle(fontSize: 13))),
                        Text('${(reifeVals[f - 1] * 100).round()} %',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: kMuted, fontSize: 13)),
                      ]),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 22),

            // Fach
            _section('PRÜFUNGSFACH'),
            for (var f = 1; f <= 5; f++)
              _fachTile(f, counts[f] ?? 0, prog),
            const SizedBox(height: 18),

            // Themenbereich
            _section('THEMENBEREICH'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Alle Bereiche', '*'),
              for (final s in subs) _chip(s, s),
            ]),
            const SizedBox(height: 22),

            // Modus
            _section('MODUS'),
            _modeTile('Heute fällig', dueN > 0 ? '$dueN Frage(n) zur Wiederholung (Spaced Repetition).'
                    : 'Aktuell nichts fällig – starte mit neuen Fragen.',
                kDue, () => _start(RoundMode.due), badge: dueN > 0 ? '$dueN' : null),
            _modeTile('Training', 'Bis zu $kRoundLen Fragen aus „${_scopeLabel()}" mit sofortiger Auswertung.',
                kInk, () => _start(RoundMode.train)),
            _modeTile('Alle Themen üben', 'Gemischte Fragen quer durch alle Fächer.',
                kPetrolDeep, () => _start(RoundMode.all)),
            _modeTile('Schwächen üben', 'Gezielt Fragen, die du noch nicht kannst.',
                kPetrol, () => _start(RoundMode.weak)),
            _modeTile('Prüfungssimulation', '$kSimLen Fragen · 60 Min · IHK-Notenschlüssel.',
                kAmber, () => _start(RoundMode.sim)),
            _modeTile('Fallaufgaben', 'Handlungssituation mit verketteten Teilaufgaben (IHK-Format).',
                kFachColor[5]!, () => _start(RoundMode.cases)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _toolsFab(),
    );
  }

  Widget _toolsFab() {
    return FloatingActionButton.extended(
      backgroundColor: kPetrol,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.build_outlined),
      label: const Text('Werkzeuge'),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.calculate_outlined, color: kPetrol),
                title: const Text('Taschenrechner'),
                onTap: () {
                  Navigator.pop(context);
                  _openTool('Taschenrechner', const CalculatorSheet());
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: kAmber),
                title: const Text('Rechenblatt'),
                onTap: () {
                  Navigator.pop(context);
                  _openTool('Rechenblatt', const DrawingPad());
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined, color: kOk),
                title: const Text('Formelbuch'),
                onTap: () {
                  Navigator.pop(context);
                  _openTool('Formelbuch', const FormulaBook());
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _section(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: kMuted)),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _stat(String num, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: kPaper,
              border: Border.all(color: kLine),
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(num, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kPetrol)),
            Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
          ]),
        ),
      );

  Widget _fachTile(int f, int n, ProgressService prog) {
    final mastered = prog.fachMastered(f);
    final active = _fach == f;
    return Card(
      color: active ? kPetrolSoft : kPaper,
      child: InkWell(
        onTap: n == 0 ? null : () => setState(() {
          _fach = f;
          _sub = '*';
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: kFachColor[f], borderRadius: BorderRadius.circular(8)),
              child: Text('$f', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(kFach[f]!, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                Text(n > 0 ? '${kFachKurz[f]} · $mastered/$n gemeistert' : 'in Vorbereitung',
                    style: const TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),
            Text(n > 0 ? '$n' : '–', style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final n = DataService.instance.forScope(_fach, value).length;
    return ChoiceChip(
      label: Text('$label  $n'),
      selected: _sub == value,
      onSelected: (_) => setState(() => _sub = value),
      selectedColor: kPetrolSoft,
    );
  }

  Widget _modeTile(String title, String desc, Color tagColor, VoidCallback onTap,
      {String? badge}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: kInk)),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(color: kDue, borderRadius: BorderRadius.circular(11)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12.5, color: kMuted)),
          ]),
        ),
      ),
    );
  }
}
