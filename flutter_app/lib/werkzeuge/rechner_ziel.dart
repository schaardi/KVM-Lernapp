import 'package:flutter/foundation.dart';

/// Beschriftung des Übernahme-Ziels im Rechner: „↩ Übernehmen <Ziel>“
/// (FR-005 D), z. B. „ins Ergebnisfeld“, „in den Rechenweg · Z2“ oder
/// „in deine Antwort“.
///
/// Quiz und Aufgabenblatt können den Wert setzen, sobald ein Antwortfeld den
/// Fokus bekommt; `null` zeigt „ins Antwortfeld“. Der eingesetzte Text kommt
/// weiter über `onUebernehmen` des Werkzeug-Docks.
final ValueNotifier<String?> rechnerZiel = ValueNotifier<String?>(null);

/// Platz, den der schwebende Rechner auf breiten Bildschirmen (ab 1100 dp)
/// rechts braucht, solange er an seinem Platz oben rechts steht (Web
/// `has-calc`). Screens können ihren Inhalt um diesen Wert nach links
/// rücken; 0 = nichts auszuweichen.
final ValueNotifier<double> rechnerAusweichen = ValueNotifier<double>(0);
