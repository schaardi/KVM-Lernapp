import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/data_service.dart';

/// Durchsuchbares Formelbuch.
class FormulaBook extends StatefulWidget {
  const FormulaBook({super.key});
  @override
  State<FormulaBook> createState() => _FormulaBookState();
}

class _FormulaBookState extends State<FormulaBook> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final groups = DataService.instance.formulas;
    final q = _q.trim().toLowerCase();

    final tiles = <Widget>[];
    var shown = 0;
    for (final g in groups) {
      final items = g.items.where((it) {
        if (q.isEmpty) return true;
        return ('${it.name} ${it.eq} ${it.note ?? ''} ${g.group}')
            .toLowerCase()
            .contains(q);
      }).toList();
      if (items.isEmpty) continue;
      final first = shown == 0;
      shown++;
      tiles.add(_groupTile(g.group, items,
          // Beim Suchen alle Treffer offen, sonst nur die erste Gruppe.
          expanded: q.isNotEmpty || first,
          searching: q.isNotEmpty));
    }
    if (tiles.isEmpty) {
      tiles.add(const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('Keine Formel gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14)),
      ));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Formel suchen (z. B. Deckungsbeitrag, Zins) …',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _groupTile(String group, List<FormulaItem> items,
      {required bool expanded, required bool searching}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Standard-Divider der ExpansionTile ausblenden.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Key wechselt mit dem Suchzustand, damit initiallyExpanded neu greift.
          key: PageStorageKey('$group|$searching'),
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 8),
          title: Row(children: [
            Expanded(
              child: Text(group.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: kPetrolDeep)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: kPetrolSoft, borderRadius: BorderRadius.circular(10)),
              child: Text('${items.length}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kPetrolDeep)),
            ),
          ]),
          children: [
            for (final it in items)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: kPaper,
                  border: Border.all(color: kLine),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: kPetrolSoft,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(it.eq,
                          style: const TextStyle(
                              fontFamily: 'monospace', color: kPetrolDeep)),
                    ),
                    if (it.note != null) ...[
                      const SizedBox(height: 5),
                      Text(it.note!,
                          style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
