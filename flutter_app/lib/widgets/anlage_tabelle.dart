import 'package:flutter/material.dart';
import '../constants.dart';
import '../models.dart';
import '../pruefung/pruef_ui.dart';
import '../services/answer_store.dart';
import 'ui.dart';

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

/// Wie im Web (`tabNorm`): ohne Leerraum, Punkte, Kommas, €, %, „Tsd.“,
/// „Std.“ und ein „h“ am Ende.
String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s.,]|€|%|tsd|std|h$'), '');

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
/// Aufdecken den amtlichen Wert und darunter die eigene Eingabe. [onFokus]
/// meldet das aktive Feld (Ziel für „Übernehmen“ aus dem Rechner).
class AnlageTabelle extends StatefulWidget {
  final Anlage anlage;
  final String? speicherKey;
  final Anlage? loesung;
  final VoidCallback? onEingabe;
  final ValueChanged<AktivesFeld>? onFokus;
  const AnlageTabelle(this.anlage, {super.key, this.speicherKey, this.loesung, this.onEingabe, this.onFokus});

  @override
  State<AnlageTabelle> createState() => _AnlageTabelleState();
}

class _AnlageTabelleState extends State<AnlageTabelle> {
  final _ctrl = <String, TextEditingController>{};
  final _fokus = <String, FocusNode>{};

  bool get _ausfuellbar => widget.speicherKey != null && widget.loesung == null && widget.anlage.hatLeere;

  TextEditingController _controller(String rc) => _ctrl.putIfAbsent(
      rc, () => TextEditingController(text: AnswerStore.instance.tabWerte(widget.speicherKey!)[rc] ?? ''));

  void _speichern(String rc) {
    AnswerStore.instance.setTab(widget.speicherKey!, rc, _controller(rc).text);
    widget.onEingabe?.call();
  }

  FocusNode _knoten(String rc) => _fokus.putIfAbsent(rc, () {
        final n = FocusNode();
        n.addListener(() {
          if (n.hasFocus) {
            widget.onFokus?.call(AktivesFeld(_controller(rc), () => _speichern(rc), art: FeldArt.tabelle));
          }
        });
        return n;
      });

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final n in _fokus.values) {
      n.dispose();
    }
    super.dispose();
  }

  Widget _feld(String rc, String label) => Semantics(
        label: label,
        child: SizedBox(
          width: 92,
          child: Aufleuchten(
            controller: _controller(rc),
            radius: 6,
            child: TextField(
            controller: _controller(rc),
            focusNode: _knoten(rc),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12.5, color: kInk),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: kPaper,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kLine)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kLine)),
              focusedBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: kPetrol, width: 2)),
              hintText: '–',
              hintStyle: TextStyle(fontSize: 12.5, color: kMuted),
            ),
            onChanged: (_) => _speichern(rc),
            ),
          ),
        ),
      );

  /// Zelle nach dem Aufdecken: amtlicher Wert, darunter die eigene Eingabe.
  Widget _vergleich(String soll, String eigen) {
    final s = soll.trim(), e = eigen.trim();
    if (s.isEmpty) {
      return Text(e, textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: kMuted));
    }
    final ok = e.isNotEmpty && anlageGleich(s, e);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(s, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
      if (e.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(ok ? '✓ $e' : e,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  color: ok ? kOkInk : kErrInk,
                  decoration: ok ? null : TextDecoration.lineThrough,
                  decorationColor: kErrInk)),
        ),
    ]);
  }

  TableRow _zeile(List<String> zellen, {bool kopf = false, int? ri}) {
    final werte =
        widget.speicherKey == null ? const <String, String>{} : AnswerStore.instance.tabWerte(widget.speicherKey!);
    return TableRow(
      decoration: kopf ? BoxDecoration(color: kSurface2) : null,
      children: [
        for (var i = 0; i < zellen.length; i++)
          Padding(
            padding: _istFeld(zellen, i, kopf: kopf, ri: ri)
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
                : const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: _zelle(zellen, i, kopf: kopf, ri: ri, werte: werte),
          ),
      ],
    );
  }

  bool _istFeld(List<String> zellen, int i, {required bool kopf, int? ri}) =>
      zellen[i].trim().isEmpty && !kopf && ri != null && widget.speicherKey != null && widget.loesung == null;

  Widget _zelle(List<String> zellen, int i, {required bool kopf, int? ri, required Map<String, String> werte}) {
    final txt = zellen[i];
    if (txt.trim().isNotEmpty || kopf || ri == null || widget.speicherKey == null) {
      return Text(txt,
          textAlign: i == 0 ? TextAlign.left : TextAlign.right,
          style: TextStyle(
              fontSize: kopf ? 11.5 : 13,
              fontWeight: kopf ? FontWeight.w700 : (i == 0 ? FontWeight.w600 : FontWeight.w400),
              color: kopf ? kPetrolInkDeep : kInk));
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((a.titel.isEmpty ? 'Anlage' : a.titel).toUpperCase(),
            style: monoStyle(10.5, color: kPetrolInk, weight: FontWeight.w600, spacing: 0.8)),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 380),
            child: Container(
              color: kPaper,
              child: Table(
                border: TableBorder.all(color: kLine),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  if (a.kopf.isNotEmpty) _zeile(a.kopf, kopf: true),
                  for (var i = 0; i < a.zeilen.length; i++) _zeile(a.zeilen[i], ri: i),
                ],
              ),
            ),
          ),
        ),
        if (a.hinweis.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(a.hinweis, style: TextStyle(fontSize: 11.5, height: 1.45, color: kMuted)),
        ],
        if (_ausfuellbar) ...[
          const SizedBox(height: 9),
          Text(
              'Die leeren Felder kannst du hier ausfüllen – sie werden '
              'gespeichert und beim Aufdecken mit der amtlichen Lösung verglichen.',
              style: TextStyle(fontSize: 11.5, height: 1.45, color: kPetrolInk, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}
