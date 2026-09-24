import 'dart:async';
import '../werkzeuge/melden_dienst.dart';
import '../werkzeuge/rechner_modell.dart';

/// Start des Pakets „Werkzeuge“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-005/008: Rechnerverlauf, Meldungen bereit prüfen.
Future<void> initWerkzeuge() async {
  // Rechner: Eingabe, Verlauf und „eingeklappt“ aus kvm_rechner (wie Web).
  await RechnerModell.instance.laden();
  // Fehler melden: gemeldete Fragen (kvm_gemeldet); den Knopf gibt es erst,
  // wenn meldungen_bereit() antwortet – jetzt und nach jeder Anmeldung. Die
  // Abfrage läuft im Hintergrund und hält den Start nicht auf.
  await MeldenDienst.instance.laden();
  MeldenDienst.instance.anmeldungBeobachten();
  unawaited(MeldenDienst.instance.bereitPruefen());
}
