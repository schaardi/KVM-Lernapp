import 'package:flutter/material.dart';

/// Kachel „Gefahrgut“: ADR-Klassen, Quiz und Warntafel (Web `#mADR`).
/// Die Umsetzung folgt im Paket „Werkzeuge“.
Future<void> oeffneGefahrgut(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Gefahrgut (ADR) kommt mit dem nächsten Update.')));
}
