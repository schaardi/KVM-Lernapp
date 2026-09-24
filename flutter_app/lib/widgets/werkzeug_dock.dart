import 'package:flutter/material.dart';
import '../constants.dart';
import 'calculator.dart';
import 'drawing_pad.dart';
import 'formula_book.dart';

/// Werkzeug-Dock in Quiz und Aufgabenblatt (FR-002 C): Rechner, Rechenblatt,
/// Formelbuch – im Quiz zusätzlich „Sprache“.
///
/// Schnittstelle für Quiz und Aufgabenblatt:
/// - [onUebernehmen] übernimmt einen Text (Rechner-Ergebnis, Formelvorlage)
///   in das gerade aktive Antwortfeld; `null` = kein Antwortfeld offen.
/// - [onSprache] schaltet Vorlesen/Spracheingabe; `null` blendet den Knopf aus.
class WerkzeugDock extends StatelessWidget {
  final void Function(String text)? onUebernehmen;
  final VoidCallback? onSprache;
  final bool spracheAktiv;
  const WerkzeugDock({super.key, this.onUebernehmen, this.onSprache, this.spracheAktiv = false});

  @override
  Widget build(BuildContext context) {
    Widget knopf(IconData icon, String label, VoidCallback onTap, {bool aktiv = false}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 21, color: aktiv ? kVioletInk : kPetrolInk),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: aktiv ? kVioletInk : kInkSoft)),
              ]),
            ),
          ),
        );
    return Material(
      color: kPaper,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: kLine))),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: SafeArea(
          top: false,
          child: Row(children: [
            knopf(Icons.calculate_outlined, 'Rechner', () => oeffneRechner(context, onUebernehmen: onUebernehmen)),
            knopf(Icons.edit_outlined, 'Rechenblatt', () => oeffneRechenblatt(context)),
            knopf(Icons.auto_stories_outlined, 'Formelbuch', () => oeffneFormelbuchBlatt(context, onUebernehmen: onUebernehmen)),
            if (onSprache != null) knopf(Icons.mic_none, 'Sprache', onSprache!, aktiv: spracheAktiv),
          ]),
        ),
      ),
    );
  }
}

/// Rechner als Blatt; „Übernehmen“ (FR-005 D) ruft [onUebernehmen].
Future<void> oeffneRechner(BuildContext context, {void Function(String text)? onUebernehmen}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const SizedBox(height: 460, child: CalculatorSheet()),
      ),
    ),
  );
}

/// Rechenblatt (Zeichenfläche) als Blatt.
Future<void> oeffneRechenblatt(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text('Rechenblatt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kInk)),
            ]),
          ),
          const Expanded(child: DrawingPad()),
        ]),
      ),
    ),
  );
}

/// Formelbuch als Blatt; eine Formelvorlage kann ins Antwortfeld wandern.
Future<void> oeffneFormelbuchBlatt(BuildContext context, {void Function(String text)? onUebernehmen}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: const FormulaBook(),
      ),
    ),
  );
}
