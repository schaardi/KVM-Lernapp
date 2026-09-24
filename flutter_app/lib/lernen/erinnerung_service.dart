import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lerntage_service.dart';
import '../services/progress_service.dart';
import 'erinnerung.dart';
import 'lernplan.dart';
import 'mitteilungen.dart';

/// Die Lern-Erinnerung der App (FR-009): Einstellung `kvm_erinnerung`, planen
/// und neu planen. Neu geplant wird beim App-Start, beim Zurückkehren in den
/// Vordergrund, nach der ersten beantworteten Frage des Tages, nach einem
/// neuen Prüfungstermin und nach jeder Änderung der Einstellung – jeweils
/// nachdem alle IDs 7001–7007 gelöscht sind.
class ErinnerungService extends ChangeNotifier {
  ErinnerungService._();
  static final ErinnerungService instance = ErinnerungService._();

  static const schluessel = 'kvm_erinnerung';

  /// Plattform; Tests setzen eine eigene Umsetzung ein.
  MitteilungsDienst dienst = LokaleMitteilungen.unterstuetzt ? LokaleMitteilungen() : const KeineMitteilungen();

  SharedPreferences? _prefs;
  ErinnerungEinstellung _e = const ErinnerungEinstellung();
  Future<void> _kette = Future.value();
  Zone? _ketteZone;
  ({int tag, bool gelernt})? _geplantFuer;

  /// Hinweis unter dem Schalter, z. B. wenn Mitteilungen gesperrt sind.
  String? hinweis;

  bool get an => _e.an;
  String get zeit => _e.zeit;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _e = ErinnerungEinstellung.lesen(_prefs!.getString(schluessel));
  }

  Future<void> starten({VoidCallback? onTippen}) => dienst.starten(onTippen: onTippen);

  void _speichern(ErinnerungEinstellung e) {
    _e = e;
    _prefs?.setString(schluessel, e.schreiben());
  }

  /// Schalter an: erst jetzt nach der Erlaubnis fragen. Bei Ablehnung bleibt
  /// er aus und es erscheint der Hinweis.
  Future<bool> einschalten() async {
    var ok = false;
    try {
      ok = await dienst.erlaubnisAnfragen();
    } catch (_) {}
    if (!ok) {
      hinweis = kErinnerungGesperrt;
      _speichern(_e.mit(an: false));
      notifyListeners();
      return false;
    }
    hinweis = null;
    _speichern(_e.mit(an: true));
    notifyListeners();
    await neuPlanen();
    return true;
  }

  /// Schalter aus: alle geplanten Erinnerungen entfernen.
  Future<void> ausschalten() async {
    hinweis = null;
    _speichern(_e.mit(an: false));
    notifyListeners();
    await neuPlanen();
  }

  Future<void> zeitSetzen(String hhmm) async {
    if (zeitLesen(hhmm) == null) return;
    _speichern(_e.mit(zeit: hhmm));
    notifyListeners();
    await neuPlanen();
  }

  /// Löscht alle Erinnerungen und plant die nächsten sieben Tage neu. Die
  /// Aufrufe laufen nacheinander, damit sich zwei Planungen nicht mischen.
  Future<void> neuPlanen({DateTime? jetzt}) {
    // Die Kette gehört zu einer Zone; in einer neuen Zone (etwa im nächsten
    // Test) beginnt sie frisch, statt an einer fremden Zukunft zu hängen.
    if (!identical(_ketteZone, Zone.current)) {
      _ketteZone = Zone.current;
      _kette = Future.value();
    }
    final lauf = _kette.then((_) => _planen(jetzt));
    _kette = lauf.catchError((_) {});
    return _kette;
  }

  Future<void> _planen(DateTime? jetzt) async {
    final t = jetzt ?? DateTime.now();
    final heute = LerntageService.heute(t);
    final gelernt = LerntageService.instance.anTag(heute) > 0;
    _geplantFuer = (tag: heute, gelernt: gelernt);
    await dienst.abbrechen(kErinnerungIds);
    if (!_e.an) return;
    final z = zeitLesen(_e.zeit) ?? zeitLesen(kErinnerungStandardZeit)!;
    final liste = erinnerungenPlanen(
      jetzt: t,
      stunde: z.stunde,
      minute: z.minute,
      heuteGelernt: gelernt,
      textHeute: gelernt ? '' : _textHeute(heute),
      pruefungTag: Lernplan.instance.termin?.pruefungsTag,
    );
    for (final m in liste) {
      try {
        await dienst.planen(m);
      } catch (_) {
        // z. B. Zeitpunkt knapp verstrichen – die übrigen Tage trotzdem planen.
      }
    }
  }

  String _textHeute(int heute) {
    final plan = Lernplan.instance.rechnen(heute: heute);
    final aktiv = plan != null && plan.tage > 0;
    return erinnerungTextHeute(
      planZiel: aktiv ? plan.ziel : null,
      pruefungTag: aktiv ? plan.pruefung : null,
      serie: LerntageService.instance.serie(),
      faellig: ProgressService.instance.dueCount(),
    );
  }

  /// Nach einer Antwort oder einer Runde: neu planen, wenn heute die erste
  /// Frage beantwortet wurde oder ein neuer Tag begonnen hat.
  void pruefen() {
    final heute = LerntageService.heute();
    final gelernt = LerntageService.instance.anTag(heute) > 0;
    final g = _geplantFuer;
    if (g == null || g.tag != heute || g.gelernt != gelernt) neuPlanen();
  }
}
