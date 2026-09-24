import 'package:flutter/material.dart';
import 'answer_store.dart';
import 'data_service.dart';
import 'lerntage_service.dart';
import 'progress_service.dart';

/// Ein Erfolg (Medaille) – wird aus dem Lernstand berechnet, nicht gespeichert
/// (FR-003 E.6, Web `erfolgeListe`).
class Erfolg {
  final IconData icon;
  final String titel;
  final String text;
  final int wert;
  final int ziel;
  const Erfolg(this.icon, this.titel, this.text, this.wert, this.ziel);

  bool get geschafft => wert >= ziel;
  double get anteil => ziel <= 0 ? 1 : (wert / ziel).clamp(0.0, 1.0);
}

List<Erfolg> erfolgeListe() {
  final prog = ProgressService.instance;
  final beantwortet = prog.antwortenGesamt();
  final gesehen = prog.seenCount();
  final gemeistert = prog.masteredCount();
  var beste = 0.0;
  for (final f in DataService.instance.activeFacher()) {
    final r = prog.fachReife(f);
    if (r > beste) beste = r;
  }
  // Original-Prüfungen: bewertete Teilaufgaben und die beste Prüfung
  var bewertet = 0, besteP = 0;
  for (final c in DataService.instance.cases) {
    if (!c.id.startsWith('P-')) continue;
    var summe = 0;
    for (final s in c.steps) {
      final p = AnswerStore.instance.points(s.id);
      if (p != null) {
        bewertet++;
        summe += p;
      }
    }
    if (summe > besteP) besteP = summe;
  }
  final serie = LerntageService.instance.serie();
  return [
    Erfolg(Icons.directions_walk, 'Erste Schritte', '10 Fragen beantwortet', beantwortet, 10),
    Erfolg(Icons.bolt, 'Am Ball', '250 Antworten gegeben', beantwortet, 250),
    Erfolg(Icons.menu_book_outlined, 'Vielleser', '1.000 Fragen gesehen', gesehen, 1000),
    Erfolg(Icons.check_circle_outline, 'Sattelfest', '100 Fragen gemeistert', gemeistert, 100),
    Erfolg(Icons.star_outline, 'Meisterlich', '1.000 Fragen gemeistert', gemeistert, 1000),
    Erfolg(Icons.local_fire_department_outlined, 'Dranbleiben', '3 Lerntage in Folge', serie, 3),
    Erfolg(Icons.calendar_month_outlined, 'Wochenserie', '7 Lerntage in Folge', serie, 7),
    Erfolg(Icons.gps_fixed, 'Fachprofi', 'ein Fach auf Grün', (beste * 100).round(), 70),
    Erfolg(Icons.description_outlined, 'Prüfungsluft', 'erste Prüfungsaufgabe bewertet', bewertet, 1),
    Erfolg(Icons.emoji_events_outlined, 'Bestanden', '50 Punkte in einer Original-Prüfung', besteP, 50),
  ];
}
