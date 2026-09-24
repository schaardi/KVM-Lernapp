import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../services/answer_store.dart';

/// „1.125“, „1125“ und „1.125 Tsd. €“ sind dieselbe Eingabe; „9 %“ und „9“
/// auch. Tausenderpunkte ohne Nachkommastellen werden ausdrücklich erkannt –
/// sonst würde „28.800“ als 28,8 gelesen.
double? anlageZahl(String s) {
  var t = s.replaceAll(RegExp(r'[^0-9.,\-]'), '');
  if (t.contains(',') && t.contains('.')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  } else if (t.contains(',')) {
    t = t.replaceAll(',', '.');
  } else if (RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', '');
  }
  return double.tryParse(t);
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[\s.,]|€|%|tsd|std'), '');

bool anlageGleich(String soll, String eigen) {
  final a = anlageZahl(soll), b = anlageZahl(eigen);
  if (a != null && b != null) {
    final tol = a.abs() * 1e-9;
    return (a - b).abs() <= (tol > 0.005 ? tol : 0.005);
  }
  final x = _norm(soll);
  return x.isNotEmpty && x == _norm(eigen);
}

/// Tabellenanlage einer Prüfungsaufgabe – waagerecht scrollbar, damit auch
/// eine Kostenrechnung mit sechs Spalten auf ein Handy passt.
///
/// Mit [speicherKey] werden die leeren Felder zu Eingabefeldern: Eine Anlage
/// wie der Betriebsabrechnungsbogen wird in der Prüfung ausgefüllt, nicht in
/// den Antwortkasten geschrieben. Mit [loesung] zeigt die Tabelle nach dem
/// Aufdecken den amtlichen Wert und darunter die eigene Eingabe.
class AnlageTabelle extends StatefulWidget {
  final Anlage anlage;
  final String? speicherKey;
  final Anlage? loesung;
  final VoidCallback? onEingabe;
  const AnlageTabelle(this.anlage,
      {super.key, this.speicherKey, this.loesung, this.onEingabe});

  @override
  State<AnlageTabelle> createState() => _AnlageTabelleState();
}

class _AnlageTabelleState extends State<AnlageTabelle> {
  final _ctrl = <String, TextEditingController>{};

  bool get _ausfuellbar =>
      widget.speicherKey != null && widget.loesung == null && widget.anlage.hatLeere;

  TextEditingController _controller(String rc) => _ctrl.putIfAbsent(
      rc,
      () => TextEditingController(
          text: AnswerStore.instance.tabWerte(widget.speicherKey!)[rc] ?? ''));

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _feld(String rc, String label) => Semantics(
        label: label,
        child: SizedBox(
          width: 92,
          child: TextField(
            controller: _controller(rc),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.5, color: kInk),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              hintText: '–',
              hintStyle: TextStyle(fontSize: 12.5, color: kMuted),
            ),
            onChanged: (v) {
              AnswerStore.instance.setTab(widget.speicherKey!, rc, v);
              widget.onEingabe?.call();
            },
          ),
        ),
      );

  /// Zelle nach dem Aufdecken: amtlicher Wert, darunter die eigene Eingabe.
  Widget _vergleich(String soll, String eigen) {
    final s = soll.trim(), e = eigen.trim();
    if (s.isEmpty) {
      return Text(e,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, color: kMuted));
    }
    final ok = e.isNotEmpty && anlageGleich(s, e);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(s,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
      if (e.isNotEmpty)
        Text(ok ? '✓ $e' : e,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                color: ok ? const Color(0xFF127A4B) : const Color(0xFFB3261E),
                decoration: ok ? null : TextDecoration.lineThrough)),
    ]);
  }

  TableRow _zeile(List<String> zellen, {bool kopf = false, int? ri}) {
    final werte = widget.speicherKey == null
        ? const <String, String>{}
        : AnswerStore.instance.tabWerte(widget.speicherKey!);
    return TableRow(
      decoration: kopf ? const BoxDecoration(color: Color(0xFFEEF4F5)) : null,
      children: [
        for (var i = 0; i < zellen.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: _zelle(zellen, i, kopf: kopf, ri: ri, werte: werte),
          ),
      ],
    );
  }

  Widget _zelle(List<String> zellen, int i,
      {required bool kopf, int? ri, required Map<String, String> werte}) {
    final txt = zellen[i];
    if (txt.trim().isNotEmpty || kopf || ri == null || widget.speicherKey == null) {
      return Text(txt,
          textAlign: i == 0 ? TextAlign.left : TextAlign.right,
          style: TextStyle(
              fontSize: kopf ? 11.5 : 13,
              fontWeight: (kopf || i == 0) ? FontWeight.w700 : FontWeight.w400,
              color: kopf ? kPetrolDeep : kInk));
    }
    final rc = '$ri-$i';
    final sol = widget.loesung;
    if (sol != null) {
      final zeile = ri < sol.zeilen.length ? sol.zeilen[ri] : const <String>[];
      return _vergleich(i < zeile.length ? zeile[i] : '', werte[rc] ?? '');
    }
    final label = '${zellen.isNotEmpty ? zellen[0] : ''}, '
        '${i < widget.anlage.kopf.length ? widget.anlage.kopf[i] : ''}';
    return _feld(rc, label);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anlage;
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
            style: TextStyle(
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
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                if (a.kopf.isNotEmpty) _zeile(a.kopf, kopf: true),
                for (var i = 0; i < a.zeilen.length; i++)
                  _zeile(a.zeilen[i], ri: i),
              ],
            ),
          ),
        ),
        if (a.hinweis.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(a.hinweis,
              style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
        ],
        if (_ausfuellbar) ...[
          const SizedBox(height: 9),
          Text(
              'Die leeren Felder kannst du hier ausfüllen – sie werden '
              'gespeichert und beim Aufdecken mit der amtlichen Lösung verglichen.',
              style: TextStyle(
                  fontSize: 11.5, height: 1.45, color: kPetrol,
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}
