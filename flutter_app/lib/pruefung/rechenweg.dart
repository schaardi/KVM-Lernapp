import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/answer_store.dart';
import 'rechenweg_kern.dart';
import '../widgets/ui.dart';
import 'pruef_ui.dart';

/// Rechenweg statt Textfeld (FR-003 B, Web `rwHTML`/`rwBinden`): Zeile für
/// Zeile Bezeichnung, Rechnung, Einheit – jede Zeile rechnet sofort.
/// Ergebnisse früherer Zeilen lassen sich über die Tastenleiste einsetzen.
/// Gespeichert wird in `kvm_open_calc` (über den [AnswerStore]).
class RechenwegFeld extends StatefulWidget {
  final String id;

  /// Nach jeder gespeicherten Änderung.
  final VoidCallback onAenderung;

  /// Ein Feld des Rechenwegs hat den Fokus bekommen (Ziel für „Übernehmen“).
  final ValueChanged<AktivesFeld>? onFokus;

  /// Beim Aufklappen gleich in die erste Rechnung springen.
  final bool autofokus;

  const RechenwegFeld({super.key, required this.id, required this.onAenderung, this.onFokus, this.autofokus = false});

  @override
  State<RechenwegFeld> createState() => _RechenwegFeldState();
}

class _Zeile {
  final l = TextEditingController();
  final f = TextEditingController();
  final u = TextEditingController();
  final lf = FocusNode();
  final ff = FocusNode();
  final uf = FocusNode();

  void dispose() {
    for (final c in [l, f, u]) {
      c.dispose();
    }
    for (final n in [lf, ff, uf]) {
      n.dispose();
    }
  }
}

const _tasten = [('+', '+'), ('−', '−'), ('·', '·'), ('÷', '÷'), ('(', '('), (')', ')'), ('%', ' %'), ('x²', '²'), ('√', '√(')];

class _RechenwegFeldState extends State<RechenwegFeld> {
  final _zeilen = <_Zeile>[];
  _Zeile? _letzt; // zuletzt fokussierte Rechnung – dort setzen die Tasten ein
  bool _fokus = false;

  @override
  void initState() {
    super.initState();
    final rows = AnswerStore.instance.calc(widget.id);
    if (rows.isEmpty) {
      _zeilen.add(_neu());
    } else {
      for (final r in rows) {
        _zeilen.add(_neu(l: r['l'] ?? '', f: r['f'] ?? '', u: r['u'] ?? ''));
      }
    }
    if (widget.autofokus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _zeilen.first.ff.requestFocus();
      });
    }
  }

  _Zeile _neu({String l = '', String f = '', String u = ''}) {
    final z = _Zeile();
    z.l.text = l;
    z.f.text = f;
    z.u.text = u;
    void fokus(TextEditingController c, FocusNode n, {bool rechnung = false}) {
      n.addListener(() {
        if (!n.hasFocus) return;
        if (rechnung) _letzt = z;
        widget.onFokus?.call(AktivesFeld(c, () => _geaendert(neuRechnen: true), teilId: widget.id));
        if (mounted) setState(() {});
      });
    }

    fokus(z.l, z.lf);
    fokus(z.f, z.ff, rechnung: true);
    fokus(z.u, z.uf);
    return z;
  }

  @override
  void dispose() {
    for (final z in _zeilen) {
      z.dispose();
    }
    super.dispose();
  }

  void _speichern() {
    AnswerStore.instance.setCalc(widget.id, [
      for (final z in _zeilen) {'l': z.l.text, 'f': z.f.text, 'u': z.u.text}
    ]);
    widget.onAenderung();
  }

  void _geaendert({bool neuRechnen = false}) {
    _speichern();
    if (neuRechnen && mounted) setState(() {});
  }

  void _neueZeile({_Zeile? nach}) {
    final z = _neu();
    setState(() {
      final i = nach == null ? -1 : _zeilen.indexOf(nach);
      if (i < 0) {
        _zeilen.add(z);
      } else {
        _zeilen.insert(i + 1, z);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) z.ff.requestFocus();
    });
  }

  void _zeileDazu() {
    final l = _zeilen.last;
    // Eine leere letzte Zeile wird genutzt statt eine weitere anzuhängen.
    if (l.f.text.trim().isEmpty && l.l.text.trim().isEmpty) {
      l.ff.requestFocus();
    } else {
      _neueZeile();
    }
  }

  void _loeschen(_Zeile z) {
    setState(() {
      if (_zeilen.length <= 1) {
        z.l.clear();
        z.f.clear();
        z.u.clear();
      } else {
        if (_letzt == z) _letzt = null;
        _zeilen.remove(z);
        WidgetsBinding.instance.addPostFrameCallback((_) => z.dispose());
      }
    });
    _speichern();
  }

  void _weiter(_Zeile z) {
    final i = _zeilen.indexOf(z);
    if (i >= 0 && i + 1 < _zeilen.length) {
      _zeilen[i + 1].ff.requestFocus();
    } else {
      _neueZeile(nach: z);
    }
  }

  /// Taste oder Zeilenbezug an der Schreibmarke einsetzen – ohne den Fokus
  /// aus dem Feld zu nehmen.
  void _einsetzen(String txt, {bool bezug = false}) {
    final z = (_letzt != null && _zeilen.contains(_letzt)) ? _letzt! : _zeilen.first;
    final v = z.f.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    var t = txt;
    if (bezug && sel.start > 0 && RegExp(r'[\d,]$').hasMatch(v.text.substring(0, sel.start))) t = ' · $t';
    z.f.value = v.replaced(sel, t).copyWith(selection: TextSelection.collapsed(offset: sel.start + t.length));
    if (!z.ff.hasFocus) z.ff.requestFocus();
    _geaendert(neuRechnen: true);
  }

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width >= 640;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hat) => setState(() => _fokus = hat),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
          color: kSurface,
          border: Border.all(color: kPetrolLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
            child: Row(children: [
              Text('RECHENWEG', style: monoStyle(10, color: kPetrolInk, weight: FontWeight.w700, spacing: 1)),
              const Spacer(),
              Text('rechnet sofort mit', style: TextStyle(fontSize: 11, color: kMuted)),
            ]),
          ),
          for (var i = 0; i < _zeilen.length; i++) _zeile(_zeilen[i], i, breit),
          if (_fokus) TextFieldTapRegion(child: _tastenleiste()),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
            _ZeileKnopf(onTap: _zeileDazu),
            if (breit)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'Enter springt in die nächste Zeile. Ergebnisse früherer Zeilen (Z1, Z2 …) über die Leiste einsetzen.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: kMuted),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _ergebnis(_Zeile z, bool breit) {
    final f = z.f.text;
    final u = z.u.text.trim();
    if (f.trim().isEmpty) {
      return Text('= …', style: monoStyle(15, color: kPlaceholder, weight: FontWeight.w600, spacing: 0));
    }
    final v = rechne(f);
    if (!v.isFinite) {
      return Text('Rechnung prüfen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kErrInk));
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '= ${rwFmt(v, u)}'),
        if (u.isNotEmpty && !breit) TextSpan(text: ' $u', style: TextStyle(fontSize: 13, color: kPetrolInk)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: monoStyle(15, color: kPetrolInkDeep, weight: FontWeight.w700, spacing: 0),
    );
  }

  Widget _zeile(_Zeile z, int i, bool breit) {
    final n = i + 1;
    final bezeichnung = TextField(
      controller: z.l,
      focusNode: z.lf,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => z.ff.requestFocus(),
      onChanged: (_) => _speichern(),
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kInk),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: 'Bezeichnung, z. B. Fixkosten',
        hintStyle: TextStyle(fontSize: 13, color: kPlaceholder, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kLineStrong)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kPetrol)),
        border: UnderlineInputBorder(borderSide: BorderSide(color: kLineStrong)),
      ),
    );
    final rechnung = Semantics(
      label: 'Zeile $n: Rechnung',
      child: TextField(
        controller: z.f,
        focusNode: z.ff,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _weiter(z),
        onChanged: (_) => _geaendert(neuRechnen: true),
        style: monoStyle(15, color: kInk, weight: FontWeight.w600, spacing: 0),
        decoration: _feld('Rechnung, z. B. 4.400 ÷ 22', stark: true),
      ),
    );
    final einheit = Semantics(
      label: 'Zeile $n: Einheit',
      child: TextField(
        controller: z.u,
        focusNode: z.uf,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => z.ff.requestFocus(),
        onChanged: (_) => _geaendert(neuRechnen: true),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kInk),
        decoration: _feld('Einheit'),
      ),
    );
    final weg = SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: 'Zeile $n löschen',
        onPressed: () => _loeschen(z),
        icon: Icon(Icons.close, size: 16, color: kMuted),
      ),
    );
    final nr = SizedBox(
      width: 24,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Z$n', textAlign: TextAlign.center, style: monoStyle(10, color: kMuted, weight: FontWeight.w700, spacing: 0)),
      ),
    );

    final inhalt = breit
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            bezeichnung,
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: rechnung),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 70, maxWidth: 190),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _ergebnis(z, breit)),
              ),
              const SizedBox(width: 7),
              SizedBox(width: 72, child: einheit),
            ]),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: bezeichnung), weg]),
            const SizedBox(height: 6),
            rechnung,
            const SizedBox(height: 6),
            Row(children: [
              SizedBox(width: 76, child: einheit),
              const SizedBox(width: 7),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _ergebnis(z, breit)),
                ),
              ),
            ]),
          ]);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(7, 7, 6, 7),
      decoration: BoxDecoration(
        color: kPaper,
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        nr,
        const SizedBox(width: 7),
        Expanded(child: inhalt),
        if (breit) ...[const SizedBox(width: 7), weg],
      ]),
    );
  }

  InputDecoration _feld(String hinweis, {bool stark = false}) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: kPaper,
        hintText: hinweis,
        hintStyle: TextStyle(fontSize: 13, color: kPlaceholder, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        contentPadding: EdgeInsets.symmetric(horizontal: stark ? 10 : 7, vertical: 9),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: stark ? kLineStrong : kLine)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPetrol, width: 1.6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  /// Tasten `+ − · ÷ ( ) % x² √(` und die Ergebnisse früherer Zeilen.
  Widget _tastenleiste() {
    final akt = (_letzt != null && _zeilen.contains(_letzt)) ? _zeilen.indexOf(_letzt!) : _zeilen.length;
    final bezuege = <(int, String)>[];
    for (var i = 0; i < akt && i < _zeilen.length; i++) {
      final v = rechne(_zeilen[i].f.text);
      if (v.isFinite) bezuege.add((i + 1, rwFmt(v)));
    }
    Widget taste(String label, VoidCallback onTap, {bool bezug = false}) => Material(
          color: bezug ? kPetrolSoft : kPaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: bezug ? kPetrolLine : kLineStrong),
          ),
          child: InkWell(
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(label,
                  style: monoStyle(bezug ? 12 : 15, color: kPetrolInkDeep, weight: bezug ? FontWeight.w600 : FontWeight.w700, spacing: 0)),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 7),
      child: Wrap(spacing: 5, runSpacing: 5, children: [
        for (final t in _tasten) taste(t.$1, () => _einsetzen(t.$2)),
        for (final b in bezuege) taste('Z${b.$1} = ${b.$2}', () => _einsetzen(b.$2, bezug: true), bezug: true),
      ]),
    );
  }
}

/// „+ Zeile“ mit gestricheltem Rahmen.
class _ZeileKnopf extends StatelessWidget {
  final VoidCallback onTap;
  const _ZeileKnopf({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Gestrichelt(kPetrol),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('+ Zeile', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kPetrolInk)),
          ]),
        ),
      ),
    );
  }
}

class _Gestrichelt extends CustomPainter {
  final Color farbe;
  _Gestrichelt(this.farbe);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = farbe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(9)).deflate(0.5);
    final pfad = Path()..addRRect(rr);
    for (final m in pfad.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Gestrichelt old) => old.farbe != farbe;
}
