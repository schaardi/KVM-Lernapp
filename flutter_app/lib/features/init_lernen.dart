import 'package:flutter/widgets.dart';
import '../lernen/erinnerung_service.dart';
import '../lernen/lernplan.dart';
import '../services/app_state.dart';
import '../services/progress_service.dart';

/// Start des Pakets „Lernen“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-006/009/011: Prüfungstermin laden,
/// Lern-Erinnerung (Mitteilungen) starten und neu planen. Im sicheren Modus
/// ([mitMitteilungen] aus) bleibt das Mitteilungs-Plugin unberührt – ohne
/// `starten` sind Planen und Abbrechen wirkungslos.
Future<void> initLernen({bool mitMitteilungen = true}) async {
  await Lernplan.instance.load();
  final er = ErinnerungService.instance;
  await er.load();
  if (mitMitteilungen) {
    try {
      // Antippen einer Erinnerung öffnet die Startseite.
      await er.starten(onTippen: () => AppState.instance.geheZu(AppSeite.start));
    } catch (_) {}
  }
  _einmalAnmelden();
  // Nicht auf das Planen warten – der Start soll nicht hängen.
  er.neuPlanen();
}

bool _angemeldet = false;
String? _letzterTermin;

void _einmalAnmelden() {
  _letzterTermin = Lernplan.instance.termin?.datum;
  if (_angemeldet) return;
  _angemeldet = true;
  WidgetsBinding.instance.addObserver(_Vordergrund());
  // Nach jeder gespeicherten Antwort (Quiz, Aufgabenblatt, Mündlich) und nach
  // einer Runde: War es die erste Antwort des Tages, wird die Erinnerung neu
  // geplant – heute kommt dann keine mehr.
  ProgressService.instance.addListener(ErinnerungService.instance.pruefen);
  AppState.instance.addListener(ErinnerungService.instance.pruefen);
  // Neuer oder entfernter Prüfungstermin: Erinnerungen enden am Tag davor.
  Lernplan.instance.addListener(() {
    final t = Lernplan.instance.termin?.datum;
    if (t == _letzterTermin) return;
    _letzterTermin = t;
    ErinnerungService.instance.neuPlanen();
  });
}

/// Zurück im Vordergrund: Plan (vielleicht ein neuer Tag) und Erinnerungen
/// auffrischen.
class _Vordergrund with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Lernplan.instance.aktualisieren();
    ErinnerungService.instance.neuPlanen();
  }
}
