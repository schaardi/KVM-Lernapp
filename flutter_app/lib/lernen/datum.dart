/// Kalendertage als Tagesindex wie im Web: `floor(ms / 86 400 000)` eines
/// Datums in UTC (`tagVon`) bzw. der Ortszeit (`LerntageService.heute`).
/// Beide zählen dieselben Kalendertage, daher lassen sie sich vergleichen.
library;

final RegExp _iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Ist [s] ein Datum im Format `2026-11-04`?
bool istIsoDatum(String? s) => s != null && _iso.hasMatch(s);

/// Tagesindex eines ISO-Datums (Web `tagVon`).
int tagVon(String datum) {
  final p = datum.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]).millisecondsSinceEpoch ~/ 86400000;
}

/// Kalenderdatum (UTC, Mitternacht) eines Tagesindex.
DateTime datumVonTag(int tag) => DateTime.fromMillisecondsSinceEpoch(tag * 86400000, isUtc: true);

/// ISO-Datum eines Tagesindex (Web `isoVon`).
String isoVon(int tag) {
  final d = datumVonTag(tag);
  String zwei(int x) => x.toString().padLeft(2, '0');
  return '${d.year}-${zwei(d.month)}-${zwei(d.day)}';
}

/// Tagesindex eines lokalen Kalendertags (Jahr/Monat/Tag der Ortszeit).
int tagVonLokal(DateTime lokal) =>
    DateTime.utc(lokal.year, lokal.month, lokal.day).millisecondsSinceEpoch ~/ 86400000;

/// Monatsnamen wie `toLocaleDateString('de-DE', {month: 'short'})`.
const List<String> kMonateKurz = [
  'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.',
];

/// Wochentage wie `{weekday: 'short'}` (Montag zuerst, wie `DateTime.weekday`).
const List<String> kWochentageKurz = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];

/// Kurzes Datum „28. Okt.“ – mit Jahr, wenn es nicht das laufende ist
/// („15. Apr. 2027“), wie Web `datumVon(tag)`.
String datumKurz(int tag, {int? laufendesJahr}) {
  final d = datumVonTag(tag);
  final jahr = laufendesJahr ?? DateTime.now().year;
  final s = '${d.day}. ${kMonateKurz[d.month - 1]}';
  return d.year == jahr ? s : '$s ${d.year}';
}

/// Langes Datum „Mi., 4. Nov. 2026“ (Web `datumVon(tag, true)`).
String datumLang(int tag) {
  final d = datumVonTag(tag);
  return '${kWochentageKurz[d.weekday - 1]}, ${d.day}. ${kMonateKurz[d.month - 1]} ${d.year}';
}
