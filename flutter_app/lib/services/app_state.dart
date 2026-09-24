import 'package:flutter/foundation.dart';

/// Die fünf Seiten der Startansicht (FR-015).
enum AppSeite { start, lernen, pruefungen, vergleich, konto }

/// Gemeinsamer Zustand der Startansicht: aktive Seite, gewähltes Fach und
/// Themenbereich. Seiten und Kacheln lesen und setzen ihn; `refresh()` baut
/// nach einer Runde alle Seiten mit dem neuen Lernstand neu.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  AppSeite seite = AppSeite.start;
  int fach = 1;
  String sub = '*';

  /// Seite „Vergleich“: null = wird geprüft, true = Rangliste eingerichtet,
  /// false = nicht eingerichtet (Reiter entfällt).
  final ValueNotifier<bool?> vergleichVerfuegbar = ValueNotifier(null);

  /// Hinweispunkt am Reiter „Vergleich“ (Einladung oder Freundschaftsanfrage).
  final ValueNotifier<bool> vergleichHinweis = ValueNotifier(false);

  void geheZu(AppSeite s) {
    if (s == AppSeite.vergleich && vergleichVerfuegbar.value == false) {
      s = AppSeite.start;
    }
    if (seite == s) {
      notifyListeners();
      return;
    }
    seite = s;
    notifyListeners();
  }

  void waehleFach(int f) {
    fach = f;
    sub = '*';
    notifyListeners();
  }

  void waehleBereich(String s) {
    sub = s;
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
