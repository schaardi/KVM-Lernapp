import 'package:flutter/material.dart';

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

// Farben (Design der Web-App)
const Color kPetrol = Color(0xFF0C6C78);
const Color kPetrolDeep = Color(0xFF084F58);
const Color kPetrolSoft = Color(0xFFE3F0F1);
const Color kAmber = Color(0xFFD9820A);
const Color kOk = Color(0xFF2C8A4E);
const Color kOkSoft = Color(0xFFE4F2E9);
const Color kErr = Color(0xFFC0472F);
const Color kErrSoft = Color(0xFFF7E6E1);
const Color kInk = Color(0xFF17272E);
const Color kMuted = Color(0xFF5C6B72);
const Color kLine = Color(0xFFD8E3E5);
const Color kPaper = Color(0xFFFFFFFF);
const Color kDue = Color(0xFF6D5AE6);

/// IHK-Notenschlüssel (100-Punkte-Schema; Prozent = Punkte).
({int note, String label}) ihkGrade(int p) {
  if (p >= 92) return (note: 1, label: 'sehr gut');
  if (p >= 81) return (note: 2, label: 'gut');
  if (p >= 67) return (note: 3, label: 'befriedigend');
  if (p >= 50) return (note: 4, label: 'ausreichend');
  if (p >= 30) return (note: 5, label: 'mangelhaft');
  return (note: 6, label: 'ungenügend');
}
