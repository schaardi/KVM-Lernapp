import 'package:flutter/material.dart';
import '../screens/kw/kw_hub.dart';
import '../werkzeuge/blatt.dart';
import '../widgets/werkzeug_dock.dart';

/// Öffnet ein Werkzeug als hochziehbares Blatt mit Kopf und ✕.
void oeffneWerkzeug(BuildContext context, String titel, Widget inhalt) {
  zeigeWerkzeugBlatt<void>(context, titel: titel, inhalt: inhalt);
}

/// Kachel „Formelbuch“ (Startseite): ohne offene Prüfung wandern Vorlagen in
/// die Zwischenablage.
void oeffneFormelbuch(BuildContext context) => oeffneFormelbuchBlatt(context);

Future<void> oeffneKostenwesen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KostenwesenScreen()));
