import '../werkzeuge/rechner_modell.dart';

/// Start des Pakets „Werkzeuge“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-005/008: Rechnerverlauf, Meldungen bereit prüfen.
Future<void> initWerkzeuge() async {
  // Rechner: Eingabe, Verlauf und „eingeklappt“ aus kvm_rechner (wie Web).
  await RechnerModell.instance.laden();
}
