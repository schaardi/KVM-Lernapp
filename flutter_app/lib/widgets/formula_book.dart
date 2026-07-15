import 'package:flutter/material.dart';
import '../constants.dart';
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
            children: [
              for (final g in groups)
                ...(() {
                  final items = g.items.where((it) {
                    if (q.isEmpty) return true;
                    return ('${it.name} ${it.eq} ${it.note ?? ''} ${g.group}')
                        .toLowerCase()
                        .contains(q);
                  }).toList();
                  if (items.isEmpty) return <Widget>[];
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 6),
                      child: Text(g.group.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: kMuted)),
                    ),
                    for (final it in items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
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
                                    style: const TextStyle(
                                        fontSize: 12, color: kMuted)),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ];
                })(),
            ],
          ),
        ),
      ],
    );
  }
}
