import '../cloud/vergleich_dienst.dart';

/// Start des Pakets „Cloud“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-004/010/012/014: Rangliste,
/// Gruppen, Freunde und Profile – beim Start und bei jeder Anmeldung den Stand
/// laden und die eigenen Werte melden, danach nach jeder Antwort (entprellt)
/// und bei neuen Prüfungsergebnissen (`pruefStand`). Lädt im Hintergrund und
/// hält den App-Start nicht auf.
Future<void> initCloud() => VergleichDienst.instance.starten();
