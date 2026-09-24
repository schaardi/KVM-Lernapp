/// Prüfungsbereiche der Original-Prüfungen – Kürzel aus der ID (`P-XX-…`),
/// Kurzname, amtlicher Name und Teil (Basisqualifikationen `bq`,
/// handlungsspezifischer Teil `hq`), wie im Web (`PB`, `BEREICH_KURZ`).
class PruefBereich {
  final String k;
  final String kurz;
  final String name;
  final String teil;
  const PruefBereich(this.k, this.kurz, this.name, this.teil);
}

/// Für Statistik und Bestehenschance (Web `PB`).
const List<PruefBereich> kPruefBereiche = [
  PruefBereich('RE', 'Recht', 'Rechtsbewusstes Handeln', 'bq'),
  PruefBereich('BW', 'BWL', 'Betriebswirtschaftliches Handeln', 'bq'),
  PruefBereich('MI', 'Methoden', 'Methoden der Information, Kommunikation und Planung', 'bq'),
  PruefBereich('ZI', 'Zusammenarbeit', 'Zusammenarbeit im Betrieb', 'bq'),
  PruefBereich('NT', 'Naturwiss. & Technik', 'Naturwissenschaftliche und technische Gesetzmäßigkeiten', 'bq'),
  PruefBereich('FT', 'Fuhrpark', 'Fuhrparktechnik und Fuhrparkmanagement', 'hq'),
  PruefBereich('OK', 'Organisation', 'Organisation und Kommunikation', 'hq'),
];

const List<String> kBereicheBq = ['RE', 'BW', 'MI', 'ZI', 'NT'];
const List<String> kBereicheHq = ['FT', 'OK'];

PruefBereich? pruefBereich(String k) {
  for (final b in kPruefBereiche) {
    if (b.k == k) return b;
  }
  return null;
}

/// Bereichskürzel aus der Prüfungs-ID: `P-RE-20241106` → `RE`.
String bereichVonId(String id) => RegExp(r'^P-([A-Z]+)-').firstMatch(id)?.group(1) ?? '';

/// Kurzname je Prüfungsbereich für die Filterchips (FR-002 F, Web
/// `BEREICH_KURZ`): die amtlichen Namen sind bis zu 55 Zeichen lang. Die
/// Reihenfolge folgt der Prüfung – erst die Basisqualifikationen, dann die
/// handlungsspezifischen Bereiche.
const List<(String, String)> kBereichKurz = [
  ('Rechtsbewusstes Handeln', 'Recht'),
  ('Betriebswirtschaftliches Handeln', 'BWL'),
  ('Methoden der Information, Kommunikation und Planung', 'Methoden'),
  ('Zusammenarbeit im Betrieb', 'Zusammenarbeit'),
  ('Naturwissenschaftliche und technische Gesetzmäßigkeiten', 'Naturwiss. & Technik'),
  ('Fuhrparktechnik und Fuhrparkmanagement', 'Fuhrpark (FT)'),
  ('Organisation und Kommunikation', 'Organisation (OK)'),
];

/// Rang eines Bereichs für die Chips; unbekannte Bereiche stehen am Ende.
int bereichRang(String name) {
  for (var i = 0; i < kBereichKurz.length; i++) {
    if (kBereichKurz[i].$1 == name) return i;
  }
  return kBereichKurz.length;
}

/// Kurzname für den Chip; unbekannte Bereiche behalten den vollen Namen.
String bereichKurz(String name) {
  final i = bereichRang(name);
  return i < kBereichKurz.length ? kBereichKurz[i].$2 : name;
}
