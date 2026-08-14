import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';

/// Kalkulatorische Kosten: Abschreibung, Zinsen, Wagnis – plus
/// Maschinenstundensatz.
class KalkKostenCalc extends StatefulWidget {
  const KalkKostenCalc({super.key});
  @override
  State<KalkKostenCalc> createState() => _KalkKostenCalcState();
}

class _KalkKostenCalcState extends State<KalkKostenCalc> {
  // Abschreibung
  final wbw = TextEditingController();
  final restwert = TextEditingController();
  final nd = TextEditingController();
  final degSatz = TextEditingController();
  final gesLeistung = TextEditingController();
  final periodenLeistung = TextEditingController();
  int _absMode = 0; // 0 linear · 1 degressiv · 2 leistungsbezogen

  // Zinsen
  final vermoegen = TextEditingController();
  final abzugskapital = TextEditingController();
  final zinssatz = TextEditingController();

  // Wagnis
  final verluste = TextEditingController();
  final bezugVergangen = TextEditingController();
  final bezugPlan = TextEditingController();

  // Maschinenstundensatz
  final mLaufzeit = TextEditingController();
  final mRaum = TextEditingController();
  final mEnergie = TextEditingController();
  final mInstand = TextEditingController();
  final mWerkzeug = TextEditingController();

  List<TextEditingController> get _all => [
        wbw, restwert, nd, degSatz, gesLeistung, periodenLeistung,
        vermoegen, abzugskapital, zinssatz,
        verluste, bezugVergangen, bezugPlan,
        mLaufzeit, mRaum, mEnergie, mInstand, mWerkzeug,
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
      });

  void _loadExample() => setState(() {
        wbw.text = '120.000';
        restwert.text = '20.000';
        nd.text = '10';
        degSatz.text = '20';
        gesLeistung.text = '40.000';
        periodenLeistung.text = '4.500';
        vermoegen.text = '800.000';
        abzugskapital.text = '150.000';
        zinssatz.text = '6';
        verluste.text = '32.000';
        bezugVergangen.text = '4.000.000';
        bezugPlan.text = '1.200.000';
        mLaufzeit.text = '1.600';
        mRaum.text = '4.800';
        mEnergie.text = '9.600';
        mInstand.text = '7.200';
        mWerkzeug.text = '2.400';
      });

  // Abschreibung
  double get _absVolumen => v(wbw) - v(restwert);
  double get _absLinear => v(nd) == 0 ? double.nan : _absVolumen / v(nd);
  double get _absDegressiv => v(wbw) * v(degSatz) / 100;
  double get _absLeistung => v(gesLeistung) == 0
      ? double.nan
      : _absVolumen / v(gesLeistung) * v(periodenLeistung);
  double get _abschreibung => switch (_absMode) {
        0 => _absLinear,
        1 => _absDegressiv,
        _ => _absLeistung,
      };

  // Zinsen
  double get _bnk => v(vermoegen) - v(abzugskapital);
  double get _zinsen => _bnk * v(zinssatz) / 100;
  double get _durchschnittKapital => (v(wbw) + v(restwert)) / 2;

  // Wagnis
  double get _wagnissatz => v(bezugVergangen) == 0
      ? double.nan
      : v(verluste) / v(bezugVergangen) * 100;
  double get _wagnisBetrag =>
      _wagnissatz.isNaN ? double.nan : v(bezugPlan) * _wagnissatz / 100;

  // Maschinenstundensatz
  double get _maschinenKosten =>
      (_abschreibung.isNaN ? 0 : _abschreibung) +
      _durchschnittKapital * v(zinssatz) / 100 +
      v(mRaum) + v(mEnergie) + v(mInstand) + v(mWerkzeug);
  double get _mss =>
      v(mLaufzeit) == 0 ? double.nan : _maschinenKosten / v(mLaufzeit);

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});

    return CalcScaffold(
      title: 'Kalkulatorische Kosten',
      subtitle: 'Abschreibung · Zinsen · Wagnis · Maschinensatz',
      onReset: _reset,
      children: [
        CalcCard(
          title: 'Kalkulatorische Abschreibung',
          subtitle: 'Basis ist der Wiederbeschaffungswert',
          trailing: ExampleButton(onPressed: _loadExample),
          child: Column(children: [
            ModeSwitch(
              labels: const ['Linear', 'Degressiv', 'Leistung'],
              index: _absMode,
              onChanged: (i) => setState(() => _absMode = i),
            ),
            SchemeLine(
              label: 'Wiederbeschaffungswert',
              field: NumField(controller: wbw, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '−',
              label: 'Restwert am Ende',
              field: NumField(controller: restwert, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
                op: '=', label: 'Abschreibungsvolumen', value: _absVolumen, sub: true),
            if (_absMode == 0)
              SchemeLine(
                label: 'Nutzungsdauer',
                field: NumField(controller: nd, onChanged: up, suffix: 'J'),
              ),
            if (_absMode == 1)
              SchemeLine(
                label: 'Abschreibungssatz',
                note: 'vom aktuellen Buchwert',
                field: NumField(controller: degSatz, onChanged: up, suffix: '%'),
              ),
            if (_absMode == 2) ...[
              SchemeLine(
                label: 'Gesamtleistung',
                field:
                    NumField(controller: gesLeistung, onChanged: up, suffix: 'h'),
              ),
              SchemeLine(
                label: 'Leistung der Periode',
                field: NumField(
                    controller: periodenLeistung, onChanged: up, suffix: 'h'),
              ),
            ],
            SchemeLine(
              op: '=',
              label: 'Abschreibung der Periode',
              value: _abschreibung.isNaN ? null : _abschreibung,
              total: true,
              accent: kPetrol,
            ),
          ]),
        ),

        CalcCard(
          title: 'Kalkulatorische Zinsen',
          subtitle: 'Verzinsung des betriebsnotwendigen Kapitals',
          child: Column(children: [
            SchemeLine(
              label: 'Betriebsnotwendiges Vermögen',
              field: NumField(controller: vermoegen, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '−',
              label: 'Abzugskapital',
              note: 'zinsfrei überlassen',
              field:
                  NumField(controller: abzugskapital, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
                op: '=',
                label: 'Betriebsnotwendiges Kapital',
                value: _bnk,
                sub: true),
            SchemeLine(
              op: '×',
              label: 'Kalkulatorischer Zinssatz',
              field: NumField(controller: zinssatz, onChanged: up, suffix: '%'),
            ),
            SchemeLine(
              op: '=',
              label: 'Kalkulatorische Zinsen',
              value: _zinsen,
              total: true,
              accent: kPetrol,
            ),
            const SizedBox(height: 10),
            ResultTile(
              label: 'Durchschnittlich gebundenes Kapital der Anlage',
              value: fmtEur(_durchschnittKapital),
              color: kInkSoft,
              hint: '(Wiederbeschaffungswert + Restwert) ÷ 2',
            ),
          ]),
        ),

        CalcCard(
          title: 'Kalkulatorische Wagnisse',
          subtitle: 'Durchschnitt mehrerer Jahre auf das Planjahr übertragen',
          child: Column(children: [
            SchemeLine(
              label: 'Wagnisverluste der Vorjahre',
              field: NumField(controller: verluste, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Bezugsgröße der Vorjahre',
              note: 'z. B. Umsatz derselben Jahre',
              field:
                  NumField(controller: bezugVergangen, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Wagnissatz',
              display: _wagnissatz.isNaN ? '–' : fmtPct(_wagnissatz),
              sub: true,
            ),
            SchemeLine(
              label: 'Bezugsgröße im Planjahr',
              field: NumField(controller: bezugPlan, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Kalkulatorisches Wagnis',
              value: _wagnisBetrag.isNaN ? null : _wagnisBetrag,
              total: true,
              accent: kAmber,
            ),
          ]),
        ),

        CalcCard(
          title: 'Maschinenstundensatz',
          subtitle: 'Maschinenabhängige Kosten je Laufstunde',
          child: Column(children: [
            SchemeLine(
              label: 'Kalk. Abschreibung',
              note: 'aus dem Feld oben',
              value: _abschreibung.isNaN ? 0 : _abschreibung,
            ),
            SchemeLine(
              op: '+',
              label: 'Kalk. Zinsen der Maschine',
              note: 'gebundenes Kapital × Zinssatz',
              value: _durchschnittKapital * v(zinssatz) / 100,
            ),
            SchemeLine(
              op: '+',
              label: 'Raumkosten',
              field: NumField(controller: mRaum, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '+',
              label: 'Energiekosten',
              field: NumField(controller: mEnergie, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '+',
              label: 'Instandhaltung',
              field: NumField(controller: mInstand, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '+',
              label: 'Werkzeugkosten',
              field: NumField(controller: mWerkzeug, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
                op: '=',
                label: 'Maschinenkosten pro Jahr',
                value: _maschinenKosten,
                sub: true),
            SchemeLine(
              op: '÷',
              label: 'Maschinenlaufstunden pro Jahr',
              field: NumField(controller: mLaufzeit, onChanged: up, suffix: 'h'),
            ),
            const SizedBox(height: 10),
            ResultTile(
              label: 'Maschinenstundensatz',
              value: _mss.isNaN ? '–' : '${fmtNum(_mss)} €/h',
              color: kOk,
              hint: 'für die Fertigungskalkulation',
            ),
          ]),
        ),

        StepsPanel(steps: [
          'Lineare Abschreibung = (Wiederbeschaffungswert − Restwert) ÷ Nutzungsdauer '
              '= ${fmtEur(_absVolumen)} ÷ ${fmtNum(v(nd), dec: 0)} '
              '= ${_absLinear.isNaN ? '–' : fmtEur(_absLinear)}',
          'Betriebsnotwendiges Kapital = Vermögen − Abzugskapital = ${fmtEur(_bnk)}',
          'Kalkulatorische Zinsen = Kapital × Zinssatz = ${fmtEur(_zinsen)}',
          'Wagnissatz = Verluste ÷ Bezugsgröße × 100 '
              '= ${_wagnissatz.isNaN ? '–' : fmtPct(_wagnissatz)}',
          'Maschinenstundensatz = maschinenabhängige Kosten ÷ Laufstunden '
              '= ${fmtEur(_maschinenKosten)} ÷ ${fmtNum(v(mLaufzeit), dec: 0)} h '
              '= ${_mss.isNaN ? '–' : '${fmtNum(_mss)} €/h'}',
        ]),

        const InfoBox(
          color: kErr,
          icon: Icons.warning_amber_rounded,
          title: 'Prüfungsfalle',
          text: 'Die kalkulatorische Abschreibung rechnet mit dem '
              'Wiederbeschaffungswert und der tatsächlichen Nutzungsdauer – die '
              'bilanzielle mit Anschaffungswert und AfA-Tabelle. Über die '
              'Nutzungsdauer darf kalkulatorisch mehr abgeschrieben werden als '
              'die Anschaffung gekostet hat.',
        ),
      ],
    );
  }
}
