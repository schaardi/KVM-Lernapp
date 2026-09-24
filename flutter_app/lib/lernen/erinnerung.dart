import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../util/format.dart';
import 'datum.dart';

/// Lern-Erinnerung (FR-009): eine tägliche lokale Mitteilung zur gewählten
/// Uhrzeit, damit die Serie nicht reißt. Hier steht die reine Logik – was wann
/// geplant wird und mit welchem Text; das Plugin steckt in `mitteilungen.dart`.
///
/// Es gibt bewusst keine tägliche Wiederholung, denn die könnte „heute schon
/// gelernt“ nicht berücksichtigen. Stattdessen werden die nächsten sieben Tage
/// einzeln geplant (IDs 7001–7007) und bei jedem Anlass neu.

/// IDs der geplanten Mitteilungen, Tag 0 (heute) bis Tag 6.
const List<int> kErinnerungIds = [7001, 7002, 7003, 7004, 7005, 7006, 7007];

const String kErinnerungTitel = 'Zeit zum Lernen';

/// Text für die Folgetage – beim Planen ist ihr Stand noch unbekannt.
const String kErinnerungFolgetage = 'Kurz reinschauen: Die fälligen Fragen warten, und deine Serie hält.';

const String kErinnerungStandardZeit = '19:00';

/// Hinweis, wenn Mitteilungen für die App gesperrt sind.
const String kErinnerungGesperrt = 'Mitteilungen sind für die App ausgeschaltet – in den Systemeinstellungen erlauben.';

/// Einstellung `kvm_erinnerung` = `{"an": true, "zeit": "19:00"}`. Das Web nutzt
/// denselben Schlüssel nur für die Uhrzeit; fehlt `an`, ist sie aus.
@immutable
class ErinnerungEinstellung {
  final bool an;
  final String zeit;
  const ErinnerungEinstellung({this.an = false, this.zeit = kErinnerungStandardZeit});

  static ErinnerungEinstellung lesen(String? raw) {
    if (raw == null || raw.isEmpty) return const ErinnerungEinstellung();
    try {
      final d = json.decode(raw);
      if (d is! Map) return const ErinnerungEinstellung();
      final z = d['zeit']?.toString();
      return ErinnerungEinstellung(an: d['an'] == true, zeit: zeitLesen(z) == null ? kErinnerungStandardZeit : z!);
    } catch (_) {
      return const ErinnerungEinstellung();
    }
  }

  String schreiben() => json.encode({'an': an, 'zeit': zeit});

  ErinnerungEinstellung mit({bool? an, String? zeit}) => ErinnerungEinstellung(an: an ?? this.an, zeit: zeit ?? this.zeit);
}

/// „19:00“ → (19, 0); ungültig → `null`.
({int stunde, int minute})? zeitLesen(String? hhmm) {
  final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(hhmm ?? '');
  if (m == null) return null;
  final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return (stunde: h, minute: min);
}

/// (19, 5) → „19:05“.
String zeitText(int stunde, int minute) =>
    '${stunde.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Auf den nächsten 5-Minuten-Schritt runden (Uhrzeitwahl in 5-min-Schritten).
String zeitAufFuenf(String hhmm) {
  final z = zeitLesen(hhmm) ?? zeitLesen(kErinnerungStandardZeit)!;
  var gesamt = ((z.stunde * 60 + z.minute) / 5).round() * 5;
  gesamt %= 24 * 60;
  return zeitText(gesamt ~/ 60, gesamt % 60);
}

/// Eine einzeln geplante Mitteilung.
@immutable
class GeplanteErinnerung {
  final int id;
  final DateTime zeit; // Ortszeit
  final String titel;
  final String text;
  const GeplanteErinnerung(this.id, this.zeit, this.titel, this.text);

  @override
  String toString() => 'GeplanteErinnerung($id, $zeit, $text)';
}

/// Plant die nächsten sieben Tage:
/// - Tag 0 (heute) nur, wenn heute noch nichts beantwortet wurde und die
///   Uhrzeit noch kommt;
/// - Tage 1–6 immer – mit Prüfungstermin aber nur bis zum Tag davor.
List<GeplanteErinnerung> erinnerungenPlanen({
  required DateTime jetzt,
  required int stunde,
  required int minute,
  required bool heuteGelernt,
  required String textHeute,
  int? pruefungTag,
}) {
  final out = <GeplanteErinnerung>[];
  for (var d = 0; d < kErinnerungIds.length; d++) {
    // Tag über den Kalender weiterzählen – so stimmt die Uhrzeit auch über
    // eine Zeitumstellung hinweg.
    final zeit = DateTime(jetzt.year, jetzt.month, jetzt.day + d, stunde, minute);
    if (d == 0 && (heuteGelernt || !zeit.isAfter(jetzt))) continue;
    if (pruefungTag != null && tagVonLokal(zeit) >= pruefungTag) continue;
    out.add(GeplanteErinnerung(kErinnerungIds[d], zeit, kErinnerungTitel, d == 0 ? textHeute : kErinnerungFolgetage));
  }
  return out;
}

/// Text für heute – die erste passende Zeile:
/// 1. Lernplan aktiv und Tagesziel > 0,
/// 2. Serie ab 2 Tagen,
/// 3. fällige Fragen,
/// 4. sonst allgemein.
String erinnerungTextHeute({
  int? planZiel,
  int? pruefungTag,
  required int serie,
  required int faellig,
  int? laufendesJahr,
}) {
  if (planZiel != null && planZiel > 0 && pruefungTag != null) {
    // „4. Nov.“ endet schon mit Punkt, „4. März“ nicht.
    final am = datumKurz(pruefungTag, laufendesJahr: laufendesJahr);
    return 'Heute dran: ${fmtN(planZiel)} ${planZiel == 1 ? 'Frage' : 'Fragen'} bis zur Prüfung am '
        '$am${am.endsWith('.') ? '' : '.'}';
  }
  if (serie >= 2) return 'Deine Serie: ${fmtN(serie)} Tage – ein paar Fragen, und sie hält.';
  if (faellig > 0) {
    return faellig == 1
        ? '1 Frage ist heute fällig – 10 Minuten reichen.'
        : '${fmtN(faellig)} Fragen sind heute fällig – 10 Minuten reichen.';
  }
  return 'Ein paar Fragen zwischendurch halten dein Wissen frisch.';
}
