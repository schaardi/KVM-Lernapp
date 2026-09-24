import 'package:flutter/material.dart';
import '../constants.dart';
import '../screens/kw/kw_hub.dart';
import '../widgets/formula_book.dart';

/// Öffnet ein Werkzeug (Formelbuch, Rechner …) als hochziehbares Blatt.
void oeffneWerkzeug(BuildContext context, String titel, Widget inhalt) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
            child: Row(
              children: [
                Text(titel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
                const Spacer(),
                IconButton(
                    tooltip: 'Schließen',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: inhalt),
        ],
      ),
    ),
  );
}

void oeffneFormelbuch(BuildContext context) => oeffneWerkzeug(context, 'Formelbuch', const FormulaBook());

Future<void> oeffneKostenwesen(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KostenwesenScreen()));
