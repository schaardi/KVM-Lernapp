import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../features/gefahrgut.dart';
import '../../features/muendlich.dart';
import '../../features/runde.dart';
import '../../features/werkzeuge.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/lerntage_service.dart';
import '../../services/progress_service.dart';
import '../../services/round_builder.dart';
import '../../services/selection_service.dart';
import '../../util/format.dart';
import '../../widgets/start/funktionen.dart';
import '../../widgets/start/hero_karte.dart';
import '../../widgets/start/pruef_karte.dart';
import '../../widgets/start/stat_leiste.dart';
import '../../widgets/ui.dart';

/// Start (FR-015 2): passt ohne Scrollen auf den Bildschirm – Statistikleiste
/// zum Aufziehen, Heute-Karte, Prüfungen und die Funktionen im Überblick.
class StartSeite extends StatelessWidget {
  const StartSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final breit = w >= 900;
      final kompakt = w <= 560 && c.maxHeight < 700;
      final abstand = kompakt ? 6.0 : 10.0;
      final funktionen = [
        Funktion(Icons.menu_book_outlined, kPetrol, 'Lernen', 'Fächer, Training, Simulation',
            () => AppState.instance.geheZu(AppSeite.lernen)),
        Funktion(Icons.mic_none, kViolet, 'Mündlich', 'Fachgespräch üben', () => starteMuendlich(context)),
        Funktion(Icons.work_outline, kPlum, 'Fallaufgaben', 'Praxisfälle mit Teilaufgaben', () => starteFallaufgabe(context)),
        Funktion(Icons.auto_stories_outlined, kOk, 'Formelbuch', 'Formeln und Schemata', () => oeffneFormelbuch(context)),
        Funktion(Icons.calculate_outlined, kPetrol, 'Kostenwesen', 'Lehrgang und Rechner', () => oeffneKostenwesen(context)),
        Funktion(Icons.warning_amber_rounded, kAmber, 'Gefahrgut', 'ADR-Klassen und Quiz', () => oeffneGefahrgut(context)),
      ];
      final stat = StatLeiste(onZuruecksetzen: () => _zuruecksetzen(context));
      final hero = HeroKarte(
          onLernen: () => starteRunde(context, RoundMode.due), kompakt: kompakt, breit: breit);
      final pruef = PruefKarte(
          onOeffnen: () => AppState.instance.geheZu(AppSeite.pruefungen), kompakt: kompakt, breit: breit);
      final kacheln = FunktionsKacheln(funktionen: funktionen, kompakt: kompakt);

      if (breit) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                stat,
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 11, child: Column(children: [hero, const SizedBox(height: 14), kacheln])),
                  const SizedBox(width: 14),
                  Expanded(flex: 10, child: pruef),
                ]),
              ]),
            ),
          ),
        );
      }
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, kompakt ? 8 : 12, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!kompakt) _kopf(w),
          stat,
          SizedBox(height: abstand),
          hero,
          SizedBox(height: abstand),
          pruef,
          SizedBox(height: abstand),
          kacheln,
        ]),
      );
    });
  }

  Widget _kopf(double w) {
    final data = DataService.instance;
    final counts = data.fachCounts();
    final basis = SelectionService.baseFacher.where((f) => (counts[f] ?? 0) > 0).length;
    final zusatz = SelectionService.zusatzFacher.where((f) => (counts[f] ?? 0) > 0).length;
    final pruef = data.cases.where((c) => c.id.startsWith('P-')).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEISTER FÜR KRAFTVERKEHR',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dispStyle((w * 0.068).clamp(18.0, 34.0), height: 1.15)),
        if (w > 560) ...[
          const SizedBox(height: 4),
          Text(
            '${fmtN(data.activeQuestions().length)} Wissensfragen · $basis Basisqualifikationen + '
            '$zusatz Fachrichtung · $pruef Original-IHK-Prüfungen',
            style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.35),
          ),
        ],
      ]),
    );
  }

  /// Zweistufige Sicherheitsabfrage – „Löschen“ erst nach dem Haken.
  Future<void> _zuruecksetzen(BuildContext context) async {
    var sicher = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Lernstand zurücksetzen?'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                'Alle gemeisterten Fragen, Statistiken und Wiederholungstermine auf '
                'diesem Gerät werden gelöscht. Das lässt sich nicht rückgängig machen.',
                style: TextStyle(color: kInkSoft, height: 1.4)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setLocal(() => sicher = !sicher),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Checkbox(
                    value: sicher,
                    activeColor: kErr,
                    onChanged: (v) => setLocal(() => sicher = v ?? false),
                  ),
                  Expanded(
                    child: Text('Ja, Lernstand endgültig löschen.',
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
              onPressed: sicher ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Endgültig löschen'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    ProgressService.instance.reset();
    LerntageService.instance.reset();
    AppState.instance.refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lernstand zurückgesetzt.')));
    }
  }
}
