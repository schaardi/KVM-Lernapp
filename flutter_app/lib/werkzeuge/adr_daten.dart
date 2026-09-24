import 'dart:ui' show Color;

/// Gefahrgut (ADR) – Daten 1:1 aus der Web-App (`index.html`: `ADR`, `EX`,
/// `KEMLER`, `decodeKemler`). Die Farben der Gefahrzettel sind die
/// ADR-Farben und bleiben in beiden Darstellungen gleich.

/// Grundfläche eines Gefahrzettels (Web `fill`).
enum AdrFlaeche { voll, weissRot, rotGelb, gelbWeiss, weissSchwarz, streifenRot, streifen9 }

/// Symbol im oberen Teil der Raute (Web `sym`).
enum AdrSymbol { flamme, flasche, totenkopf, explosion, oxidation, aetzend, radioaktiv, biogefahr, keins }

const Color kAdrSchwarz = Color(0xFF111111);
const Color kAdrWeiss = Color(0xFFFFFFFF);
const Color kAdrRot = Color(0xFFE4322B);
const Color kAdrGelb = Color(0xFFF4C400);

/// Eine Gefahrgutklasse mit ihrem Gefahrzettel.
class AdrKlasse {
  /// Klasse, z. B. „2.1“.
  final String klasse;

  /// Zahl unten auf dem Zettel, z. B. „2“.
  final String nummer;
  final String name;
  final AdrFlaeche flaeche;

  /// Füllfarbe bei [AdrFlaeche.voll].
  final Color farbe;
  final AdrSymbol symbol;
  final Color symbolFarbe;
  final Color nummerFarbe;
  final String beispiele;

  const AdrKlasse(
    this.klasse,
    this.nummer,
    this.name, {
    this.flaeche = AdrFlaeche.voll,
    this.farbe = kAdrWeiss,
    required this.symbol,
    this.symbolFarbe = kAdrSchwarz,
    this.nummerFarbe = kAdrSchwarz,
    required this.beispiele,
  });
}

/// Die 15 Gefahrzettel der Übersicht (Web `ADR`).
const List<AdrKlasse> kAdrKlassen = [
  AdrKlasse('1', '1', 'Explosive Stoffe und Gegenstände',
      farbe: Color(0xFFE38A00), symbol: AdrSymbol.explosion, beispiele: 'Sprengstoff, Munition, Feuerwerk'),
  AdrKlasse('2.1', '2', 'Entzündbare Gase',
      farbe: kAdrRot, symbol: AdrSymbol.flamme, symbolFarbe: kAdrWeiss, beispiele: 'Propan, Butan, Wasserstoff'),
  AdrKlasse('2.2', '2', 'Nicht entzündbare, nicht giftige Gase',
      farbe: Color(0xFF2E9B51),
      symbol: AdrSymbol.flasche,
      symbolFarbe: kAdrWeiss,
      beispiele: 'Stickstoff, Sauerstoff, CO₂'),
  AdrKlasse('2.3', '2', 'Giftige Gase', symbol: AdrSymbol.totenkopf, beispiele: 'Chlor, Ammoniak'),
  AdrKlasse('3', '3', 'Entzündbare flüssige Stoffe',
      farbe: kAdrRot, symbol: AdrSymbol.flamme, symbolFarbe: kAdrWeiss, beispiele: 'Benzin, Diesel, Ethanol'),
  AdrKlasse('4.1', '4', 'Entzündbare feste Stoffe',
      flaeche: AdrFlaeche.streifenRot, symbol: AdrSymbol.flamme, beispiele: 'Streichhölzer, Schwefel'),
  AdrKlasse('4.2', '4', 'Selbstentzündliche Stoffe',
      flaeche: AdrFlaeche.weissRot, symbol: AdrSymbol.flamme, beispiele: 'Weißer Phosphor'),
  AdrKlasse('4.3', '4', 'Stoffe, die mit Wasser entzündbare Gase entwickeln',
      farbe: Color(0xFF2758A8), symbol: AdrSymbol.flamme, symbolFarbe: kAdrWeiss, beispiele: 'Natrium, Calciumcarbid'),
  AdrKlasse('5.1', '5.1', 'Entzündend (oxidierend) wirkende Stoffe',
      farbe: kAdrGelb, symbol: AdrSymbol.oxidation, beispiele: 'Wasserstoffperoxid, Nitrate'),
  AdrKlasse('5.2', '5.2', 'Organische Peroxide',
      flaeche: AdrFlaeche.rotGelb, symbol: AdrSymbol.flamme, beispiele: 'Organische Peroxide'),
  AdrKlasse('6.1', '6', 'Giftige Stoffe', symbol: AdrSymbol.totenkopf, beispiele: 'Pestizide, Arsenverbindungen'),
  AdrKlasse('6.2', '6', 'Ansteckungsgefährliche Stoffe',
      symbol: AdrSymbol.biogefahr, beispiele: 'Medizinische Abfälle, Kulturen'),
  AdrKlasse('7', '7', 'Radioaktive Stoffe',
      flaeche: AdrFlaeche.gelbWeiss, symbol: AdrSymbol.radioaktiv, beispiele: 'Radioaktive Präparate'),
  AdrKlasse('8', '8', 'Ätzende Stoffe',
      flaeche: AdrFlaeche.weissSchwarz,
      symbol: AdrSymbol.aetzend,
      nummerFarbe: kAdrWeiss,
      beispiele: 'Schwefelsäure, Natronlauge'),
  AdrKlasse('9', '9', 'Verschiedene gefährliche Stoffe und Gegenstände',
      flaeche: AdrFlaeche.streifen9, symbol: AdrSymbol.keins, beispiele: 'Lithiumbatterien, Asbest'),
];

/// Beispielstoff für die Warntafel: Gefahrnummer (Kemler-Zahl), UN-Nummer.
class AdrBeispiel {
  final String kemler;
  final String un;
  final String stoff;
  const AdrBeispiel(this.kemler, this.un, this.stoff);
}

/// Beispielstoffe der Warntafel (Web `EX`).
const List<AdrBeispiel> kAdrBeispiele = [
  AdrBeispiel('33', '1203', 'Benzin (Ottokraftstoff)'),
  AdrBeispiel('30', '1202', 'Dieselkraftstoff / Heizöl leicht'),
  AdrBeispiel('23', '1978', 'Propan'),
  AdrBeispiel('268', '1017', 'Chlor'),
  AdrBeispiel('80', '1830', 'Schwefelsäure (> 51 %)'),
  AdrBeispiel('X423', '1428', 'Natrium'),
  AdrBeispiel('90', '3082', 'Umweltgefährdender Stoff, flüssig'),
  AdrBeispiel('606', '2814', 'Ansteckungsgefährlicher Stoff'),
];

/// Bedeutung der Ziffern einer Gefahrnummer (Web `KEMLER`).
const Map<String, String> kKemler = {
  '2': 'Entweichen von Gas durch Druck oder chemische Reaktion',
  '3': 'Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen',
  '4': 'Entzündbarkeit fester Stoffe',
  '5': 'Entzündend (oxidierend, brandfördernd) wirkend',
  '6': 'Giftigkeit oder Ansteckungsgefahr',
  '7': 'Radioaktivität',
  '8': 'Ätzwirkung',
  '9': 'Gefahr einer spontanen heftigen Reaktion',
  '0': 'ohne weitere Bedeutung (Auffüllziffer)',
};

/// Teil einer gedeuteten Zeile; [fett] wie `<b>` im Web.
class TextTeil {
  final String text;
  final bool fett;
  const TextTeil(this.text, {this.fett = false});
}

/// Eine Zeile als schlichter Text (Tests, Vorlesen).
String zeilenText(List<TextTeil> zeile) => zeile.map((t) => t.text).join();

/// Deutet eine Gefahrnummer (Web `decodeKemler`):
/// - vorangestelltes X: reagiert gefährlich mit Wasser
/// - erste Ziffer: Hauptgefahr, verdoppelt = Verstärkung der Gefahr
/// - „0“ an zweiter Stelle einer zweistelligen Zahl: keine weitere Gefahr
List<List<TextTeil>> kemlerDeuten(String kemler) {
  final out = <List<TextTeil>>[];
  var x = kemler.trim().toUpperCase();
  if (x.startsWith('X')) {
    out.add(const [TextTeil('X', fett: true), TextTeil(' = der Stoff reagiert gefährlich mit Wasser')]);
    x = x.substring(1);
  }
  final z = x.split('');
  if (z.isEmpty) return out;
  String bedeutung(String d) => kKemler[d] ?? '?';
  if (z.length >= 2 && z[0] == z[1]) {
    out.add([
      TextTeil('${z[0]}${z[1]}', fett: true),
      TextTeil(' = ${bedeutung(z[0])} – '),
      const TextTeil('Verdoppelung = Verstärkung der Gefahr', fett: true),
    ]);
    for (var i = 2; i < z.length; i++) {
      if (z[i] != '0') out.add([TextTeil(z[i], fett: true), TextTeil(' = ${bedeutung(z[i])}')]);
    }
  } else {
    out.add([TextTeil(z[0], fett: true), TextTeil(' (Hauptgefahr) = ${bedeutung(z[0])}')]);
    for (var j = 1; j < z.length; j++) {
      if (z[j] == '0') {
        if (z.length == 2) out.add(const [TextTeil('0', fett: true), TextTeil(' = keine weitere Gefahr')]);
      } else {
        out.add([TextTeil(z[j], fett: true), TextTeil(' = ${bedeutung(z[j])}')]);
      }
    }
  }
  return out;
}
