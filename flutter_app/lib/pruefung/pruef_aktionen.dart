import 'package:flutter/material.dart';
import '../models.dart';
import '../services/answer_store.dart';
import 'echt.dart';
import 'ergebnisse.dart';
import 'pruef_ui.dart';

/// „Neu starten“ mit Nachfrage (FR-014 1) – aus der Prüfungsliste und vom
/// Ergebnis-Bildschirm. Gibt true zurück, wenn neu gestartet wurde; öffnen
/// muss der Aufrufer (bei Aufgabe 1).
Future<bool> neuStartenFragen(BuildContext context, CaseStudy fall) async {
  final e = Echtbedingungen.instance.von(fall.id);
  final ok = await nachfragen(
    context,
    titel: 'Prüfung neu starten?',
    text: '${e != null && !e.abgegeben ? 'Der laufende Durchgang unter Prüfungsbedingungen wird abgebrochen. ' : ''}'
        'Deine Antworten, Rechenwege, Skizzen und Punkte dieser Prüfung werden gelöscht – '
        'ausgewertete Durchgänge bleiben in deiner Übersicht.',
    ja: 'Neu starten',
    gefaehrlich: true,
  );
  if (!ok) return false;
  PruefErgebnisse.instance.neuStarten(fall);
  return true;
}

/// Start unter Prüfungsbedingungen (FR-007): Läuft für diese Prüfung schon ein
/// Durchgang, geht es dort weiter. Läuft einer einer anderen Prüfung oder gibt
/// es schon Antworten, fragt die App vorher. Gibt true zurück, wenn das
/// Aufgabenblatt (bei Aufgabe 1) geöffnet werden soll.
Future<bool> echtStartenFragen(BuildContext context, CaseStudy fall) async {
  final lauf = Echtbedingungen.instance.lauf;
  if (lauf != null && lauf.id == fall.id) return true;
  if (lauf != null && !lauf.abgegeben) {
    final ok = await nachfragen(
      context,
      titel: 'Es läuft noch eine andere Prüfung unter Prüfungsbedingungen.',
      text: 'Diesen Durchgang beenden und die neue Prüfung starten?',
      ja: 'Neue Prüfung starten',
    );
    if (!ok || !context.mounted) return false;
  }
  if (fall.steps.any((s) => AnswerStore.instance.hatStand(s.id))) {
    final ok = await nachfragen(
      context,
      titel: 'Für diese Prüfung sind schon Antworten gespeichert.',
      text: 'Unter Prüfungsbedingungen startest du mit leeren Blättern – die bisherigen Antworten und Punkte '
          'dieser Prüfung werden gelöscht.',
      ja: 'Leeren und starten',
      gefaehrlich: true,
    );
    if (!ok) return false;
  }
  PruefErgebnisse.instance.echtStarten(fall);
  return true;
}
