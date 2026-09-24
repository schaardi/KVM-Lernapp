import 'package:flutter/material.dart';
import '../constants.dart';
import '../werkzeuge/melden_dialog.dart';
import '../werkzeuge/melden_dienst.dart';

/// Knopf „Fehler?“ (FR-008, FR-013): meldet einen Fehler zu einer Frage oder
/// Teilaufgabe über `meldung_senden` (docs/supabase-meldungen.sql).
///
/// Schnittstelle für Quiz, Aufgabenblatt und Mündlich:
/// - [frageId]: ID der Frage bzw. Teilaufgabe (z. B. `P-NT-20150429-s3`)
/// - [bezug]: kurze Anzeige im Dialog, z. B. „Aufgabe 2 b)“ oder der Fragetext
/// - [kontext]: Zusatzinfos wie im Web, z. B. `{'modus': 'scrBlatt'}`
/// - [kompakt]: nur Symbol (in engen Köpfen)
///
/// Unauffällig: Fähnchen und „Fehler?“ in `kMuted`, ohne Rahmen; schon
/// gemeldet „Gemeldet ✓“ in `kOkInk`. Sichtbar erst, wenn
/// `meldungen_bereit()` antwortet (Start bzw. Anmeldung, siehe
/// `initWerkzeuge`). Fach, Bereich und Auszug für den Kontext sucht der
/// Dialog selbst zur [frageId]; `modus` ist `quiz` oder `blatt`.
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
  Widget build(BuildContext context) {
    final dienst = MeldenDienst.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([dienst.bereit, dienst]),
      builder: (context, _) {
        if (!dienst.bereit.value) return const SizedBox.shrink();
        final gemeldet = dienst.istGemeldet(frageId);
        final farbe = gemeldet ? kOkInk : kMuted;
        final text = gemeldet ? 'Gemeldet ✓' : 'Fehler?';
        final titel = MeldenDienst.istTeilaufgabe(frageId)
            ? 'Fehler in dieser Teilaufgabe melden'
            : 'Fehler in dieser Frage melden';
        return Semantics(
          button: true,
          label: text,
          hint: titel,
          excludeSemantics: true,
          child: Tooltip(
            message: titel,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => oeffneMelden(context, frageId: frageId, bezug: bezug, kontext: kontext),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 32, minWidth: kompakt ? 32 : 0),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: kompakt ? 6 : 2, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.outlined_flag, size: kompakt ? 16 : 14, color: farbe),
                    if (!kompakt) ...[
                      const SizedBox(width: 5),
                      Text(text,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                              height: 1.2,
                              color: farbe)),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Öffnet den Melde-Dialog direkt (z. B. aus einem Menü): auf dem Handy als
/// Blatt von unten, breit als Dialog (480 breit).
Future<void> oeffneMelden(BuildContext context,
    {required String frageId, required String bezug, Map<String, dynamic> kontext = const {}}) {
  return zeigeMeldenDialog(context, frageId: frageId, bezug: bezug, kontext: kontext);
}
