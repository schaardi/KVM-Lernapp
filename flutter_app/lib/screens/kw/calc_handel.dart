import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';

/// Bezugskalkulation (Einkauf) und Handelskalkulation (Verkauf) im
/// durchgehenden Schema vom Listeneinkaufs- zum Listenverkaufspreis.
class HandelCalc extends StatefulWidget {
  const HandelCalc({super.key});
  @override
  State<HandelCalc> createState() => _HandelCalcState();
}

class _HandelCalcState extends State<HandelCalc> {
  final lep = TextEditingController();
  final liefRabatt = TextEditingController();
  final liefSkonto = TextEditingController();
  final bezugskosten = TextEditingController();

  final handlungskosten = TextEditingController(); // in % vom Bezugspreis
  final gewinn = TextEditingController();
  final kdSkonto = TextEditingController();
  final kdRabatt = TextEditingController();
  final ust = TextEditingController(text: '19');

  List<TextEditingController> get _all => [
        lep, liefRabatt, liefSkonto, bezugskosten,
        handlungskosten, gewinn, kdSkonto, kdRabatt, ust,
      ];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() => setState(() {
        for (final c in _all) {
          c.clear();
        }
        ust.text = '19';
      });

  void _loadExample() => setState(() {
        lep.text = '1.000';
        liefRabatt.text = '20';
        liefSkonto.text = '2';
        bezugskosten.text = '46';
        handlungskosten.text = '35';
        gewinn.text = '20';
        kdSkonto.text = '3';
        kdRabatt.text = '10';
        ust.text = '19';
      });

  // Bezugskalkulation
  double get _zielEk => v(lep) * (100 - v(liefRabatt)) / 100;
  double get _barEk => _zielEk * (100 - v(liefSkonto)) / 100;
  double get _bezugspreis => _barEk + v(bezugskosten);

  // Handelskalkulation
  double get _handlungskostenBetrag => _bezugspreis * v(handlungskosten) / 100;
  double get _selbstkosten => _bezugspreis + _handlungskostenBetrag;
  double get _gewinnBetrag => _selbstkosten * v(gewinn) / 100;
  double get _barVk => _selbstkosten + _gewinnBetrag;
  double get _zielVk {
    final s = v(kdSkonto);
    return s >= 100 ? double.nan : _barVk / (100 - s) * 100;
  }

  double get _listenVk {
    final r = v(kdRabatt);
    return r >= 100 ? double.nan : _zielVk / (100 - r) * 100;
  }

  double get _brutto => _listenVk * (1 + v(ust) / 100);
  double get _handelsspanne =>
      _listenVk.isNaN || _listenVk == 0
          ? double.nan
          : (_listenVk - _bezugspreis) / _listenVk * 100;
  double get _kalkZuschlag =>
      _bezugspreis == 0 ? double.nan : (_listenVk - _bezugspreis) / _bezugspreis * 100;

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});

    return CalcScaffold(
      title: 'Handelskalkulation',
      subtitle: 'Bezugspreis · Verkaufspreis · Handelsspanne',
      onReset: _reset,
      children: [
        CalcCard(
          title: 'Bezugskalkulation (Einkauf)',
          subtitle: 'Was kostet die Ware wirklich im Lager?',
          trailing: ExampleButton(onPressed: _loadExample),
          child: Column(children: [
            SchemeLine(
              label: 'Listeneinkaufspreis',
              field: NumField(controller: lep, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '−',
              label: 'Liefererrabatt',
              percent: NumField(
                  controller: liefRabatt, onChanged: up, suffix: '%', width: 62),
              value: v(lep) - _zielEk,
            ),
            SchemeLine(op: '=', label: 'Zieleinkaufspreis', value: _zielEk, sub: true),
            SchemeLine(
              op: '−',
              label: 'Liefererskonto',
              percent: NumField(
                  controller: liefSkonto, onChanged: up, suffix: '%', width: 62),
              value: _zielEk - _barEk,
            ),
            SchemeLine(op: '=', label: 'Bareinkaufspreis', value: _barEk, sub: true),
            SchemeLine(
              op: '+',
              label: 'Bezugskosten',
              note: 'Fracht, Verpackung, Versicherung',
              field: NumField(controller: bezugskosten, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Bezugspreis (Einstandspreis)',
              value: _bezugspreis,
              total: true,
              accent: kPetrol,
            ),
          ]),
        ),

        CalcCard(
          title: 'Verkaufskalkulation',
          subtitle: 'Vom Einstandspreis zum Listenverkaufspreis',
          child: Column(children: [
            SchemeLine(label: 'Bezugspreis', value: _bezugspreis),
            SchemeLine(
              op: '+',
              label: 'Handlungskosten',
              note: 'Zuschlag auf den Bezugspreis',
              percent: NumField(
                  controller: handlungskosten,
                  onChanged: up,
                  suffix: '%',
                  width: 62),
              value: _handlungskostenBetrag,
            ),
            SchemeLine(
                op: '=', label: 'Selbstkosten', value: _selbstkosten, sub: true),
            SchemeLine(
              op: '+',
              label: 'Gewinnzuschlag',
              percent: NumField(
                  controller: gewinn, onChanged: up, suffix: '%', width: 62),
              value: _gewinnBetrag,
            ),
            SchemeLine(op: '=', label: 'Barverkaufspreis', value: _barVk, sub: true),
            SchemeLine(
              op: '+',
              label: 'Kundenskonto',
              note: 'im Hundert',
              percent: NumField(
                  controller: kdSkonto, onChanged: up, suffix: '%', width: 62),
              value: _zielVk.isNaN ? null : _zielVk - _barVk,
            ),
            SchemeLine(
              op: '=',
              label: 'Zielverkaufspreis',
              value: _zielVk.isNaN ? null : _zielVk,
              sub: true,
            ),
            SchemeLine(
              op: '+',
              label: 'Kundenrabatt',
              note: 'im Hundert',
              percent: NumField(
                  controller: kdRabatt, onChanged: up, suffix: '%', width: 62),
              value: _listenVk.isNaN ? null : _listenVk - _zielVk,
            ),
            SchemeLine(
              op: '=',
              label: 'Listenverkaufspreis (netto)',
              value: _listenVk.isNaN ? null : _listenVk,
              total: true,
              accent: kOk,
            ),
            SchemeLine(
              op: '+',
              label: 'Umsatzsteuer',
              percent:
                  NumField(controller: ust, onChanged: up, suffix: '%', width: 62),
              value: _listenVk.isNaN ? null : _brutto - _listenVk,
            ),
            SchemeLine(
              op: '=',
              label: 'Bruttoverkaufspreis',
              value: _brutto.isNaN ? null : _brutto,
              total: true,
            ),
          ]),
        ),

        CalcCard(
          title: 'Kennzahlen des Handels',
          child: Row(children: [
            Expanded(
              child: ResultTile(
                label: 'Handelsspanne',
                value: _handelsspanne.isNaN ? '–' : fmtPct(_handelsspanne),
                color: kOk,
                hint: 'bezogen auf den Verkaufspreis',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ResultTile(
                label: 'Kalkulationszuschlag',
                value: _kalkZuschlag.isNaN ? '–' : fmtPct(_kalkZuschlag),
                color: kAmber,
                hint: 'bezogen auf den Bezugspreis',
              ),
            ),
          ]),
        ),

        StepsPanel(steps: [
          'Zieleinkaufspreis = Listeneinkaufspreis − Liefererrabatt (vom Hundert) '
              '= ${fmtEur(_zielEk)}',
          'Bareinkaufspreis = Zieleinkaufspreis − Liefererskonto = ${fmtEur(_barEk)}',
          'Bezugspreis = Bareinkaufspreis + Bezugskosten = ${fmtEur(_bezugspreis)}',
          'Selbstkosten = Bezugspreis + Handlungskosten = ${fmtEur(_selbstkosten)}',
          'Barverkaufspreis = Selbstkosten + Gewinn = ${fmtEur(_barVk)}',
          'Zielverkaufspreis = Barverkaufspreis ÷ (100 − Kundenskonto) × 100 '
              '= ${_zielVk.isNaN ? '–' : fmtEur(_zielVk)}',
          'Listenverkaufspreis = Zielverkaufspreis ÷ (100 − Kundenrabatt) × 100 '
              '= ${_listenVk.isNaN ? '–' : fmtEur(_listenVk)}',
        ]),

        const InfoBox(
          color: kErr,
          icon: Icons.warning_amber_rounded,
          title: 'Merke die Richtung',
          text: 'Im Einkauf wird abgezogen („vom Hundert" – multiplizieren), im '
              'Verkauf wird aufgeschlagen („im Hundert" – dividieren). '
              'Handelsspanne bezieht sich auf den Verkaufspreis, der '
              'Kalkulationszuschlag auf den Bezugspreis – deshalb sind die '
              'Prozentzahlen unterschiedlich groß.',
        ),
      ],
    );
  }
}
