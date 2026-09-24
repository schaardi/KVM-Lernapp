import 'package:flutter/material.dart';

/// Knopf „Fehler?“ (FR-008, FR-013): meldet einen Fehler zu einer Frage oder
/// Teilaufgabe über `meldung_senden` (docs/supabase-meldungen.sql).
///
/// Schnittstelle für Quiz, Aufgabenblatt und Mündlich:
/// - [frageId]: ID der Frage bzw. Teilaufgabe (z. B. `P-NT-20150429-s3`)
/// - [bezug]: kurze Anzeige im Dialog, z. B. „Aufgabe 2 b)“ oder der Fragetext
/// - [kontext]: Zusatzinfos wie im Web, z. B. `{'modus': 'scrBlatt'}`
/// - [kompakt]: nur Symbol (in engen Köpfen)
///
/// Die Umsetzung folgt im Paket „Werkzeuge“; bis dahin ist der Knopf unsichtbar.
class MeldenKnopf extends StatelessWidget {
  final String frageId;
  final String bezug;
  final Map<String, dynamic> kontext;
  final bool kompakt;
  const MeldenKnopf({
    super.key,
    required this.frageId,
    required this.bezug,
    this.kontext = const {},
    this.kompakt = false,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Öffnet den Melde-Dialog direkt (z. B. aus einem Menü).
Future<void> oeffneMelden(BuildContext context,
    {required String frageId, required String bezug, Map<String, dynamic> kontext = const {}}) async {}
