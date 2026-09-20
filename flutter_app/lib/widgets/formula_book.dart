import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../models.dart';
import '../services/data_service.dart';
import '../services/formula_calc.dart';
import 'calc_kit.dart';

/// Durchsuchbares Formelbuch: Kalkulationsschemas zum Ausfüllen und Formeln,
/// die mit eigenen Zahlen rechnen. Inhalte und Rechenwege stammen aus
/// assets/data/formulas.json – dieselbe Quelle wie in der Web-App.
class FormulaBook extends StatefulWidget {
  const FormulaBook({super.key});
  @override
  State<FormulaBook> createState() => _FormulaBookState();
}

/// Beispielwerte je Schema – „Beispiel“ füllt einen kompletten Fall.
const Map<String, Map<String, String>> _beispiele = {
  'zuschlag': {
    'FEK|v': '3.900', 'SEF|v': '510', 'SEV|v': '455', 'LVP|v': '21.340',
    'MGK|p': '25', 'FGK|p': '210', 'VwGK|p': '15', 'VtGK|p': '5', 'GEW|p': '10',
  },
  'einkauf': {
    'LEP|v': '2.500', 'LRA|p': '20', 'LSK|p': '3', 'BZK|v': '120',
  },
  'verkauf': {
    'BP|v': '58,50', 'HKO|p': '40', 'GEW|p': '15',
    'SKO|p': '2', 'PRO|p': '5', 'RAB|p': '25',
  },
};

/// Zahl für den Rechenweg: bis zu vier Nachkommastellen, ohne Nullen am Ende.
String _fmtKurz(double x) {
  if (x.isNaN || x.isInfinite) return '–';
  var s = fmtNum(x, dec: 4);
  if (s.contains(',')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r',$'), '');
  }
  return s;
}

class _FormulaBookState extends State<FormulaBook> {
  String _q = '';
  final Map<String, TextEditingController> _ctl = {};

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String key, {String? initial}) =>
      _ctl.putIfAbsent(key, () => TextEditingController(text: initial ?? ''));

  double? _val(String key) => parseDe(_c(key).text);

  @override
  Widget build(BuildContext context) {
    final groups = DataService.instance.formulas;
    final q = _q.trim().toLowerCase();

    final tiles = <Widget>[];
    var shown = 0;
    for (final g in groups) {
      final items = g.items
          .where((it) =>
              q.isEmpty || '${it.haystack} ${g.group}'.toLowerCase().contains(q))
          .toList();
      final schemas = g.schemas
          .where((s) =>
              q.isEmpty || '${s.haystack} ${g.group}'.toLowerCase().contains(q))
          .toList();
      if (items.isEmpty && schemas.isEmpty) continue;
      final first = shown == 0;
      shown++;
      tiles.add(_groupTile(g.group, items, schemas,
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
              hintText: 'Formel suchen (z. B. Selbstkosten, Akkord, Zins) …',
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
      List<CalcSchema> schemas,
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
          maintainState: true,
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
              child: Text('${items.length + schemas.length}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kPetrolDeep)),
            ),
          ]),
          children: [
            for (final s in schemas) _schemaCard(s),
            for (final it in items) _formulaCard(group, it),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── Formelkarte ────────────────────────────────
  Widget _formulaCard(String group, FormulaItem it) {
    return Container(
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
              style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kPetrolSoft, borderRadius: BorderRadius.circular(6)),
            child: Text(it.eq,
                style: const TextStyle(
                    fontFamily: 'monospace', color: kPetrolDeep)),
          ),
          if (it.computable) ..._rechner(group, it),
          if (it.note != null) ...[
            const SizedBox(height: 5),
            Text(it.note!,
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ],
      ),
    );
  }

  List<Widget> _rechner(String group, FormulaItem it) {
    final vals = <String, double>{};
    var fehlt = false;
    for (final vr in it.vars) {
      final key = '$group|${it.name}|${vr.k}';
      if (!_ctl.containsKey(key) && vr.d != null) {
        _c(key, initial: _fmtKurz(vr.d!));
      }
      final x = _val(key);
      if (x == null) {
        fehlt = true;
      } else {
        vals[vr.k] = x;
      }
    }

    String ergebnis, weg;
    if (fehlt) {
      ergebnis = 'Werte eintragen';
      weg = '';
    } else {
      try {
        final y = evalFormula(it.expr!, vals);
        final einheit = it.resultUnit.isEmpty ? '' : ' ${it.resultUnit}';
        ergebnis = '${fmtNum(y, dec: it.dec)}$einheit';
        weg = '${traceFormula(it.expr!, vals, _fmtKurz)} = '
            '${fmtNum(y, dec: it.dec)}$einheit';
      } on FormulaError catch (e) {
        ergebnis = '—';
        weg = e.message;
      }
    }

    return [
      const SizedBox(height: 8),
      for (final vr in it.vars)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(
              child: Text(vr.n,
                  style: const TextStyle(fontSize: 12, color: kMuted)),
            ),
            const SizedBox(width: 8),
            NumField(
              controller: _c('$group|${it.name}|${vr.k}'),
              onChanged: () => setState(() {}),
              suffix: vr.u.isEmpty ? null : vr.u,
              hint: '—',
              width: 124,
            ),
          ]),
        ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: kPetrolSoft, borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          Expanded(
            child: Text('= ${it.resultName}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolDeep)),
          ),
          Text(ergebnis,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: fehlt ? 12.5 : 16,
                  fontWeight: fehlt ? FontWeight.w600 : FontWeight.w800,
                  color: fehlt ? kMuted : kPetrolDeep)),
        ]),
      ),
      if (weg.isNotEmpty) ...[
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(weg,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 11.5, color: kMuted)),
        ),
      ],
    ];
  }

  // ──────────────────────────── Kalkulationsschema ──────────────────────────
  Widget _schemaCard(CalcSchema s) {
    final eingaben = <String, double>{};
    final saetze = <String, double>{};
    for (final r in s.rows) {
      final k = r['k'] as String;
      final betrag = _val('ks|${s.id}|$k|v');
      if (betrag != null) eingaben[k] = betrag;
      final satz = _val('ks|${s.id}|$k|p');
      if (satz != null) saetze[k] = satz;
    }

    SchemaResult? ergebnis;
    String? fehler;
    try {
      ergebnis = solveSchema(s.rows, eingaben, saetze);
    } on FormulaError catch (e) {
      fehler = e.message;
    }
    final out = ergebnis;

    final String hinweis;
    final bool warnt;
    if (fehler != null || out == null) {
      hinweis = fehler ?? 'Das Schema lässt sich mit diesen Angaben nicht lösen.';
      warnt = true;
    } else if (out.hinweis != null) {
      hinweis = out.hinweis!;
      warnt = true;
    } else {
      warnt = false;
      final offen = out.unbekannt;
      if (offen != null) {
        final z = s.rows.firstWhere((r) => r['k'] == offen);
        hinweis = 'Rückwärts gerechnet: ${z['n']} ergibt sich aus deiner Vorgabe.';
      } else {
        hinweis = 'Graue Zahlen sind berechnet. Tippe einen Betrag in eine '
            '„=“-Zeile und lass dafür eine Kostenzeile frei, dann rechnet das '
            'Schema rückwärts.';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 9),
      decoration: BoxDecoration(
        color: kPaper,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14.5, color: kInk)),
        const SizedBox(height: 3),
        Text(s.note,
            style: const TextStyle(fontSize: 12, height: 1.45, color: kMuted)),
        const SizedBox(height: 9),
        for (final r in s.rows) _schemaRow(s, r, out),
        const SizedBox(height: 9),
        Row(children: [
          _kleinButton('Beispiel', () => _fuellen(s, _beispiele[s.id])),
          const SizedBox(width: 7),
          _kleinButton('Leeren', () => _fuellen(s, null)),
          const SizedBox(width: 7),
          _kleinButton('Kopieren', () => _kopieren(s, out)),
        ]),
        const SizedBox(height: 7),
        Text(hinweis,
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: warnt ? kErr : kMuted)),
      ]),
    );
  }

  Widget _schemaRow(CalcSchema s, Map<String, dynamic> r, SchemaResult? out) {
    final k = r['k'] as String;
    final t = r['t'] as String;
    final istSumme = t == 'sum';
    final istUnbekannt = out?.unbekannt == k;
    final berechnet = out == null ? null : out.werte[k];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: istUnbekannt
            ? kAmber.withValues(alpha: 0.14)
            : (istSumme ? kBgTint.withValues(alpha: 0.5) : null),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Text(r['n'].toString(),
              style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: istSumme ? FontWeight.w700 : FontWeight.w400,
                  color: kInk)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: (t == 'pct' || t == 'ih')
              ? NumField(
                  controller: _c('ks|${s.id}|$k|p'),
                  onChanged: () => setState(() {}),
                  suffix: '%',
                  hint: '${(r['rd'] as num?)?.toInt() ?? 0}',
                  width: 70,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
        NumField(
          controller: _c('ks|${s.id}|$k|v'),
          onChanged: () => setState(() {}),
          // Solange das Feld leer ist, steht im Hinweis der errechnete Betrag –
          // in Petrol, damit er sich von einer bloßen Vorbelegung abhebt.
          hint: berechnet == null ? '' : fmtNum(berechnet),
          hintColor: kPetrolDeep,
          width: 104,
        ),
      ]),
    );
  }

  /// Ausgefülltes Schema als Text – so, wie man es in der Prüfung
  /// untereinander schreiben würde. Ein unberührtes Schema rechnet lauter
  /// Nullen aus; das ist kein Rechenweg und wird nicht kopiert.
  String _schemaText(CalcSchema s, SchemaResult? out) {
    if (out == null) return '';
    final eigene = s.rows.any((r) {
      final k = r['k'] as String;
      return _val('ks|${s.id}|$k|v') != null;
    });
    if (!eigene) return '';
    final zeilen = <String>[s.name];
    for (final r in s.rows) {
      final k = r['k'] as String;
      final v = out.werte[k];
      if (v == null || !v.isFinite) continue;
      var satz = '';
      final t = r['t'] as String;
      if (t == 'pct' || t == 'ih') {
        final p = _val('ks|${s.id}|$k|p') ??
            (r['rd'] is num ? (r['rd'] as num).toDouble() : null);
        if (p != null) satz = ' (${fmtNum(p, dec: 2)} %)';
      }
      final name = r['n'] as String;
      zeilen.add('$name$satz: ${fmtNum(v, dec: 2)}');
    }
    return zeilen.length > 1 ? zeilen.join('\n') : '';
  }

  /// Der Rechenweg wandert in die Zwischenablage: In der App wird das
  /// Formelbuch von der Startseite geöffnet, nicht über einer laufenden
  /// Prüfung – von dort lässt er sich in das Antwortfeld einfügen.
  void _kopieren(CalcSchema s, SchemaResult? out) {
    final txt = _schemaText(s, out);
    final bote = ScaffoldMessenger.maybeOf(context);
    if (txt.isEmpty) {
      bote?.showSnackBar(const SnackBar(
          content: Text('Erst Werte eintragen – dann lässt sich der '
              'Rechenweg kopieren.')));
      return;
    }
    Clipboard.setData(ClipboardData(text: txt));
    bote?.showSnackBar(const SnackBar(
        content: Text('Rechenweg kopiert – im Aufgabenblatt in das '
            'Antwortfeld einfügen.')));
  }

  Widget _kleinButton(String text, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kPetrol,
          side: const BorderSide(color: kLine),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      );

  void _fuellen(CalcSchema s, Map<String, String>? werte) {
    setState(() {
      for (final r in s.rows) {
        final k = r['k'] as String;
        _c('ks|${s.id}|$k|v').text = werte?['$k|v'] ?? '';
        _c('ks|${s.id}|$k|p').text = werte?['$k|p'] ?? '';
      }
    });
  }
}
