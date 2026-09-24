import 'package:flutter/material.dart';
import '../../widgets/ui.dart';
import '../pruefungen_screen.dart';

/// Prüfungen (FR-015 3): die Liste der Original-IHK-Prüfungen als Seite statt
/// als eigener Bildschirm.
class PruefungenSeite extends StatelessWidget {
  const PruefungenSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return const PruefungenListe(
      kopf: SeitenTitel('Original-IHK-Prüfungen'),
    );
  }
}
