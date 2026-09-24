import 'package:flutter/material.dart';
import 'theme/palette.dart';

export 'theme/palette.dart' show KvmPalette;

/// Fach-Namen (lang) und Kurzbezeichnungen – 1:1 aus der Web-App übernommen.
const Map<int, String> kFach = {
  1: 'Rechtsbewusstes Handeln',
  2: 'Betriebswirtschaftliches Handeln',
  3: 'Methoden der Information, Kommunikation und Planung',
  4: 'Zusammenarbeit im Betrieb',
  5: 'Kraftverkehr – fachspezifisch',
};

const Map<int, String> kFachKurz = {
  1: 'Recht',
  2: 'BWL',
  3: 'Methoden',
  4: 'Zusammenarbeit',
  5: 'Kraftverkehr',
};

const Map<int, Color> kFachColor = {
  1: Color(0xFF0C6C78),
  2: Color(0xFFD9820A),
  3: Color(0xFF2C8A4E),
  4: Color(0xFF3F6FB5),
  5: Color(0xFFA2497F),
};

/// Sortierreihenfolge der Themenbereiche (Sub) – bestimmt die Anzeige.
const List<String> kSubOrder = [
  'Arbeitsrecht', 'Betriebsverfassung', 'Sozialversicherung', 'Arbeitsschutz',
  'Umweltrecht', 'Produkthaftung/Datenschutz', 'Vertrags- und Handelsrecht',
  'Volkswirtschaft', 'Rechtsformen', 'Betriebsorganisation', 'Materialwirtschaft',
  'Kostenrechnung', 'Rechnungswesen', 'Finanzierung', 'Controlling', 'Marketing',
  'Projektmanagement', 'Kreativitätstechniken', 'Statistik', 'Präsentation',
  'Kommunikation', 'EDV', 'Arbeitsmethodik',
  'Motivation', 'Führungsstile', 'Führungsmethoden', 'Gruppen', 'Konflikte',
  'Personalentwicklung', 'Personalplanung', 'Mitarbeiterbeurteilung',
  'Berufsausbildung', 'Entgelt und Arbeitszeit',
  'Lenk- und Ruhezeiten', 'Güterkraftverkehrsrecht', 'Gefahrgut',
  'Ladungssicherung', 'Fuhrparkmanagement',
  'Straßenverkehrs- und Zulassungsrecht', 'Berufskraftfahrerqualifikation',
  'Fahrzeugtechnik und Wartung', 'Maut und Wegekosten', 'Kombinierter Verkehr',
  'Grenzüberschreitender Verkehr und Zoll', 'Schwer- und Großraumtransport',
  'Temperaturgeführte Transporte (ATP)', 'Tiertransporte',
  'Versicherungen im Güterkraftverkehr', 'Abfall- und Entsorgungstransport',
  'Container- und Seehafenverkehr', 'Umweltzonen und Emissionsvorschriften',
  'Ladungsträger und Verpackung', 'Digitalisierung und Telematik',
  'Naturwissenschaftliche und technische Grundlagen',
];

int subOrderIndex(String sub) {
  final i = kSubOrder.indexOf(sub);
  return i < 0 ? 999 : i;
}

// Leitner / Spaced Repetition
const int kMasterBox = 3;
const int kMaxBox = 5;
const List<int> kSrIntervals = [1, 2, 4, 9, 17, 33]; // Tage je Box 0..5
const int kRoundLen = 20;
const int kSimLen = 30;
const int kSimSeconds = 60 * 60;

/// Freemium: nach je so vielen beantworteten Fragen eine Interstitial-Werbung
/// (entfällt für Premium-/Werbefrei-Nutzer).
const int kAdEveryQuestions = 10;

// Farbwelt – dieselben Tokens wie die Web-App (FR-002 A). Sie lesen aus der
// aktuellen Palette (hell oder dunkel, siehe theme/palette.dart); wechselt die
// Darstellung, baut die App alle Widgets neu. Daher sind sie keine `const`.
KvmPalette get kPalette => KvmPalette.current;
Color get kBg => KvmPalette.current.steel;
Color get kBgTint => KvmPalette.current.bgTint;
Color get kPaper => KvmPalette.current.paper;
Color get kSurface => KvmPalette.current.surface;
Color get kSurface2 => KvmPalette.current.surface2;
Color get kTrack => KvmPalette.current.track;
Color get kLine => KvmPalette.current.line;
Color get kLineSoft => KvmPalette.current.lineSoft;
Color get kLineStrong => KvmPalette.current.lineStrong;
Color get kInk => KvmPalette.current.ink;
Color get kInkSoft => KvmPalette.current.inkSoft;
Color get kMuted => KvmPalette.current.muted;
Color get kPlaceholder => KvmPalette.current.placeholder;
Color get kPetrol => KvmPalette.current.petrol;
Color get kPetrolDeep => KvmPalette.current.petrolDeep;
Color get kPetrolSoft => KvmPalette.current.petrolSoft;
Color get kPetrolLine => KvmPalette.current.petrolLine;
Color get kPetrolInk => KvmPalette.current.petrolInk;
Color get kPetrolInkDeep => KvmPalette.current.petrolInkDeep;
Color get kAmber => KvmPalette.current.amber;
Color get kAmberDeep => KvmPalette.current.amberDeep;
Color get kAmberSoft => KvmPalette.current.amberSoft;
Color get kAmberLine => KvmPalette.current.amberLine;
Color get kAmberInk => KvmPalette.current.amberInk;
Color get kOk => KvmPalette.current.ok;
Color get kOkSoft => KvmPalette.current.okSoft;
Color get kOkLine => KvmPalette.current.okLine;
Color get kOkInk => KvmPalette.current.okInk;
Color get kErr => KvmPalette.current.err;
Color get kErrSoft => KvmPalette.current.errSoft;
Color get kErrFaint => KvmPalette.current.errFaint;
Color get kErrLine => KvmPalette.current.errLine;
Color get kErrInk => KvmPalette.current.errInk;
Color get kPlum => KvmPalette.current.plum;
Color get kPlumSoft => KvmPalette.current.plumSoft;
Color get kPlumLine => KvmPalette.current.plumLine;
Color get kPlumInk => KvmPalette.current.plumInk;
Color get kViolet => KvmPalette.current.violet;
Color get kVioletSoft => KvmPalette.current.violetSoft;
Color get kVioletInk => KvmPalette.current.violetInk;
Color get kBlue => KvmPalette.current.blue;
Color get kBlueSoft => KvmPalette.current.blueSoft;
Color get kBlueInk => KvmPalette.current.blueInk;
Color get kGoldSoft => KvmPalette.current.goldSoft;
Color get kGoldLine => KvmPalette.current.goldLine;
Color get kGoldInk => KvmPalette.current.goldInk;
/// Sprache aktiv / „Heute fällig“ (Web `--violet`).
Color get kDue => KvmPalette.current.violet;

const double kRadius = 16;
const double kRadiusSm = 12;

/// Weiche, dezente Kartenschatten (im Dunkeln kräftiger, aber kaum sichtbar).
List<BoxShadow> get kSoftShadow => KvmPalette.current.shadow;

/// IHK-Notenschlüssel (100-Punkte-Schema; Prozent = Punkte).
({int note, String label}) ihkGrade(int p) {
  if (p >= 92) return (note: 1, label: 'sehr gut');
  if (p >= 81) return (note: 2, label: 'gut');
  if (p >= 67) return (note: 3, label: 'befriedigend');
  if (p >= 50) return (note: 4, label: 'ausreichend');
  if (p >= 30) return (note: 5, label: 'mangelhaft');
  return (note: 6, label: 'ungenügend');
}
