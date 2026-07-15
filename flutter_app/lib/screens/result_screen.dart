import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/round_builder.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final RoundMode mode;
  final List<Question> pool;
  final List<bool?> results;
  final List<Question> wrong;
  final bool timeUp;
  const ResultScreen({
    super.key,
    required this.mode,
    required this.pool,
    required this.results,
    required this.wrong,
    this.timeUp = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = pool.length;
    final right = results.where((r) => r == true).length;
    final pct = total == 0 ? 0 : (right / total * 100).round();
    final isSim = mode == RoundMode.sim;
    final grade = ihkGrade(pct);
    final pass = pct >= 50;

    final title = switch (mode) {
      RoundMode.sim => 'Prüfungssimulation',
      RoundMode.weak => 'Schwächen-Training',
      RoundMode.all => 'Alle Themen',
      RoundMode.due => 'Heute fällig',
      RoundMode.cases => 'Fallaufgabe',
      _ => 'Trainingsrunde',
    };

    // Aufschlüsselung je Themenbereich
    final subs = <String>[];
    for (final q in pool) {
      if (!subs.contains(q.sub)) subs.add(q.sub);
    }
    subs.sort((a, b) => subOrderIndex(a).compareTo(subOrderIndex(b)));

    final uniqueWrong = <Question>[];
    for (final q in wrong) {
      if (!uniqueWrong.contains(q)) uniqueWrong.add(q);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 10,
                      backgroundColor: kLine,
                      color: pass ? kOk : kAmber,
                    ),
                  ),
                  Text('$pct %', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kInk)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kInk))),
            if (isSim)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: pass ? kOkSoft : kErrSoft,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${pass ? "Bestanden" : "Nicht bestanden"} · Note ${grade.note} (${grade.label})',
                      style: TextStyle(fontWeight: FontWeight.w700, color: pass ? kOk : kErr),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '$right von $total richtig${timeUp ? " · Zeit abgelaufen" : ""}${isSim ? " · $pct von 100 Punkten (IHK)" : ""}',
                style: const TextStyle(color: kMuted),
              ),
            ),
            const SizedBox(height: 22),

            // Aufschlüsselung
            for (final sub in subs) _subRow(sub),
            const SizedBox(height: 22),

            if (uniqueWrong.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final pool2 = RoundBuilder.build(RoundMode.retry, 0, '*', uniqueWrong);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => QuizScreen(mode: RoundMode.retry, pool: pool2, fach: 0, sub: '*'),
                    ));
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: kAmber, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text('Nur Fehler wiederholen (${uniqueWrong.length})'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kPetrol, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Zur Startseite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subRow(String sub) {
    final idxs = <int>[];
    for (var i = 0; i < pool.length; i++) {
      if (pool[i].sub == sub) idxs.add(i);
    }
    final r = idxs.where((i) => results[i] == true).length;
    final p = idxs.isEmpty ? 0 : (r / idxs.length * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(sub, style: const TextStyle(fontWeight: FontWeight.w600, color: kInk))),
          Text('$r/${idxs.length} · $p %', style: const TextStyle(color: kMuted, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p / 100,
            minHeight: 6,
            backgroundColor: kLine,
            color: p >= 50 ? kOk : kAmber,
          ),
        ),
      ]),
    );
  }
}
