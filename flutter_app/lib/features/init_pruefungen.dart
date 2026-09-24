import '../pruefung/cloud_abgleich.dart';
import '../pruefung/echt.dart';
import '../pruefung/ergebnisse.dart';

/// Start des Pakets „Prüfungen“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-014: Ergebnisse laden
/// (`kvm_pruef_erg`, einmalig mit Übernahme von `kvm_echt_verlauf`), laufende
/// Prüfungsbedingungen (`kvm_echt`), `pruefStatistik` setzen und den
/// Cloud-Abgleich `pruefungen_abgleichen` anbinden (beim Anmelden alles,
/// danach nach jeder Änderung).
Future<void> initPruefungen() async {
  await Echtbedingungen.instance.load();
  await PruefErgebnisse.instance.load();
  PruefCloud.instance.anbinden();
}
