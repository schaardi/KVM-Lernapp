import 'package:flutter/material.dart';
import '../screens/gefahrgut_screen.dart';

/// Kachel „Gefahrgut“: ADR-Klassen, Quiz und Warntafel (Web `#mADR`).
Future<void> oeffneGefahrgut(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GefahrgutScreen()));
