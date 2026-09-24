import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../werkzeuge/blatt.dart';
import '../werkzeuge/rechner_modell.dart';
import '../werkzeuge/rechner_ziel.dart';
import 'ui.dart';

// Die Anzeige bleibt in beiden Darstellungen dunkel wie ein Rechner-Display
// (FR-002 A/I, Ausnahme für feste Farben) – Werte wie im Web (`.calc-disp`).
const Color _dispGrund = Color(0xFF0F1E23);
const Color _dispText = Color(0xFF8FB6BD);
const Color _dispHell = Color(0xFFEAFAFF);
const Color _dispWert = Color(0xFFCFEEF2);
const Color _dispFehler = Color(0xFFFFB4A3);
const Color _dispZeit = Color(0xFF9FE0C9);
const Color _dispLinie = Color(0x4D8FB6BD);

/// Wie der Rechner erscheint: als Blatt, unten angedockt (Handy) oder als
/// schwebendes Fenster (breit).
enum RechnerStil { blatt, angedockt, schwebend }

/// Taschenrechner wie ein Prüfungsrechner (FR-005): Anzeige mit Verlauf,
/// Funktionsreihe `inv sin cos tan π h min`, Tastenfeld 5 × 5 und
/// „↩ Übernehmen“. Der Zustand liegt in [RechnerModell.instance] und
/// übersteht Schließen und Neustart.
///
/// Passt sich der verfügbaren Höhe an: Ist wenig Platz, werden die Tasten
/// niedriger.
class CalculatorSheet extends StatefulWidget {
  /// Setzt das Ergebnis ins Antwortfeld („1234,5“ – ohne Tausenderpunkt);
  /// `null` blendet „Übernehmen“ aus.
  final void Function(String text)? onUebernehmen;

  /// ✕; ohne Angabe schließt ✕ die Route (Blatt).
  final VoidCallback? onSchliessen;
  final RechnerStil stil;

  /// Kopf ziehen (schwebendes Fenster).
  final GestureDragUpdateCallback? onZiehen;

  /// Anderes Modell (Tests); sonst [RechnerModell.instance].
  final RechnerModell? modell;

  const CalculatorSheet({
    super.key,
    this.onUebernehmen,
    this.onSchliessen,
    this.stil = RechnerStil.blatt,
    this.onZiehen,
    this.modell,
  });

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  /// Offene Rechner; nur der zuletzt geöffnete nimmt die Tastatur an.
  static final List<_CalculatorSheetState> _offen = [];

  RechnerModell get _m => widget.modell ?? RechnerModell.instance;
  bool get _dock => widget.stil == RechnerStil.angedockt;

  @override
  void initState() {
    super.initState();
    _offen.add(this);
    HardwareKeyboard.instance.addHandler(_tastatur);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_tastatur);
    _offen.remove(this);
    super.dispose();
  }

  void _schliessen() {
    final s = widget.onSchliessen;
    if (s != null) {
      s();
    } else {
      Navigator.maybePop(context);
    }
  }

  static const Map<String, String> _zeichen = {
    '+': '+', '-': '−', '*': '×', 'x': '×', '/': '÷', ':': '÷', '^': '^', '%': '%',
    '(': '(', ')': ')', ',': ',', '.': ',', '=': '=', 'c': 'C', 'C': 'C', 'p': 'π', 'h': 'zeit',
  };

  static final Map<LogicalKeyboardKey, String> _ziffernblock = {
    LogicalKeyboardKey.numpadAdd: '+',
    LogicalKeyboardKey.numpadSubtract: '−',
    LogicalKeyboardKey.numpadMultiply: '×',
    LogicalKeyboardKey.numpadDivide: '÷',
    LogicalKeyboardKey.numpadDecimal: ',',
    LogicalKeyboardKey.numpadComma: ',',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  /// Hardware-Tastatur (FR-005 E, wie Web): Ziffern, `+ - * / : x ^ % ( ) , .`,
  /// Enter und `=`, ⌫, Entf/`c`, `p` (π), `h` (Zeit), Esc schließt. Nicht,
  /// solange ein Textfeld den Fokus hat.
  bool _tastatur(KeyEvent e) {
    if (!mounted || _offen.isEmpty || !identical(_offen.last, this)) return false;
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final hw = HardwareKeyboard.instance;
    if (hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed) return false;
    final fokus = FocusManager.instance.primaryFocus;
    final fctx = fokus?.context;
    if (fctx != null &&
        (fctx.widget is EditableText || fctx.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    final taste = e.logicalKey;
    String? k;
    if (taste == LogicalKeyboardKey.enter || taste == LogicalKeyboardKey.numpadEnter) {
      // Enter auf einem Knopf der Seite („Antwort prüfen“) löst den Knopf aus.
      if (fokus != null && fokus is! FocusScopeNode) return false;
      k = '=';
    } else if (_ziffernblock.containsKey(taste)) {
      k = _ziffernblock[taste];
    } else if (taste == LogicalKeyboardKey.backspace) {
      k = '⌫';
    } else if (taste == LogicalKeyboardKey.delete) {
      k = 'C';
    } else if (taste == LogicalKeyboardKey.escape) {
      if (widget.stil == RechnerStil.blatt) return false; // das Blatt schließt selbst
      _schliessen();
      return true;
    } else {
      final c = e.character;
      if (c == null || c.isEmpty) return false;
      k = _zeichen[c] ?? (RegExp(r'^\d$').hasMatch(c) ? c : null);
    }
    if (k == null) return false;
    _m.taste(k);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_m, rechnerZiel]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) => _aufbau(box.maxHeight.isFinite),
      ),
    );
  }

  Widget _aufbau(bool begrenzt) {
    final m = _m;
    final zeigeUebernehmen = widget.onUebernehmen != null && m.kannUebernehmen;
    final tasten = _Tastenfeld(modell: m, dock: _dock);
    final inhalt = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RechnerAnzeige(modell: m, verlaufHoehe: _dock ? 44 : 64),
        if (zeigeUebernehmen) ...[
          SizedBox(height: _dock ? 6 : 8),
          _uebernehmenKnopf(),
        ],
        if (!m.mini) ...[
          SizedBox(height: _dock ? 8 : 10),
          if (begrenzt) Flexible(child: tasten) else tasten,
        ],
      ],
    );
    final koerper = Padding(
      padding: _dock ? const EdgeInsets.fromLTRB(10, 8, 10, 10) : const EdgeInsets.all(12),
      child: inhalt,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kopf(),
        if (begrenzt) Flexible(child: koerper) else koerper,
      ],
    );
  }

  Widget _kopf() {
    final mini = _m.mini;
    final kopf = Container(
      padding: _dock ? const EdgeInsets.fromLTRB(12, 6, 10, 6) : const EdgeInsets.fromLTRB(12, 9, 10, 9),
      decoration: BoxDecoration(
        color: widget.stil == RechnerStil.blatt ? null : kSurface,
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(children: [
        Icon(Icons.calculate_outlined, size: 17, color: kPetrolInk),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            header: true,
            child: Text('TASCHENRECHNER', maxLines: 1, overflow: TextOverflow.ellipsis, style: dispStyle(15)),
          ),
        ),
        RahmenKnopf(
          onTap: _m.miniUmschalten,
          semantik: mini ? 'Tasten ausklappen' : 'Tasten einklappen',
          child: AnimatedRotation(
            turns: mini ? 0.5 : 0,
            duration: const Duration(milliseconds: 150),
            child: Icon(Icons.expand_more, size: 20, color: kMuted),
          ),
        ),
        const SizedBox(width: 6),
        SchliessenKnopf(onTap: _schliessen, groesse: 34),
      ]),
    );
    if (widget.onZiehen == null) return kopf;
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(onPanUpdate: widget.onZiehen, child: kopf),
    );
  }

  Widget _uebernehmenKnopf() {
    final ziel = rechnerZiel.value ?? 'ins Antwortfeld';
    final r = BorderRadius.circular(10);
    return Semantics(
      button: true,
      label: 'Übernehmen $ziel',
      excludeSemantics: true,
      child: Material(
        color: kPetrolSoft,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: kPetrolLine)),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: r,
          onTap: () {
            if (_m.kannUebernehmen) widget.onUebernehmen?.call(_m.uebernahmeWert);
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: _dock ? 36 : 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.undo_rounded, size: 17, color: kPetrolInkDeep),
                const SizedBox(width: 7),
                Flexible(
                  child: Text.rich(
                    TextSpan(text: 'Übernehmen ', children: [
                      TextSpan(text: ziel, style: TextStyle(fontWeight: FontWeight.w500, color: kPetrolInk)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: kPetrolInkDeep),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ersatzschrift für π und √ – die gebündelten Schriften (Inter, IBM Plex
/// Mono) haben beide Zeichen nicht; Roboto ist auf Android die Systemschrift.
const List<String> _ersatz = ['Roboto'];

/// Text mit „⁻¹“ als hochgestelltes „−1“ – die gebündelten Schriften haben
/// das Zeichen nicht.
List<InlineSpan> _mitHochzahl(String text, TextStyle stil) {
  const hoch = '⁻¹';
  stil = stil.copyWith(fontFamilyFallback: _ersatz);
  if (!text.contains(hoch)) return [TextSpan(text: text, style: stil)];
  final spans = <InlineSpan>[];
  final teile = text.split(hoch);
  final groesse = stil.fontSize ?? 14;
  for (var i = 0; i < teile.length; i++) {
    if (teile[i].isNotEmpty) spans.add(TextSpan(text: teile[i], style: stil));
    if (i < teile.length - 1) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.aboveBaseline,
        baseline: TextBaseline.alphabetic,
        child: Padding(
          padding: EdgeInsets.only(bottom: groesse * 0.35, left: 0.5),
          child: Text('−1', style: stil.copyWith(fontSize: groesse * 0.62, height: 1)),
        ),
      ));
    }
  }
  return spans;
}

/// Anzeige: Verlauf, Rechnung, Ergebnis mit Zeitfeld; wackelt bei Fehlern.
class _RechnerAnzeige extends StatefulWidget {
  final RechnerModell modell;
  final double verlaufHoehe;
  const _RechnerAnzeige({required this.modell, required this.verlaufHoehe});

  @override
  State<_RechnerAnzeige> createState() => _RechnerAnzeigeState();
}

class _RechnerAnzeigeState extends State<_RechnerAnzeige> with SingleTickerProviderStateMixin {
  late final AnimationController _wackeln =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  late int _stand = widget.modell.wackeln;

  @override
  void initState() {
    super.initState();
    widget.modell.addListener(_pruefen);
  }

  @override
  void didUpdateWidget(covariant _RechnerAnzeige alt) {
    super.didUpdateWidget(alt);
    if (!identical(alt.modell, widget.modell)) {
      alt.modell.removeListener(_pruefen);
      widget.modell.addListener(_pruefen);
      _stand = widget.modell.wackeln;
    }
  }

  @override
  void dispose() {
    widget.modell.removeListener(_pruefen);
    _wackeln.dispose();
    super.dispose();
  }

  void _pruefen() {
    if (widget.modell.wackeln != _stand) {
      _stand = widget.modell.wackeln;
      _wackeln.forward(from: 0);
    }
  }

  /// Ausschlag: 25 % → −5, 75 % → +5 (Web `cshake`).
  double _versatz(double t) {
    if (t <= 0.25) return -5 * (t / 0.25);
    if (t <= 0.75) return -5 + 10 * ((t - 0.25) / 0.5);
    return 5 * (1 - (t - 0.75) / 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.modell;
    const mono = TextStyle(fontFamily: kFontMono, fontFamilyFallback: _ersatz, fontWeight: FontWeight.w500);
    final ausdruck = <InlineSpan>[];
    for (final t in m.anzeigeZeile) {
      ausdruck.addAll(_mitHochzahl(
          t.text,
          mono.copyWith(
              fontSize: 14, height: 1.4, color: t.blass ? _dispText.withValues(alpha: 0.38) : _dispText)));
    }
    final art = m.ergebnisArt;
    final zeit = m.zeitText;
    final ergebnisStil = art == ErgebnisArt.fehler
        ? const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: _dispFehler)
        : TextStyle(
            fontFamily: kFontMono,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: art == ErgebnisArt.blass ? _dispHell.withValues(alpha: 0.4) : _dispHell,
          );

    final anzeige = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
      decoration: BoxDecoration(
        color: _dispGrund,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (m.verlauf.isNotEmpty) _verlauf(m),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 20),
            child: Text.rich(
              TextSpan(children: ausdruck),
              textAlign: TextAlign.right,
              style: mono.copyWith(fontSize: 14, height: 1.4, color: _dispText),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 36,
            child: Row(children: [
              if (zeit != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: _dispZeit, borderRadius: BorderRadius.circular(6)),
                  child: Text(zeit,
                      style: const TextStyle(
                          fontFamily: kFontMono, fontSize: 12, fontWeight: FontWeight.w600, color: _dispGrund)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      liveRegion: true,
                      label: art == ErgebnisArt.fehler ? m.ergebnisText : 'Ergebnis ${m.ergebnisText}',
                      excludeSemantics: true,
                      child: Text(m.ergebnisText, maxLines: 1, style: ergebnisStil),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Eingeklappt: Antippen der Anzeige klappt die Tasten wieder auf.
      onTap: m.mini ? m.aufklappen : null,
      child: AnimatedBuilder(
        animation: _wackeln,
        builder: (context, child) => Transform.translate(
          offset: Offset(_wackeln.isAnimating ? _versatz(_wackeln.value) : 0, 0),
          child: child,
        ),
        child: anzeige,
      ),
    );
  }

  Widget _verlauf(RechnerModell m) {
    final eintraege = m.verlauf;
    const mono = TextStyle(fontFamily: kFontMono, fontFamilyFallback: _ersatz, fontSize: 12, height: 1.5);
    final zeilen = <Widget>[
      for (var i = eintraege.length - 1; i >= 0; i--)
        Semantics(
          button: true,
          label: '${eintraege[i].a} ${eintraege[i].wertText} einsetzen',
          excludeSemantics: true,
          child: InkWell(
            canRequestFocus: false,
            borderRadius: BorderRadius.circular(5),
            onTap: () => m.einsetzen(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                        children: _mitHochzahl(
                            eintraege[i].a, mono.copyWith(fontWeight: FontWeight.w500, color: _dispText))),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 5),
                Text(eintraege[i].wertText,
                    maxLines: 1, style: mono.copyWith(fontWeight: FontWeight.w600, color: _dispWert)),
              ]),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(5),
          onTap: m.verlaufLeeren,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('Verlauf leeren',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _dispText.withValues(alpha: 0.8))),
          ),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: CustomPaint(
        painter: const _Strichlinie(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.verlaufHoehe),
            child: ListView(
              shrinkWrap: true,
              reverse: true,
              padding: EdgeInsets.zero,
              children: zeilen,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gestrichelte Linie unter dem Verlauf (Web: `border-bottom: 1px dashed`).
class _Strichlinie extends CustomPainter {
  const _Strichlinie();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _dispLinie
      ..strokeWidth = 1;
    final y = size.height - 0.5;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _Strichlinie old) => false;
}

enum _Art { zahl, op, fx, del, eq }

/// Funktionsreihe und Tastenfeld 5 × 5 (Web `FN_TASTEN`, `TASTEN`).
class _Tastenfeld extends StatelessWidget {
  final RechnerModell modell;
  final bool dock;
  const _Tastenfeld({required this.modell, required this.dock});

  static const _fn = [
    ('inv', 'Umkehrfunktion: sin⁻¹, cos⁻¹, tan⁻¹'),
    ('sin', 'Sinus (Grad)'),
    ('cos', 'Kosinus (Grad)'),
    ('tan', 'Tangens (Grad)'),
    ('π', 'Pi'),
    ('zeit', 'Stunden und Minuten, z. B. 6 h 45 min'),
  ];

  static const List<List<(String, _Art, String?)>> _gitter = [
    [('C', _Art.del, 'Alles löschen'), ('(', _Art.zahl, null), (')', _Art.zahl, null), ('%', _Art.op, 'Prozent'), ('⌫', _Art.del, 'Letzte Eingabe löschen')],
    [('7', _Art.zahl, null), ('8', _Art.zahl, null), ('9', _Art.zahl, null), ('÷', _Art.op, 'geteilt durch'), ('√', _Art.fx, 'Wurzel')],
    [('4', _Art.zahl, null), ('5', _Art.zahl, null), ('6', _Art.zahl, null), ('×', _Art.op, 'mal'), ('²', _Art.fx, 'Quadrat')],
    [('1', _Art.zahl, null), ('2', _Art.zahl, null), ('3', _Art.zahl, null), ('−', _Art.op, 'minus'), ('^', _Art.fx, 'hoch')],
    [('0', _Art.zahl, null), (',', _Art.zahl, 'Komma'), ('±', _Art.zahl, 'Vorzeichen wechseln'), ('+', _Art.op, 'plus'), ('=', _Art.eq, 'Ergebnis')],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final abstand = dock ? 5.0 : 6.0;
      var taste = dock ? 42.0 : 46.0;
      var fn = dock ? 32.0 : 34.0;
      final noetig = fn + 5 * taste + 5 * abstand;
      var zuKnapp = false;
      if (box.maxHeight.isFinite && box.maxHeight < noetig) {
        // Wenig Platz (z. B. kleines Blatt): Tasten niedriger, nie unter die
        // Hälfte – reicht auch das nicht, lässt sich das Tastenfeld scrollen.
        final f = (box.maxHeight - 5 * abstand) / (fn + 5 * taste);
        zuKnapp = f < 0.5;
        final g = f.clamp(0.5, 1.0);
        taste *= g;
        fn *= g;
      }
      final reihen = <Widget>[
        SizedBox(height: fn, child: _reihe([for (final k in _fn) _fnTaste(k.$1, k.$2)], abstand)),
      ];
      for (final r in _gitter) {
        reihen
          ..add(SizedBox(height: abstand))
          ..add(SizedBox(
              height: taste, child: _reihe([for (final k in r) _taste(k.$1, k.$2, k.$3)], abstand)));
      }
      final feld = Column(mainAxisSize: MainAxisSize.min, children: reihen);
      return zuKnapp ? SingleChildScrollView(child: feld) : feld;
    });
  }

  Widget _reihe(List<Widget> tasten, double abstand) {
    final kinder = <Widget>[];
    for (var i = 0; i < tasten.length; i++) {
      if (i > 0) kinder.add(SizedBox(width: abstand));
      kinder.add(Expanded(child: tasten[i]));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: kinder);
  }

  Widget _knopf({
    required String code,
    required Widget beschriftung,
    required Color grund,
    required Color rand,
    required double radius,
    String? semantik,
    bool? an,
  }) {
    final r = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      label: semantik,
      toggled: an,
      excludeSemantics: semantik != null,
      child: Material(
        color: grund,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: rand)),
        child: InkWell(
          canRequestFocus: false,
          borderRadius: r,
          onTap: () => modell.taste(code),
          child: Center(child: beschriftung),
        ),
      ),
    );
  }

  Widget _fnTaste(String code, String semantik) {
    final inv = modell.inv;
    final an = code == 'inv' && inv;
    final farbe = an ? Colors.white : kPetrolInkDeep;
    final stil = TextStyle(
      fontFamily: kFontMono,
      fontSize: code == 'zeit' ? 11.5 : 13,
      fontWeight: FontWeight.w600,
      letterSpacing: code == 'zeit' ? -0.2 : 0,
      color: farbe,
    );
    final text = switch (code) {
      'zeit' => 'h min',
      'sin' || 'cos' || 'tan' => inv ? '$code⁻¹' : code,
      _ => code,
    };
    return _knopf(
      code: code,
      beschriftung: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(TextSpan(children: _mitHochzahl(text, stil)), maxLines: 1),
      ),
      grund: an ? kPetrol : kSurface,
      rand: an ? kPetrol : kLine,
      radius: 8,
      semantik: semantik,
      an: code == 'inv' ? inv : null,
    );
  }

  Widget _taste(String code, _Art art, String? semantik) {
    final farbe = switch (art) {
      _Art.eq => Colors.white,
      _Art.del => kAmberInk,
      _Art.op || _Art.fx => kPetrolInkDeep,
      _Art.zahl => kInk,
    };
    final groesse = switch (art) {
      _Art.eq => 22.0,
      _Art.fx => 16.0,
      _ => 18.0,
    };
    final stil = TextStyle(
        fontFamily: 'Inter',
        fontFamilyFallback: _ersatz,
        fontSize: groesse,
        fontWeight: FontWeight.w600,
        color: farbe,
        height: 1.1);
    final Widget beschriftung = switch (code) {
      '⌫' => Icon(Icons.backspace_outlined, size: 20, color: farbe),
      '²' => Text('x²', style: stil),
      '^' => Text.rich(TextSpan(children: [
          TextSpan(text: 'x', style: stil),
          WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: EdgeInsets.only(bottom: groesse * 0.4, left: 1),
              child: Text('y', style: stil.copyWith(fontSize: groesse * 0.62, height: 1)),
            ),
          ),
        ])),
      _ => Text(code, style: stil),
    };
    return _knopf(
      code: code,
      beschriftung: beschriftung,
      grund: switch (art) {
        _Art.eq => kPetrol,
        _Art.op => kSurface2,
        _ => kPaper,
      },
      rand: art == _Art.eq ? kPetrol : kLineStrong,
      radius: 10,
      semantik: semantik,
    );
  }
}
