import 'package:flutter/foundation.dart';

/// Kennzahlen der Original-Prüfungen (FR-014 3/4) – Schnittstelle zwischen dem
/// Paket „Prüfungen“ (liefert) und dem Paket „Cloud“ (meldet an die Rangliste
/// und in die Profil-Details).

/// Je Prüfungsbereich (RE, BW, MI, ZI, NT, FT, OK).
class PruefBereichStat {
  final String kurz; // z. B. „Recht“
  final int n; // gewertete Erstversuche
  final int ok; // davon bestanden
  final int? schnitt; // Ø Punkte, gerundet
  final double? chance; // Bestehenschance 0..1
  const PruefBereichStat({required this.kurz, required this.n, required this.ok, this.schnitt, this.chance});
}

class PruefStatistik {
  final int n; // gewertete Erstversuche gesamt
  final int ok; // davon bestanden
  final int? schnitt; // Ø Punkte, gerundet
  final double? bq; // Chance Basisqualifikationen (alle BQ-Bereiche gewertet), sonst null
  final double? hq; // Chance Handlungsspezifisch
  final double? gesamt; // beide Teile
  final double? haupt; // gesamt, sonst bq, sonst hq
  final Map<String, PruefBereichStat> bereiche;
  const PruefStatistik({
    required this.n,
    required this.ok,
    this.schnitt,
    this.bq,
    this.hq,
    this.gesamt,
    this.haupt,
    this.bereiche = const {},
  });

  static const leer = PruefStatistik(n: 0, ok: 0);
}

/// Liefert die aktuelle Statistik – setzt das Paket „Prüfungen“.
PruefStatistik Function() pruefStatistik = () => PruefStatistik.leer;

/// Wird erhöht, sobald sich Prüfungsergebnisse ändern (neu gewertet, aus der
/// Cloud übernommen) – die Cloud meldet dann neu, die Startseite zeichnet neu.
final ValueNotifier<int> pruefStand = ValueNotifier(0);
