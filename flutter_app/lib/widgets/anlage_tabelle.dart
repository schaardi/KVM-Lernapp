import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';

/// Tabellenanlage einer Prüfungsaufgabe – waagerecht scrollbar, damit auch
/// eine Kostenrechnung mit sechs Spalten auf ein Handy passt.
///
/// Steckt in einem eigenen Widget, weil sie sowohl in der Einzelfrage
/// (`QuizScreen`) als auch im Aufgabenblatt gebraucht wird.
class AnlageTabelle extends StatelessWidget {
  final Anlage anlage;
  const AnlageTabelle(this.anlage, {super.key});

  TableRow _zeile(List<String> zellen, {bool kopf = false}) => TableRow(
        decoration: kopf ? const BoxDecoration(color: Color(0xFFEEF4F5)) : null,
        children: [
          for (var i = 0; i < zellen.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Text(zellen[i],
                  textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                  style: TextStyle(
                      fontSize: kopf ? 11.5 : 13,
                      fontWeight:
                          (kopf || i == 0) ? FontWeight.w700 : FontWeight.w400,
                      color: kopf ? kPetrolDeep : kInk)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final a = anlage;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFD),
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.titel.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: kPetrol)),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 420),
            child: Table(
              border: TableBorder.all(color: kLine),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                if (a.kopf.isNotEmpty) _zeile(a.kopf, kopf: true),
                for (final r in a.zeilen) _zeile(r),
              ],
            ),
          ),
        ),
        if (a.hinweis.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(a.hinweis,
              style: const TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
        ],
      ]),
    );
  }
}
