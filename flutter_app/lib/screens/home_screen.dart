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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: kLine, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _hero(),
            const SizedBox(height: 22),

            // Fortschritt
            _section('Lernfortschritt', trailing: TextButton.icon(
              onPressed: () async {
                final ok = await _confirmReset();
                if (!mounted || !ok) return;
                setState(() => prog.reset());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lernfortschritt zurückgesetzt.')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: kMuted),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Zurücksetzen'),
            )),
            Row(children: [
              _stat(mastered.toString(), 'Gemeistert', kOk),
              _stat(seen.toString(), 'Gesehen', kPetrol),
              _stat((total - seen).toString(), 'Offen', kMuted),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : mastered / total,
                minHeight: 10,
                backgroundColor: kLine,
                color: kPetrol,
              ),
            ),
            const SizedBox(height: 24),

            // Prüfungsreife-Radar
            _section('Prüfungsreife', trailing: _pill('$overall %', kPetrol)),
            _softCard(
              child: Column(children: [
                RadarChart(values: reifeVals),
                const SizedBox(height: 8),
                for (var f = 1; f <= 5; f++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: kFachColor[f], shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('$f. ${kFachKurz[f]}', style: const TextStyle(fontSize: 13, color: kInkSoft))),
                      Text('${(reifeVals[f - 1] * 100).round()} %',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: kMuted, fontSize: 13)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 24),

            // Fach
            _section('Prüfungsfach'),
            for (var f = 1; f <= 5; f++)
              _fachTile(f, counts[f] ?? 0, prog),
            const SizedBox(height: 20),

            // Themenbereich
            _section('Themenbereich'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Alle Bereiche', '*'),
              for (final s in subs) _chip(s, s),
            ]),
            const SizedBox(height: 24),

            // Modus
            _section('Übungsmodus'),
            _modeTile('Heute fällig',
                dueN > 0 ? '$dueN Frage(n) zur Wiederholung – optimal getaktet.'
                    : 'Aktuell nichts fällig – starte mit neuen Fragen.',
                kDue, Icons.event_repeat, () => _start(RoundMode.due),
                badge: dueN > 0 ? '$dueN' : null),
            _modeTile('Training',
                'Bis zu $kRoundLen Fragen aus „${_scopeLabel()}" mit sofortiger Auswertung.',
                kPetrol, Icons.bolt, () => _start(RoundMode.train)),
            _modeTile('Alle Themen',
                'Gemischte Fragen quer durch alle fünf Fächer.',
                kPetrolDeep, Icons.shuffle, () => _start(RoundMode.all)),
            _modeTile('Schwächen gezielt',
                'Fragen, die du noch nicht sicher beherrschst.',
                kAmber, Icons.gps_fixed, () => _start(RoundMode.weak)),
            _modeTile('Prüfungssimulation',
                '$kSimLen Fragen · 60 Minuten · IHK-Notenschlüssel.',
                kErr, Icons.timer_outlined, () => _start(RoundMode.sim)),
            _modeTile('Fallaufgaben',
                'Handlungssituation mit verketteten Teilaufgaben (IHK-Format).',
                kFachColor[5]!, Icons.account_tree_outlined, () => _start(RoundMode.cases)),
          ],
        ),
      ),
      floatingActionButton: _toolsFab(),
    );
  }

  /// Zweistufige Sicherheitsabfrage – der „Löschen"-Knopf ist erst nach dem
  /// Bestätigungshaken aktiv, damit nichts versehentlich passiert.
  Future<bool> _confirmReset() async {
    var sure = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Fortschritt zurücksetzen?'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
                'Alle gemeisterten Fragen, Statistiken und Wiederholungstermine auf '
                'diesem Gerät werden gelöscht. Das lässt sich nicht rückgängig machen.',
                style: TextStyle(color: kInkSoft, height: 1.4)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setLocal(() => sure = !sure),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Checkbox(
                    value: sure,
                    activeColor: kErr,
                    onChanged: (v) => setLocal(() => sure = v ?? false),
                  ),
                  const Expanded(
                    child: Text('Ja, Fortschritt endgültig löschen.',
                        style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
                  ),
                ]),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: kErr, disabledBackgroundColor: kErr.withValues(alpha: 0.35)),
              onPressed: sure ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Endgültig löschen'),
            ),
          ],
        ),
      ),
    );
    return ok == true;
  }

  // ---- Kopfbereich / Branding ----
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kPaper, kBgTint],
        ),
        borderRadius: BorderRadius.circular(kRadius + 4),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _monogram(),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('IHK-FORTBILDUNGSPRÜFUNG',
                style: TextStyle(color: kPetrol, fontWeight: FontWeight.w800,
                    fontSize: 10.5, letterSpacing: 1.4)),
            SizedBox(height: 2),
            Text('KVM-Trainer',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: kInk, height: 1.0)),
          ]),
        ]),
        const SizedBox(height: 16),
        const Text('Geprüfte/r Kraftverkehrsmeister/-in',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800,
                height: 1.12, color: kInk)),
      ]),
    );
  }

  Widget _monogram() {
    return Container(
      width: 50, height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [kPetrol, kPetrolDeep],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0x330C6C78), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 26),
    );
  }

  Widget _toolsFab() {
    return FloatingActionButton.extended(
      backgroundColor: kPetrol,
      foregroundColor: Colors.white,
      elevation: 3,
      icon: const Icon(Icons.handyman_outlined),
      label: const Text('Werkzeuge', style: TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              _toolTile(Icons.calculate_outlined, kPetrol, 'Taschenrechner',
                  () => _openTool('Taschenrechner', const CalculatorSheet())),
              _toolTile(Icons.draw_outlined, kAmber, 'Rechenblatt',
                  () => _openTool('Rechenblatt', const DrawingPad())),
              _toolTile(Icons.menu_book_outlined, kOk, 'Formelbuch',
                  () => _openTool('Formelbuch', const FormulaBook())),
              const SizedBox(height: 6),
            ]),
          ),
        );
      },
    );
  }

  Widget _toolTile(IconData icon, Color color, String title, VoidCallback open) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: kInk)),
      trailing: const Icon(Icons.chevron_right, color: kMuted),
      onTap: () {
        Navigator.pop(context);
        open();
      },
    );
  }

  Widget _section(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kInk)),
            if (trailing != null) trailing,
          ],
        ),
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _softCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kLine),
          boxShadow: kSoftShadow,
        ),
        child: child,
      );

  Widget _stat(String num, String label, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: kPaper,
              borderRadius: BorderRadius.circular(kRadiusSm),
              border: Border.all(color: kLine),
              boxShadow: kSoftShadow),
          child: Column(children: [
            Text(num, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: color, height: 1)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11.5, color: kMuted, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _fachTile(int f, int n, ProgressService prog) {
    final mastered = prog.fachMastered(f);
    final active = _fach == f;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: active ? kPetrolSoft : kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: active ? kPetrol.withValues(alpha: 0.5) : kLine),
        boxShadow: active ? null : kSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: n == 0 ? null : () => setState(() {
            _fach = f;
            _sub = '*';
          }),
          borderRadius: BorderRadius.circular(kRadius),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kFachColor[f], borderRadius: BorderRadius.circular(11)),
                child: Text('$f', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kFach[f]!, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk, fontSize: 14.5)),
                  const SizedBox(height: 1),
                  Text(n > 0 ? '${kFachKurz[f]} · $mastered/$n gemeistert' : 'in Vorbereitung',
                      style: const TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
              if (active) const Icon(Icons.check_circle, color: kPetrol, size: 20)
              else Text(n > 0 ? '$n' : '–',
                  style: const TextStyle(color: kMuted, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final n = DataService.instance.forScope(_fach, value).length;
    final selected = _sub == value;
    return ChoiceChip(
      label: Text('$label · $n'),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _sub = value),
      selectedColor: kPetrol,
      labelStyle: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13,
          color: selected ? Colors.white : kInkSoft),
      side: BorderSide(color: selected ? kPetrol : kLine),
    );
  }

  Widget _modeTile(String title, String desc, Color tagColor, IconData icon,
      VoidCallback onTap, {String? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: tagColor, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kInk)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: kDue, borderRadius: BorderRadius.circular(999)),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(desc, style: const TextStyle(fontSize: 12.5, color: kMuted, height: 1.25)),
                ]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: kMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
