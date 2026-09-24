import 'dart:math' as math;
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
///
/// [onVorlage] nimmt eine Vorlage für das Antwortfeld der offenen
/// Teilaufgabe entgegen (FR-002 C.4). Gibt der Callback als
/// `String? Function(String)` das Ziel zurück („Aufgabe 1 a)“), steht es im
/// Hinweis. Ohne Callback (Startseite) landet die Vorlage in der
/// Zwischenablage.
class FormulaBook extends StatefulWidget {
  final void Function(String text)? onVorlage;
  const FormulaBook({super.key, this.onVorlage});
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

/// Weiche Trennstellen (U+00AD) an den Fugen typischer Kostenbegriffe
/// (FR-002 H, Web `weich()`): „Fertigungs·gemein·kosten“ bricht auf schmalen
/// Handys mit Bindestrich statt mitten im Wort. Nur fürs Anzeigen – Vorlagen
/// und Zwischenablage nutzen den Originaltext.
final RegExp _fuge = RegExp(r'(Material|Fertigungs|Verwaltungs|Vertriebs|Sonder|einzel|'
    r'gemein|Herstell|Selbst|Listen|verkaufs|Bezugs|Einstands|Kunden)(?=[a-zäöüß]{4,})');
String weich(String s) => s.replaceAllMapped(_fuge, (m) => '${m[1]}­');

enum _HinweisArt { normal, ok, warnung }

/// Zahlenfeld im Kalkulationsschema – wie `NumField`, aber mit wählbarem
/// Innenabstand: Im 58 breiten Prozentfeld muss „210 %“ Platz haben.
class _Zahlfeld extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? suffix;
  final String hint;
  final Color? hintColor;
  final double width;
  final double innen;
  const _Zahlfeld({
    required this.controller,
    required this.onChanged,
    required this.hint,
    required this.width,
    this.suffix,
    this.hintColor,
    this.innen = 8,
  });

  @override
  Widget build(BuildContext context) {
    final rand = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kLine),
    );
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: hintColor ?? kMuted, fontWeight: FontWeight.w400),
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 11.5, color: kMuted),
          contentPadding: EdgeInsets.symmetric(horizontal: innen, vertical: 8),
          filled: true,
          fillColor: kBgTint.withValues(alpha: 0.55),
          border: rand,
          enabledBorder: rand,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: kPetrol, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _FormulaBookState extends State<FormulaBook> {
  String _q = '';
  final Map<String, TextEditingController> _ctl = {};

  /// Rückmeldung nach „Vorlage ins Antwortfeld“ je Karte – bis zur nächsten
  /// Eingabe (wie im Web, wo der Hinweis dann neu berechnet wird).
  final Map<String, (String, _HinweisArt)> _meldung = {};

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

  void _eingabe() => setState(_meldung.clear);

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
      tiles.add(Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text('Keine Formel gefunden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14)),
      ));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Formel suchen (z. B. Deckungsbeitrag, Bestellmenge, Zins) …',
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
                  style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: kPetrolInkDeep)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: kPetrolSoft, borderRadius: BorderRadius.circular(10)),
              child: Text('${items.length + schemas.length}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: kPetrolInkDeep)),
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
              style: TextStyle(fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kPetrolSoft, borderRadius: BorderRadius.circular(6)),
            child: Text(it.eq,
                style: TextStyle(
                    fontFamily: 'IBMPlexMono', color: kPetrolInkDeep)),
          ),
          if (it.computable) ..._rechner(group, it),
          if (it.note != null) ...[
            const SizedBox(height: 5),
            Text(it.note!,
                style: TextStyle(fontSize: 12, color: kMuted)),
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

    final karte = 'f|$group|${it.name}';
    return [
      const SizedBox(height: 8),
      for (final vr in it.vars)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          // Auf schmalen Handys (360 dp) darf das Feld nicht aus der Karte
          // ragen: höchstens 124 breit, sonst so viel, wie neben der
          // Beschriftung Platz ist (FR-002 H.3).
          child: LayoutBuilder(builder: (context, box) {
            final feld = math.min(124.0, math.max(72.0, (box.maxWidth - 8) * 0.55));
            return Row(children: [
              Expanded(
                child: Text(vr.n,
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ),
              const SizedBox(width: 8),
              NumField(
                controller: _c('$group|${it.name}|${vr.k}'),
                onChanged: _eingabe,
                suffix: vr.u.isEmpty ? null : vr.u,
                hint: '—',
                width: feld,
              ),
            ]);
          }),
        ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: kPetrolSoft, borderRadius: BorderRadius.circular(7)),
        child: Row(children: [
          Expanded(
            child: Text('= ${it.resultName}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kPetrolInkDeep)),
          ),
          Text(ergebnis,
              style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: fehlt ? 12.5 : 16,
                  fontWeight: fehlt ? FontWeight.w600 : FontWeight.w800,
                  color: fehlt ? kMuted : kPetrolInkDeep)),
        ]),
      ),
      if (weg.isNotEmpty) ...[
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(weg,
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', fontSize: 11.5, color: kMuted)),
        ),
      ],
      const SizedBox(height: 8),
      _fuss(karte, [
        _vorlageButton(() => _vorlage(karte, _formelText(group, it))),
      ], null),
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

    final karte = 'ks|${s.id}';
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
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14.5, color: kInk)),
        const SizedBox(height: 3),
        Text(s.note,
            style: TextStyle(fontSize: 12, height: 1.45, color: kMuted)),
        const SizedBox(height: 9),
        for (final r in s.rows) _schemaRow(s, r, out),
        const SizedBox(height: 9),
        _fuss(
          karte,
          [
            _kleinButton('Beispiel', () => _fuellen(s, _beispiele[s.id])),
            _kleinButton('Leeren', () => _fuellen(s, null)),
            _vorlageButton(() => _vorlage(karte, _schemaText(s, out))),
          ],
          (hinweis, warnt ? _HinweisArt.warnung : _HinweisArt.normal),
        ),
      ]),
    );
  }

  Widget _schemaRow(CalcSchema s, Map<String, dynamic> r, SchemaResult? out) {
    final k = r['k'] as String;
    final t = r['t'] as String;
    final istSumme = t == 'sum';
    final istUnbekannt = out?.unbekannt == k;
    final berechnet = out == null ? null : out.werte[k];
    // Schmale Handys (FR-002 H.1): Prozentfeld 58 statt 70, Wertfeld 92 statt
    // 104, Abstand 5; die Beschriftung bricht um.
    final schmal = MediaQuery.sizeOf(context).width < 400;
    final pBreite = schmal ? 58.0 : 70.0;
    final vBreite = schmal ? 92.0 : 104.0;
    final abstand = schmal ? 5.0 : 6.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: istUnbekannt
            ? kAmberSoft
            : (istSumme ? kBgTint.withValues(alpha: 0.5) : null),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Text(weich(r['n'].toString()),
              style: TextStyle(
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: istSumme ? FontWeight.w700 : FontWeight.w400,
                  color: kInk)),
        ),
        // Auf schmalen Handys nutzt eine Zeile ohne Satz die Prozentspalte für
        // die Beschriftung („= Zieleinkaufspreis“ in einer Zeile).
        if (!schmal || t == 'pct' || t == 'ih') ...[
        SizedBox(width: abstand),
        SizedBox(
          width: pBreite,
          child: (t == 'pct' || t == 'ih')
              ? _Zahlfeld(
                  controller: _c('ks|${s.id}|$k|p'),
                  onChanged: _eingabe,
                  suffix: '%',
                  hint: '${(r['rd'] as num?)?.toInt() ?? 0}',
                  width: pBreite,
                  innen: schmal ? 5 : 8,
                )
              : const SizedBox.shrink(),
        ),
        ],
        SizedBox(width: abstand),
        _Zahlfeld(
          controller: _c('ks|${s.id}|$k|v'),
          onChanged: _eingabe,
          // Solange das Feld leer ist, steht im Hinweis der errechnete Betrag –
          // in Petrol, damit er sich von einer bloßen Vorbelegung abhebt.
          hint: berechnet == null ? '' : fmtNum(berechnet),
          hintColor: kPetrolInkDeep,
          width: vBreite,
          innen: schmal ? 6 : 8,
        ),
      ]),
    );
  }

  /// Knöpfe und Hinweis unter einer Karte (Web `.ks-foot`). Nach „Vorlage ins
  /// Antwortfeld“ steht dort die Rückmeldung.
  Widget _fuss(String karte, List<Widget> knoepfe, (String, _HinweisArt)? hinweis) {
    final zeige = _meldung[karte] ?? hinweis;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 7, runSpacing: 7, children: knoepfe),
      if (zeige != null) ...[
        const SizedBox(height: 7),
        Text(zeige.$1,
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontWeight: zeige.$2 == _HinweisArt.ok ? FontWeight.w600 : FontWeight.w400,
                color: switch (zeige.$2) {
                  _HinweisArt.ok => kPetrolInkDeep,
                  _HinweisArt.warnung => kErrInk,
                  _HinweisArt.normal => kMuted,
                })),
      ],
    ]);
  }

  /// Kalkulationsschema als Vorlage: jede Zeile untereinander, wie man sie in
  /// der Prüfung schreibt. Ausgefüllt wird im Antwortfeld – dort stehen die
  /// Zahlen der Aufgabe daneben. Steht hier schon ein Betrag, kommen die
  /// gerechneten Werte mit; ein unberührtes Schema rechnet lauter Nullen aus,
  /// deshalb bleiben die Zeilen dann leer.
  String _schemaText(CalcSchema s, SchemaResult? out) {
    final eigene = s.rows.any((r) {
      final k = r['k'] as String;
      return _val('ks|${s.id}|$k|v') != null;
    });
    final zeilen = <String>[s.name];
    for (final r in s.rows) {
      final k = r['k'] as String;
      var satz = '';
      final t = r['t'] as String;
      if (t == 'pct' || t == 'ih') {
        final p = _val('ks|${s.id}|$k|p') ??
            (r['rd'] is num ? (r['rd'] as num).toDouble() : null);
        if (p != null) satz = ' (${fmtNum(p, dec: 2)} %)';
      }
      final v = eigene ? out?.werte[k] : null;
      final wert = (v != null && v.isFinite) ? fmtNum(v, dec: 2) : '';
      final name = r['n'] as String;
      zeilen.add('$name$satz: $wert');
    }
    return zeilen.join('\n');
  }

  /// Einzelformel als Vorlage: Gleichung, darunter je eine Zeile für ihre
  /// Größen und eine für das Ergebnis.
  String _formelText(String group, FormulaItem it) {
    final zeilen = <String>[it.name, it.eq];
    for (final vr in it.vars) {
      final x = _c('$group|${it.name}|${vr.k}').text.trim();
      zeilen.add('${vr.n}${vr.u.isEmpty ? '' : ' in ${vr.u}'}: $x');
    }
    if (it.resultName.isNotEmpty) {
      zeilen.add('= ${it.resultName}'
          '${it.resultUnit.isEmpty ? '' : ' in ${it.resultUnit}'}: ');
    }
    return zeilen.join('\n');
  }

  /// „Vorlage ins Antwortfeld“ (Web `fbUebernahme`): mit offenem Antwortfeld
  /// (Quiz, Aufgabenblatt) dorthin, sonst – etwa von der Startseite aus – in
  /// die Zwischenablage.
  void _vorlage(String karte, String txt) {
    if (txt.isEmpty) {
      setState(() => _meldung[karte] =
          ('Diese Formel lässt sich nicht als Vorlage übernehmen.', _HinweisArt.warnung));
      return;
    }
    final ziel = widget.onVorlage;
    if (ziel != null) {
      String? name;
      if (ziel is String? Function(String)) {
        name = ziel(txt);
      } else {
        ziel(txt);
      }
      setState(() => _meldung[karte] = (
            name != null && name.trim().isNotEmpty
                ? 'Als Vorlage in die Antwort zu ${name.trim()} übernommen – dort ausfüllen.'
                : 'Als Vorlage in deine Antwort übernommen – dort ausfüllen.',
            _HinweisArt.ok
          ));
      return;
    }
    Clipboard.setData(ClipboardData(text: txt));
    setState(() => _meldung[karte] =
        ('Keine Prüfung offen – die Vorlage liegt jetzt in der Zwischenablage.', _HinweisArt.normal));
  }

  Widget _vorlageButton(VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kPetrolInkDeep,
          side: BorderSide(color: kPetrol),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12),
        ),
        child: const Text('Vorlage ins Antwortfeld'),
      );

  Widget _kleinButton(String text, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: kPetrolInk,
          side: BorderSide(color: kLine),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12),
        ),
        child: Text(text),
      );

  void _fuellen(CalcSchema s, Map<String, String>? werte) {
    setState(() {
      _meldung.clear();
      for (final r in s.rows) {
        final k = r['k'] as String;
        _c('ks|${s.id}|$k|v').text = werte?['$k|v'] ?? '';
        _c('ks|${s.id}|$k|p').text = werte?['$k|p'] ?? '';
      }
    });
  }
}
