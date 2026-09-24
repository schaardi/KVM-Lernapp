import 'package:flutter/material.dart';
import '../../lernen/datum.dart';
import '../../lernen/lernplan.dart';
import '../../lernen/termin_formular.dart';
import '../../services/app_state.dart';
import '../../util/format.dart';
import '../ui.dart';

/// Prüfungstermin und Lernplan in der Heute-Karte (FR-006, FR-015 2.3).
///
/// Ohne Termin auf dem Handy nur ein schlanker Link „Prüfungstermin
/// eintragen“, breiter eine Zeile mit „Wann ist deine Prüfung?“. Mit Termin der
/// Plan: verbleibende Tage, Tagesziel mit Balken und eine Statuszeile mit
/// Ampel. Der Block sitzt auf dem dunklen Petrol-Verlauf, Schrift weiß.
class PlanBlock extends StatefulWidget {
  const PlanBlock({super.key});

  @override
  State<PlanBlock> createState() => _PlanBlockState();
}

class _PlanBlockState extends State<PlanBlock> {
  // Der Block ist `const` in der Heute-Karte eingebaut und würde deshalb beim
  // Neuaufbau der Seite übersprungen – er hört selbst auf Lernstand und Termin.
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_neu);
    Lernplan.instance.addListener(_neu);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_neu);
    Lernplan.instance.removeListener(_neu);
    super.dispose();
  }

  void _neu() {
    if (mounted) setState(() {});
  }

  static Color _weiss(double a) => Colors.white.withValues(alpha: a);

  /// Grün des Balkens wie der Ring der Heute-Karte bei „prüfungsreif“.
  static const Color _balkenGruen = Color(0xFF8FE3AA);

  void _bearbeiten() => terminBearbeiten(context);

  /// Unter dieser nutzbaren Höhe (ohne Status- und Gestenleiste) wird der
  /// Plan noch knapper, damit die Startseite ohne Scrollen bleibt (375 × 667).
  static const double _niedrig = 720;

  @override
  Widget build(BuildContext context) {
    final groesse = MediaQuery.sizeOf(context);
    final handy = groesse.width <= 560;
    final knapp = handy && groesse.height - MediaQuery.paddingOf(context).vertical < _niedrig;
    final plan = Lernplan.instance;
    final t = plan.termin;
    if (t == null) return handy ? _link() : _leerZeile();
    final p = plan.rechnen()!;
    final am = datumLang(p.pruefung);

    final List<Widget> inhalt;
    if (p.tage < 0) {
      inhalt = [
        Text('PRÜFUNG VORBEI', style: dispStyle(16, color: Colors.white, height: 1.2)),
        Padding(
          padding: EdgeInsets.fromLTRB(0, handy ? 3 : 5, 0, handy ? 7 : 10),
          child: Text('Deine Prüfung war am $am. Steht ein neuer Termin an?', style: _txt),
        ),
        _knopf('Neuen Termin eintragen'),
      ];
    } else if (p.tage == 0) {
      inhalt = [
        _kopf('Heute ist Prüfung', null, handy),
        Padding(
          padding: EdgeInsets.only(top: handy ? 3 : 5),
          child: Text('Viel Erfolg! Kurz vorher helfen die fälligen Fragen mehr als neuer Stoff.', style: _txt),
        ),
      ];
    } else {
      final status = planStatus(p, schwerpunkte: !knapp);
      inhalt = [
        _kopf(p.tage == 1 ? 'Morgen ist Prüfung' : 'Noch ${fmtN(p.tage)} Tage', p.tage == 1 ? am : 'bis zur Prüfung am $am',
            handy, knapp: knapp),
        if (p.ziel > 0) _zielZeile(p.geschafft, p.ziel, handy, knapp: knapp),
        _statusZeile(status.ampel, status.text, handy, knapp: knapp),
      ];
    }
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: knapp ? 8 : (handy ? 10 : 14)),
      padding: knapp
          ? const EdgeInsets.fromLTRB(11, 7, 11, 8)
          : (handy ? const EdgeInsets.fromLTRB(11, 9, 11, 10) : const EdgeInsets.fromLTRB(14, 12, 14, 13)),
      decoration: BoxDecoration(
        color: _weiss(0.08),
        border: Border.all(color: _weiss(0.17)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Semantics(
        liveRegion: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: inhalt),
      ),
    );
  }

  TextStyle get _txt => TextStyle(fontSize: 12.5, height: 1.45, color: _weiss(0.86));

  /// „Noch 42 Tage“ + Datum, rechts „ändern“.
  Widget _kopf(String tage, String? datum, bool handy, {bool knapp = false}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(tage.toUpperCase(), style: dispStyle(knapp ? 17 : (handy ? 18 : 23), color: Colors.white, height: 1.05)),
            if (datum != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(datum, style: TextStyle(fontSize: 12, height: 1.2, color: _weiss(0.8))),
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Semantics(
        button: true,
        label: 'Prüfungstermin ändern',
        excludeSemantics: true,
        child: InkWell(
          onTap: _bearbeiten,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: Text('ändern',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _weiss(0.88),
                  decoration: TextDecoration.underline,
                  decorationColor: _weiss(0.88),
                )),
          ),
        ),
      ),
    ]);
  }

  /// „Heute · 20 / 142 · Balken · Fragen“.
  Widget _zielZeile(int geschafft, int ziel, bool handy, {bool knapp = false}) {
    final klein = TextStyle(fontSize: 12, color: _weiss(0.86));
    final g = geschafft > 99999 ? 99999 : geschafft;
    return Padding(
      padding: EdgeInsets.only(top: knapp ? 5 : (handy ? 8 : 10)),
      child: Row(children: [
        Text('Heute', style: klein),
        const SizedBox(width: 9),
        Text('${fmtN(g)} / ${fmtN(ziel)}',
            style: monoStyle(14, color: Colors.white, weight: FontWeight.w600, spacing: 0)),
        const SizedBox(width: 9),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 60),
            child: Balken(geschafft / ziel, hoehe: 7, farbe: _balkenGruen, spur: _weiss(0.18)),
          ),
        ),
        const SizedBox(width: 9),
        Text('Fragen', style: klein),
      ]),
    );
  }

  Widget _statusZeile(Ampel amp, String text, bool handy, {bool knapp = false}) {
    return Padding(
      padding: EdgeInsets.only(top: knapp ? 5 : (handy ? 7 : 9)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: ampelFarbe(amp),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _weiss(0.2), spreadRadius: 3)],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.45, color: _weiss(0.9)))),
      ]),
    );
  }

  /// Heller Knopf auf dem Verlauf (Web `.plan-btn`).
  Widget _knopf(String text, {double hoehe = 38, double schrift = 13}) {
    return OutlinedButton(
      onPressed: _bearbeiten,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _weiss(0.12),
        side: BorderSide(color: _weiss(0.35)),
        minimumSize: Size(0, hoehe),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(fontFamily: 'Inter', fontSize: schrift, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
  }

  /// Handy ohne Termin: nur ein unterstrichener Link unter „Jetzt lernen“.
  Widget _link() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: 'Prüfungstermin eintragen',
        child: InkWell(
          onTap: _bearbeiten,
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Text('Prüfungstermin eintragen',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _weiss(0.9),
                    decoration: TextDecoration.underline,
                    decorationColor: _weiss(0.9),
                  )),
            ),
          ),
        ),
      ),
    );
  }

  /// Breiter ohne Termin: eine Zeile „Wann ist deine Prüfung?“ mit Knopf.
  Widget _leerZeile() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: _weiss(0.08),
        border: Border.all(color: _weiss(0.17)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          Text('WANN IST DEINE PRÜFUNG?', style: dispStyle(13.5, color: Colors.white, height: 1.2)),
          _knopf('Prüfungstermin eintragen', hoehe: 34, schrift: 12.5),
        ],
      ),
    );
  }
}
