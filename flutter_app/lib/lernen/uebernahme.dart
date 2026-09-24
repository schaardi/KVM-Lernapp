import '../services/rechenkern.dart' show leseZahl;

/// „Übernehmen“ aus dem Werkzeug-Dock ins aktive Antwortfeld des Quiz
/// (FR-002 C, FR-005 D) – reine Logik, damit sie sich ohne Oberfläche prüfen
/// lässt.

/// Liest eine Zahl wie das Ergebnisfeld (Web `parseCalcNum`): „1.234,5“,
/// „4.400“, „1.5“, „−3“.
double? zahlLesen(String s) => leseZahl(s);

/// Wert fürs Ergebnisfeld der Rechenfrage: ohne Tausenderpunkt („1234,5“),
/// er ersetzt den Inhalt. Ist [text] keine einzelne Zahl (etwa eine
/// Formelvorlage), gibt es `null`.
String? inErgebnisfeld(String text) {
  final t = text.replaceAll(RegExp(r'\s'), '');
  if (!_zahl.hasMatch(t)) return null;
  final v = zahlLesen(t);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return zahlOhnePunkt(v);
}

/// Eine einzelne Zahl, notfalls mit € oder % dahinter – keine Rechnung.
final RegExp _zahl = RegExp(r'^[−–+-]?\d[\d.,]*[€%]?$');

/// 1234.5 → „1234,5“, -3 → „-3“ (höchstens sechs Nachkommastellen).
String zahlOhnePunkt(double v) {
  final r = (v * 1e6).round() / 1e6;
  if (r == r.roundToDouble()) return r.toInt().toString();
  return r.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceAll('.', ',');
}

/// Text in eine Textantwort übernehmen.
/// - Eine mehrzeilige Vorlage (Formelbuch) wird mit einer Leerzeile angehängt,
///   ohne Vorhandenes zu überschreiben.
/// - Ein einzelner Wert (Rechner) kommt an die Cursorstelle – mit Leerzeichen
///   davor, wenn davor weder Leerraum noch „(“ steht.
/// Gibt den neuen Text und die Cursorposition dahinter zurück.
({String text, int cursor}) inAntwort(String alt, String neu, {int? start, int? ende}) {
  if (neu.contains('\n')) {
    final a = alt.trimRight();
    final t = a.isEmpty ? neu : '$a\n\n$neu';
    return (text: t, cursor: t.length);
  }
  final s = (start == null || start < 0 || start > alt.length) ? alt.length : start;
  final e = (ende == null || ende < s || ende > alt.length) ? s : ende;
  final vor = alt.substring(0, s);
  final wert = (vor.isNotEmpty && !RegExp(r'[\s(]$').hasMatch(vor)) ? ' $neu' : neu;
  final t = '$vor$wert${alt.substring(e)}';
  return (text: t, cursor: vor.length + wert.length);
}
