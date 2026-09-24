import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../lernen/muendlich_logik.dart';
import '../screens/muendlich_screen.dart';
import '../services/app_state.dart';
import '../services/voice_service.dart';

/// Einstieg „Mündlich üben“ (FR-011) – von der Startseite (Kachel) und der
/// Seite „Lernen“ (Moduskarte). Zehn Fragen aus dem gewählten Bereich
/// (Fach + Themenbereich), gewichtet wie im Training.
Future<void> starteMuendlich(BuildContext context) async {
  final st = AppState.instance;
  final kandidaten = muendlichKandidaten(st.fach, st.sub);
  if (kandidaten.length < kMuendlichMindestens) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Für diesen Bereich gibt es noch keine passenden Fragen fürs Fachgespräch.')));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => MuendlichScreen(pool: muendlichPool(kandidaten), fach: st.fach, sub: st.sub),
  ));
  st.refresh();
}

/// Lässt sich im gewählten Bereich mündlich üben (mindestens drei Fragen)?
/// Für die Moduskarte auf der Seite „Lernen“ (deaktiviert, wenn nicht).
bool muendlichMoeglich() {
  final st = AppState.instance;
  return muendlichKandidaten(st.fach, st.sub).length >= kMuendlichMindestens;
}

/// Beschreibung der Moduskarte wie im Web (`oralDesc`).
String muendlichBeschreibung() {
  final st = AppState.instance;
  final n = muendlichKandidaten(st.fach, st.sub).length;
  if (n < kMuendlichMindestens) return 'Für diesen Bereich gibt es noch keine passenden Fragen fürs Fachgespräch.';
  final bereich = st.sub == '*' ? '${kFachKurz[st.fach]} – alle Bereiche' : st.sub;
  final wie = VoiceService.instance.sttAvailable ? ' per Sprache' : ', laut oder in Stichpunkten';
  return '${min(kMuendlichLaenge, n)} Fragen aus „$bereich“ werden vorgelesen – du antwortest frei$wie, '
      'danach Musterlösung und Selbstcheck.';
}
