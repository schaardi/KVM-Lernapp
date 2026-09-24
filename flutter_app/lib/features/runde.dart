import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/round_builder.dart';
import '../screens/aufgabenblatt_screen.dart';
import '../screens/quiz_screen.dart';

/// Startet eine Übungsrunde im gewählten Fach/Bereich (oder fachübergreifend)
/// und aktualisiert danach alle Seiten.
Future<void> starteRunde(BuildContext context, RoundMode mode) async {
  if (mode == RoundMode.cases) return starteFallaufgabe(context);
  final st = AppState.instance;
  final pool = RoundBuilder.build(mode, st.fach, st.sub, const []);
  if (pool.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Für diesen Modus gibt es gerade keine passenden Fragen.')));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => QuizScreen(mode: mode, pool: pool, fach: st.fach, sub: st.sub),
  ));
  st.refresh();
}

/// Zufällige Fallaufgabe (wie Web `startRound('cases')`) im Aufgabenblatt.
Future<void> starteFallaufgabe(BuildContext context) async {
  final faelle = DataService.instance.cases;
  if (faelle.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Es sind noch keine Fallaufgaben verfügbar.')));
    return;
  }
  await oeffneFall(context, faelle[Random().nextInt(faelle.length)]);
}

/// Öffnet eine Fallaufgabe oder Original-Prüfung im Aufgabenblatt – auf Wunsch
/// gleich bei Aufgabe [aufgabe].
Future<void> oeffneFall(BuildContext context, CaseStudy fall, {int? aufgabe}) async {
  var start = 0;
  if (aufgabe != null) {
    final i = fall.steps.indexWhere((s) => s.nr == aufgabe);
    if (i >= 0) start = i;
  }
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => AufgabenblattScreen(fall: fall, startIndex: start),
  ));
  AppState.instance.refresh();
}

CaseStudy? fallMitId(String id) {
  for (final c in DataService.instance.cases) {
    if (c.id == id) return c;
  }
  return null;
}
