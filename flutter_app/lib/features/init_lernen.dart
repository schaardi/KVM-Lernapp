import 'package:flutter/widgets.dart';
import '../lernen/erinnerung_service.dart';
import '../lernen/lernplan.dart';
import '../services/app_state.dart';

/// Start des Pakets „Lernen“ – wird beim App-Start aus `main.dart` aufgerufen
/// (nach Daten, Lernstand und Anmeldung). FR-006/009/011: Prüfungstermin laden,
/// Lern-Erinnerung (Mitteilungen) starten und neu planen.
Future<void> initLernen() async {
  await Lernplan.instance.load();
  final er = ErinnerungService.instance;
  await er.load();
  try {
    // Antippen einer Erinnerung öffnet die Startseite.
    await er.starten(onTippen: () => AppState.instance.geheZu(AppSeite.start));
  } catch (_) {}
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
  // Nach einer Runde (auch im Aufgabenblatt) baut AppState die Seiten neu –
  // war es die erste Antwort des Tages, wird die Erinnerung neu geplant.
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
