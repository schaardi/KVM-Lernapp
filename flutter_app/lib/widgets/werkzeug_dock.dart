import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';
import '../werkzeuge/blatt.dart';
import '../werkzeuge/rechner_ziel.dart';
import 'calculator.dart';
import 'drawing_pad.dart';
import 'formula_book.dart';

export '../werkzeuge/rechner_ziel.dart' show rechnerZiel, rechnerAusweichen;

/// Bis zu dieser Breite dockt der Rechner unten an, darüber schwebt er
/// (Web: `max-width: 560px`).
const double kRechnerDockBis = 560;

/// Werkzeug-Dock in Quiz und Aufgabenblatt (FR-002 C): Rechner, Rechenblatt,
/// Formelbuch – im Quiz zusätzlich „Sprache“.
///
/// Einbau als `Scaffold(bottomNavigationBar: WerkzeugDock(...))` – so
/// verdeckt das Dock nie „Weiter“. Auf dem Handy dockt der Rechner an Stelle
/// der Leiste unten an; der Scaffold-Inhalt wird dabei niedriger, die Aufgabe
/// bleibt darüber lesbar und scrollbar (FR-005 E). Ab 561 dp schwebt der
/// Rechner als ziehbares Fenster oben rechts.
///
/// Schnittstelle für Quiz und Aufgabenblatt:
/// - [onUebernehmen] übernimmt einen Text in das gerade aktive Antwortfeld;
///   `null` = kein Antwortfeld offen. Der Rechner liefert das Ergebnis ohne
///   Tausenderpunkt („1234,5“), das Formelbuch eine Vorlage (mehrzeilig).
///   Ist der Callback eine Funktion `String? Function(String)` und gibt er
///   das Ziel zurück (z. B. „Aufgabe 1 a)“), nennt das Formelbuch es.
///   Die Beschriftung „Übernehmen <Ziel>“ lässt sich über [rechnerZiel]
///   setzen; die ganze Rechnung für eine leere Rechenweg-Zeile liefert
///   `RechnerModell.instance.rechnungText`.
/// - [onSprache] schaltet Vorlesen/Spracheingabe; `null` blendet den Knopf aus.
class WerkzeugDock extends StatefulWidget {
  final void Function(String text)? onUebernehmen;
  final VoidCallback? onSprache;
  final bool spracheAktiv;
  const WerkzeugDock({super.key, this.onUebernehmen, this.onSprache, this.spracheAktiv = false});

  @override
  State<WerkzeugDock> createState() => _WerkzeugDockState();
}

class _WerkzeugDockState extends State<WerkzeugDock> {
  /// Alle eingebauten Docks – `oeffneRechner` sucht das Dock seiner Route.
  static final List<_WerkzeugDockState> _alle = [];

  final _portal = OverlayPortalController();
  bool _rechnerOffen = false;
  void Function(String text)? _ziel;
  Completer<void>? _zu;
  Offset? _pos;
  bool _verschoben = false;

  @override
  void initState() {
    super.initState();
    _alle.add(this);
  }

  @override
  void dispose() {
    _alle.remove(this);
    final zu = _zu;
    _zu = null;
    zu?.complete();
    if (_rechnerOffen) {
      // Nach dem Abbau – Zuhörer dürfen hier nicht mehr bauen.
      WidgetsBinding.instance.addPostFrameCallback((_) => rechnerAusweichen.value = 0);
    }
    super.dispose();
  }

  /// Dock derselben Route wie [context] (oder darüber im Baum).
  static _WerkzeugDockState? _fuer(BuildContext context) {
    final direkt = context.findAncestorStateOfType<_WerkzeugDockState>();
    if (direkt != null) return direkt;
    final route = ModalRoute.of(context);
    if (route == null) return null;
    for (final d in _alle.reversed) {
      if (d.mounted && ModalRoute.of(d.context) == route) return d;
    }
    return null;
  }

  Future<void> _rechnerOeffnen(void Function(String text)? ziel) {
    _ziel = ziel;
    if (_rechnerOffen) {
      setState(() {});
      return _zu!.future;
    }
    final zu = _zu = Completer<void>();
    setState(() => _rechnerOffen = true);
    _portal.show();
    _ausweichen();
    return zu.future;
  }

  void _rechnerSchliessen() {
    if (!_rechnerOffen) return;
    setState(() {
      _rechnerOffen = false;
      _ziel = null;
    });
    _portal.hide();
    _ausweichen();
    final zu = _zu;
    _zu = null;
    zu?.complete();
  }

  void _ausweichen() {
    final breite = MediaQuery.sizeOf(context).width;
    final wert = (_rechnerOffen && breite > kRechnerDockBis && !_verschoben && breite >= 1100) ? 324.0 + 40 : 0.0;
    if (rechnerAusweichen.value != wert) rechnerAusweichen.value = wert;
  }

  void _ziehen(DragUpdateDetails d) {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _verschoben = true;
      _pos = (_pos ?? _startPos(size, MediaQuery.paddingOf(context))) + d.delta;
    });
    _ausweichen();
  }

  static Offset _startPos(Size size, EdgeInsets rand) => Offset(size.width - 324 - 16, rand.top + 72);

  @override
  Widget build(BuildContext context) {
    final breit = MediaQuery.sizeOf(context).width > kRechnerDockBis;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _schwebend,
      child: _rechnerOffen && !breit ? _angedockt() : _leiste(breit),
    );
  }

  /// Handy: Rechner unten angedockt über die volle Breite, Ecken oben 16.
  Widget _angedockt() {
    final hoehe = MediaQuery.sizeOf(context).height;
    const ecken = BorderRadius.vertical(top: Radius.circular(16));
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: hoehe * 0.66),
      child: Container(
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: ecken,
          border: Border.all(color: kLineStrong),
          boxShadow: kSoftShadow,
        ),
        child: ClipRRect(
          borderRadius: ecken,
          child: SafeArea(
            top: false,
            child: CalculatorSheet(
              stil: RechnerStil.angedockt,
              onUebernehmen: _ziel,
              onSchliessen: _rechnerSchliessen,
            ),
          ),
        ),
      ),
    );
  }

  /// Breit: schwebendes Fenster, 324 breit, oben rechts, ziehbar.
  Widget _schwebend(BuildContext ctx) {
    final mq = MediaQuery.of(ctx);
    final size = mq.size;
    if (!_rechnerOffen || size.width <= kRechnerDockBis) return const SizedBox.shrink();
    const breite = 324.0;
    final p = _pos ?? _startPos(size, mq.padding);
    final oben = mq.padding.top + 6;
    final x = p.dx.clamp(6.0, math.max(6.0, size.width - breite - 6)).toDouble();
    final y = p.dy.clamp(oben, math.max(oben, size.height - 140)).toDouble();
    const ecken = BorderRadius.all(Radius.circular(14));
    return Stack(children: [
      Positioned(
        left: x,
        top: y,
        width: breite,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: math.max(160, size.height - y - 8 - mq.padding.bottom)),
          child: Container(
            decoration: BoxDecoration(
              color: kPaper,
              borderRadius: ecken,
              border: Border.all(color: kLineStrong),
              boxShadow: kSoftShadow,
            ),
            child: ClipRRect(
              borderRadius: ecken,
              child: Material(
                color: kPaper,
                child: CalculatorSheet(
                  stil: RechnerStil.schwebend,
                  onUebernehmen: _ziel,
                  onSchliessen: _rechnerSchliessen,
                  onZiehen: _ziehen,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _leiste(bool breit) {
    final knoepfe = <Widget>[
      _knopf(
        icon: Icons.calculate_outlined,
        label: 'Rechner',
        tooltip: 'Taschenrechner',
        an: _rechnerOffen,
        breit: breit,
        onTap: () => _rechnerOffen ? _rechnerSchliessen() : _rechnerOeffnen(widget.onUebernehmen),
      ),
      _knopf(
        icon: Icons.edit_outlined,
        label: 'Blatt',
        tooltip: 'Rechenblatt',
        breit: breit,
        onTap: () => oeffneRechenblatt(context),
      ),
      _knopf(
        icon: Icons.menu_book_outlined,
        label: 'Formeln',
        tooltip: 'Formelbuch',
        breit: breit,
        onTap: () => oeffneFormelbuchBlatt(context, onUebernehmen: widget.onUebernehmen),
      ),
      if (widget.onSprache != null)
        _knopf(
          icon: widget.spracheAktiv ? Icons.mic : Icons.mic_none,
          label: 'Sprache',
          tooltip: 'Sprachbedienung: Frage vorlesen, Antwort per A/B/C/D sprechen',
          an: widget.spracheAktiv,
          sprache: true,
          breit: breit,
          onTap: widget.onSprache!,
        ),
    ];
    final unten = MediaQuery.paddingOf(context).bottom;
    final leiste = Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: kPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        mainAxisSize: breit ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (var i = 0; i < knoepfe.length; i++) ...[
            if (i > 0) SizedBox(width: breit ? 2 : 4),
            breit ? knoepfe[i] : Expanded(child: knoepfe[i]),
          ],
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, breit ? 16 : 10, 10 + unten),
      child: breit ? Align(alignment: Alignment.centerRight, heightFactor: 1, child: leiste) : leiste,
    );
  }

  /// Ein Werkzeug: Symbol 20 in Petrol, Beschriftung darunter (Handy) bzw.
  /// daneben (breit). Offener Rechner: Fläche `kPetrolSoft`; Sprache an:
  /// violett gefüllt, weiße Schrift.
  Widget _knopf({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool breit,
    required VoidCallback onTap,
    bool an = false,
    bool sprache = false,
  }) {
    final gefuellt = sprache && an;
    final grund = gefuellt ? kViolet : (an ? kPetrolSoft : Colors.transparent);
    final symbol = gefuellt ? Colors.white : kPetrolInk;
    final schrift = gefuellt ? Colors.white : kInk;
    final inhalt = breit
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: symbol),
            const SizedBox(width: 9),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: schrift)),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: symbol),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, height: 1, color: schrift)),
          ]);
    final r = BorderRadius.circular(11);
    return Semantics(
      button: true,
      label: tooltip,
      toggled: (label == 'Rechner' || sprache) ? an : null,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: grund,
          borderRadius: r,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: breit ? 44 : 50),
              child: Padding(
                padding: breit ? const EdgeInsets.fromLTRB(11, 8, 14, 8) : const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Center(widthFactor: 1, heightFactor: 1, child: inhalt),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Öffnet den Taschenrechner (FR-005); „Übernehmen“ ruft [onUebernehmen]
/// mit dem Ergebnis ohne Tausenderpunkt („1234,5“).
///
/// Mit einem [WerkzeugDock] auf derselben Route dockt der Rechner dort an
/// (Handy) bzw. schwebt oben rechts (breit). Ohne Dock erscheint er als
/// Blatt, das die Seite darüber bedienbar lässt. Das Future endet, wenn der
/// Rechner geschlossen wird.
Future<void> oeffneRechner(BuildContext context, {void Function(String text)? onUebernehmen}) {
  final dock = _WerkzeugDockState._fuer(context);
  if (dock != null) return dock._rechnerOeffnen(onUebernehmen ?? dock.widget.onUebernehmen);
  return _rechnerOhneDock(context, onUebernehmen);
}

Future<void> _rechnerOhneDock(BuildContext context, void Function(String text)? onUebernehmen) {
  final hoehe = MediaQuery.sizeOf(context).height;
  const ecken = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)));
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null) {
    // Kein modales Blatt: Die Aufgabe darüber bleibt lesbar und bedienbar.
    late final PersistentBottomSheetController blatt;
    blatt = scaffold.showBottomSheet(
      (ctx) => SafeArea(
        top: false,
        child: CalculatorSheet(
          stil: RechnerStil.angedockt,
          onUebernehmen: onUebernehmen,
          onSchliessen: () => blatt.close(),
        ),
      ),
      backgroundColor: kPaper,
      shape: ecken,
      clipBehavior: Clip.antiAlias,
      enableDrag: false,
      constraints: BoxConstraints(maxWidth: 480, maxHeight: hoehe * 0.7),
    );
    return blatt.closed;
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPaper,
    shape: ecken,
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxWidth: 480, maxHeight: hoehe * 0.8),
    builder: (ctx) => SafeArea(
      top: false,
      child: CalculatorSheet(stil: RechnerStil.angedockt, onUebernehmen: onUebernehmen),
    ),
  );
}

/// Rechenblatt (Zeichenfläche) als Blatt. Das Blatt lässt sich nicht nach
/// unten wischen – jeder Strich gehört der Zeichnung.
Future<void> oeffneRechenblatt(BuildContext context) {
  return zeigeWerkzeugBlatt<void>(
    context,
    titel: 'Rechenblatt',
    hoehe: 0.8,
    ziehbar: false,
    inhalt: const DrawingPad(),
  );
}

/// Formelbuch als Blatt; „Vorlage ins Antwortfeld“ gibt die Vorlage an
/// [onUebernehmen]. Ohne Ziel landet sie in der Zwischenablage.
Future<void> oeffneFormelbuchBlatt(BuildContext context, {void Function(String text)? onUebernehmen}) {
  return zeigeWerkzeugBlatt<void>(
    context,
    titel: 'Formelbuch',
    inhalt: FormulaBook(onVorlage: onUebernehmen),
  );
}
