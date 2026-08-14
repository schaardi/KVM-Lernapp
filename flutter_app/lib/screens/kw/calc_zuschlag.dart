import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';
import '../../services/kw_bridge.dart';

/// Differenzierende Zuschlagskalkulation + Angebotskalkulation
/// (vorwärts · rückwärts · Differenz) – im Original-Prüfungsschema.
class ZuschlagCalc extends StatefulWidget {
  const ZuschlagCalc({super.key});
  @override
  State<ZuschlagCalc> createState() => _ZuschlagCalcState();
}

class _ZuschlagCalcState extends State<ZuschlagCalc> {
  // Kostenschema
  final fm = TextEditingController();
  final mgk = TextEditingController();
  final fl = TextEditingController();
  final fgk = TextEditingController();
  final sef = TextEditingController();
  final vwgk = TextEditingController();
  final vtgk = TextEditingController();
  final sev = TextEditingController();
  // Angebot
  final gewinn = TextEditingController();
  final skonto = TextEditingController();
  final rabatt = TextEditingController();
  final ust = TextEditingController(text: '19');
  final lvpIn = TextEditingController(); // für rückwärts / Differenz
  final menge = TextEditingController();

  int _mode = 0; // 0 vorwärts · 1 rückwärts · 2 Differenz

  @override
  void initState() {
    super.initState();
    if (KwRates.hasValues) _applyRates();
  }

  void _applyRates() {
    if (KwRates.mgk != null) mgk.text = fmtNum(KwRates.mgk!);
    if (KwRates.fgk != null) fgk.text = fmtNum(KwRates.fgk!);
    if (KwRates.vwgk != null) vwgk.text = fmtNum(KwRates.vwgk!);
    if (KwRates.vtgk != null) vtgk.text = fmtNum(KwRates.vtgk!);
  }

  @override
  void dispose() {
    for (final c in [
      fm, mgk, fl, fgk, sef, vwgk, vtgk, sev,
      gewinn, skonto, rabatt, ust, lvpIn, menge,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    setState(() {
      for (final c in [
        fm, mgk, fl, fgk, sef, vwgk, vtgk, sev,
        gewinn, skonto, rabatt, lvpIn, menge,
      ]) {
        c.clear();
      }
      ust.text = '19';
    });
  }

  void _loadExample() {
    setState(() {
      fm.text = '40.000';
      mgk.text = '15';
      fl.text = '25.000';
      fgk.text = '210';
      sef.text = '2.500';
      vwgk.text = '6';
      vtgk.text = '4';
      sev.text = '1.800';
      gewinn.text = '12';
      skonto.text = '3';
      rabatt.text = '10';
      ust.text = '19';
      menge.text = '500';
      lvpIn.text = '250.000';
    });
  }

  // ── Rechnung ───────────────────────────────────────────────────────────────
  double get _fm => v(fm);
  double get _mgkBetrag => _fm * v(mgk) / 100;
  double get _mk => _fm + _mgkBetrag;
  double get _fl => v(fl);
  double get _fgkBetrag => _fl * v(fgk) / 100;
  double get _fk => _fl + _fgkBetrag + v(sef);
  double get _hk => _mk + _fk;
  double get _vwgkBetrag => _hk * v(vwgk) / 100;
  double get _vtgkBetrag => _hk * v(vtgk) / 100;
  double get _sk => _hk + _vwgkBetrag + _vtgkBetrag + v(sev);

  // vorwärts: Selbstkosten -> Listenverkaufspreis
  double get _gewinnBetrag => _sk * v(gewinn) / 100;
  double get _bvpVor => _sk + _gewinnBetrag;
  double get _zvpVor {
    final s = v(skonto);
    return s >= 100 ? double.nan : _bvpVor / (100 - s) * 100;
  }

  double get _lvpVor {
    final r = v(rabatt);
    return r >= 100 ? double.nan : _zvpVor / (100 - r) * 100;
  }

  double get _bruttoVor => _lvpVor * (1 + v(ust) / 100);

  // rückwärts: Listenverkaufspreis -> maximale Selbstkosten
  double get _zvpRueck => v(lvpIn) * (100 - v(rabatt)) / 100;
  double get _bvpRueck => _zvpRueck * (100 - v(skonto)) / 100;
  double get _skMax {
    final g = v(gewinn);
    return _bvpRueck / (100 + g) * 100;
  }

  // Differenz: Preis und Kosten gegeben -> tatsächlicher Gewinn
  double get _gewinnDiff => _bvpRueck - _sk;
  double get _gewinnDiffProzent => _sk == 0 ? double.nan : _gewinnDiff / _sk * 100;

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});
    final st = v(menge);

    return CalcScaffold(
      title: 'Zuschlagskalkulation',
      subtitle: 'Selbstkosten · Angebotspreis',
      onReset: _reset,
      children: [
        ModeSwitch(
          labels: const ['Vorwärts', 'Rückwärts', 'Differenz'],
          index: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        InfoBox(
          color: _mode == 0 ? kPetrol : (_mode == 1 ? kAmber : kDue),
          icon: Icons.route_outlined,
          title: _mode == 0
              ? 'Vorwärtskalkulation'
              : (_mode == 1 ? 'Rückwärtskalkulation' : 'Differenzkalkulation'),
          text: _mode == 0
              ? 'Du kennst deine Kosten und suchst den Verkaufspreis. Skonto und '
                  'Rabatt werden „im Hundert" herausgerechnet.'
              : (_mode == 1
                  ? 'Der Marktpreis steht fest. Gesucht sind die Selbstkosten, '
                      'die du höchstens haben darfst (Zielkosten).'
                  : 'Kosten und Marktpreis stehen fest. Gesucht ist der Gewinn, '
                      'der dabei übrig bleibt.'),
        ),

        CalcCard(
          title: 'Kostenschema',
          subtitle: 'Einzelkosten eintragen, Zuschlagssätze in Prozent',
          trailing: ExampleButton(onPressed: _loadExample),
          child: Column(children: [
            SchemeLine(
              label: 'Fertigungsmaterial (FM)',
              field: NumField(controller: fm, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '+',
              label: 'Materialgemeinkosten',
              percent: NumField(
                  controller: mgk, onChanged: up, suffix: '%', width: 62),
              value: _mgkBetrag,
            ),
            SchemeLine(op: '=', label: 'Materialkosten (MK)', value: _mk, sub: true),
            const SizedBox(height: 10),
            SchemeLine(
              label: 'Fertigungslöhne (FL)',
              field: NumField(controller: fl, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '+',
              label: 'Fertigungsgemeinkosten',
              percent: NumField(
                  controller: fgk, onChanged: up, suffix: '%', width: 62),
              value: _fgkBetrag,
            ),
            SchemeLine(
              op: '+',
              label: 'Sondereinzelkosten Fertigung',
              field: NumField(controller: sef, onChanged: up, suffix: '€'),
            ),
            SchemeLine(op: '=', label: 'Fertigungskosten (FK)', value: _fk, sub: true),
            const SizedBox(height: 10),
            SchemeLine(
              op: '=',
              label: 'Herstellkosten (HK)',
              value: _hk,
              total: true,
              accent: kPetrol,
            ),
            SchemeLine(
              op: '+',
              label: 'Verwaltungsgemeinkosten',
              note: 'auf die Herstellkosten',
              percent: NumField(
                  controller: vwgk, onChanged: up, suffix: '%', width: 62),
              value: _vwgkBetrag,
            ),
            SchemeLine(
              op: '+',
              label: 'Vertriebsgemeinkosten',
              note: 'auf die Herstellkosten',
              percent: NumField(
                  controller: vtgk, onChanged: up, suffix: '%', width: 62),
              value: _vtgkBetrag,
            ),
            SchemeLine(
              op: '+',
              label: 'Sondereinzelkosten Vertrieb',
              field: NumField(controller: sev, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Selbstkosten (SK)',
              value: _sk,
              total: true,
              accent: kPetrolDeep,
            ),
          ]),
        ),

        if (_mode == 0) _vorwaerts(up, st),
        if (_mode == 1) _rueckwaerts(up),
        if (_mode == 2) _differenz(up),

        CalcCard(
          title: 'Je Stück',
          subtitle: 'Optional – Stückzahl eintragen',
          child: Column(children: [
            SchemeLine(
              label: 'Stückzahl',
              field: NumField(controller: menge, onChanged: up, suffix: 'Stk'),
            ),
            SchemeLine(
              op: '=',
              label: 'Selbstkosten je Stück',
              value: st > 0 ? _sk / st : null,
              sub: true,
            ),
            if (_mode == 0)
              SchemeLine(
                op: '=',
                label: 'Listenverkaufspreis je Stück',
                value: st > 0 ? _lvpVor / st : null,
                sub: true,
              ),
          ]),
        ),

        StepsPanel(steps: _steps()),

        const InfoBox(
          color: kErr,
          icon: Icons.warning_amber_rounded,
          title: 'Prüfungsfalle',
          text: 'Skonto und Rabatt werden vorwärts nicht einfach aufgeschlagen. '
              'Sie beziehen sich auf den jeweils höheren Wert – deshalb wird '
              'geteilt („im Hundert"). Probe: Vom Ergebnis den Prozentsatz '
              'wieder abziehen, dann muss der Ausgangswert herauskommen.',
        ),
      ],
    );
  }

  Widget _vorwaerts(VoidCallback up, double st) {
    return CalcCard(
      title: 'Angebotskalkulation',
      subtitle: 'Von den Selbstkosten zum Verkaufspreis',
      child: Column(children: [
        SchemeLine(label: 'Selbstkosten (SK)', value: _sk),
        SchemeLine(
          op: '+',
          label: 'Gewinnzuschlag',
          percent:
              NumField(controller: gewinn, onChanged: up, suffix: '%', width: 62),
          value: _gewinnBetrag,
        ),
        SchemeLine(op: '=', label: 'Barverkaufspreis', value: _bvpVor, sub: true),
        SchemeLine(
          op: '+',
          label: 'Kundenskonto',
          note: 'im Hundert',
          percent:
              NumField(controller: skonto, onChanged: up, suffix: '%', width: 62),
          value: _zvpVor.isNaN ? null : _zvpVor - _bvpVor,
        ),
        SchemeLine(
          op: '=',
          label: 'Zielverkaufspreis',
          value: _zvpVor.isNaN ? null : _zvpVor,
          sub: true,
        ),
        SchemeLine(
          op: '+',
          label: 'Kundenrabatt',
          note: 'im Hundert',
          percent:
              NumField(controller: rabatt, onChanged: up, suffix: '%', width: 62),
          value: _lvpVor.isNaN ? null : _lvpVor - _zvpVor,
        ),
        SchemeLine(
          op: '=',
          label: 'Listenverkaufspreis (netto)',
          value: _lvpVor.isNaN ? null : _lvpVor,
          total: true,
          accent: kOk,
        ),
        SchemeLine(
          op: '+',
          label: 'Umsatzsteuer',
          percent: NumField(controller: ust, onChanged: up, suffix: '%', width: 62),
          value: _lvpVor.isNaN ? null : _bruttoVor - _lvpVor,
        ),
        SchemeLine(
          op: '=',
          label: 'Bruttoverkaufspreis',
          value: _bruttoVor.isNaN ? null : _bruttoVor,
          total: true,
        ),
      ]),
    );
  }

  Widget _rueckwaerts(VoidCallback up) {
    return CalcCard(
      title: 'Rückwärtskalkulation',
      subtitle: 'Vom Marktpreis zu den maximalen Selbstkosten',
      child: Column(children: [
        SchemeLine(
          label: 'Listenverkaufspreis (netto)',
          field: NumField(controller: lvpIn, onChanged: up, suffix: '€'),
        ),
        SchemeLine(
          op: '−',
          label: 'Kundenrabatt',
          note: 'vom Hundert',
          percent:
              NumField(controller: rabatt, onChanged: up, suffix: '%', width: 62),
          value: v(lvpIn) - _zvpRueck,
        ),
        SchemeLine(op: '=', label: 'Zielverkaufspreis', value: _zvpRueck, sub: true),
        SchemeLine(
          op: '−',
          label: 'Kundenskonto',
          note: 'vom Hundert',
          percent:
              NumField(controller: skonto, onChanged: up, suffix: '%', width: 62),
          value: _zvpRueck - _bvpRueck,
        ),
        SchemeLine(op: '=', label: 'Barverkaufspreis', value: _bvpRueck, sub: true),
        SchemeLine(
          op: '−',
          label: 'Gewinnzuschlag',
          note: 'im Hundert',
          percent:
              NumField(controller: gewinn, onChanged: up, suffix: '%', width: 62),
          value: _bvpRueck - _skMax,
        ),
        SchemeLine(
          op: '=',
          label: 'Höchstens zulässige Selbstkosten',
          value: _skMax,
          total: true,
          accent: kAmber,
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ResultTile(
              label: 'Deine Selbstkosten (Schema)',
              value: fmtEur(_sk),
              color: kPetrol,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ResultTile(
              label: _sk <= _skMax ? 'Spielraum' : 'Kostenüberhang',
              value: fmtEur((_skMax - _sk).abs()),
              color: _sk <= _skMax ? kOk : kErr,
              hint: _sk <= _skMax ? 'Preis ist tragbar' : 'zu teuer',
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _differenz(VoidCallback up) {
    return CalcCard(
      title: 'Differenzkalkulation',
      subtitle: 'Welcher Gewinn bleibt bei vorgegebenem Marktpreis?',
      child: Column(children: [
        SchemeLine(
          label: 'Listenverkaufspreis (netto)',
          field: NumField(controller: lvpIn, onChanged: up, suffix: '€'),
        ),
        SchemeLine(
          op: '−',
          label: 'Kundenrabatt',
          percent:
              NumField(controller: rabatt, onChanged: up, suffix: '%', width: 62),
          value: v(lvpIn) - _zvpRueck,
        ),
        SchemeLine(op: '=', label: 'Zielverkaufspreis', value: _zvpRueck, sub: true),
        SchemeLine(
          op: '−',
          label: 'Kundenskonto',
          percent:
              NumField(controller: skonto, onChanged: up, suffix: '%', width: 62),
          value: _zvpRueck - _bvpRueck,
        ),
        SchemeLine(op: '=', label: 'Barverkaufspreis', value: _bvpRueck, sub: true),
        SchemeLine(op: '−', label: 'Selbstkosten (aus dem Schema)', value: _sk),
        SchemeLine(
          op: '=',
          label: 'Gewinn',
          value: _gewinnDiff,
          total: true,
          accent: _gewinnDiff >= 0 ? kOk : kErr,
        ),
        const SizedBox(height: 12),
        ResultTile(
          label: 'Gewinnzuschlag in Prozent der Selbstkosten',
          value: _gewinnDiffProzent.isNaN ? '–' : fmtPct(_gewinnDiffProzent),
          color: _gewinnDiff >= 0 ? kOk : kErr,
          hint: _gewinnDiff >= 0
              ? 'Der Auftrag trägt sich.'
              : 'Der Preis deckt die Selbstkosten nicht.',
        ),
      ]),
    );
  }

  List<String> _steps() {
    final s = <String>[
      'Materialgemeinkosten = Fertigungsmaterial × MGK-Satz: '
          '${fmtEur(_fm)} × ${fmtNum(v(mgk))} % = ${fmtEur(_mgkBetrag)}',
      'Materialkosten = FM + MGK = ${fmtEur(_mk)}',
      'Fertigungsgemeinkosten = Fertigungslöhne × FGK-Satz: '
          '${fmtEur(_fl)} × ${fmtNum(v(fgk))} % = ${fmtEur(_fgkBetrag)}',
      'Fertigungskosten = FL + FGK + SEK Fertigung = ${fmtEur(_fk)}',
      'Herstellkosten = Materialkosten + Fertigungskosten = ${fmtEur(_hk)}',
      'Verwaltungs- und Vertriebsgemeinkosten jeweils auf die Herstellkosten: '
          '${fmtEur(_vwgkBetrag)} bzw. ${fmtEur(_vtgkBetrag)}',
      'Selbstkosten = HK + VwGK + VtGK + SEK Vertrieb = ${fmtEur(_sk)}',
    ];
    if (_mode == 0) {
      s.addAll([
        'Gewinn = Selbstkosten × ${fmtNum(v(gewinn))} % = ${fmtEur(_gewinnBetrag)}',
        'Barverkaufspreis = ${fmtEur(_bvpVor)}',
        'Zielverkaufspreis = Barverkaufspreis ÷ (100 − ${fmtNum(v(skonto))}) × 100 '
            '= ${_zvpVor.isNaN ? '–' : fmtEur(_zvpVor)}',
        'Listenverkaufspreis = Zielverkaufspreis ÷ (100 − ${fmtNum(v(rabatt))}) × 100 '
            '= ${_lvpVor.isNaN ? '–' : fmtEur(_lvpVor)}',
      ]);
    } else {
      s.addAll([
        'Zielverkaufspreis = Listenpreis × (100 − ${fmtNum(v(rabatt))}) ÷ 100 '
            '= ${fmtEur(_zvpRueck)}',
        'Barverkaufspreis = Zielverkaufspreis × (100 − ${fmtNum(v(skonto))}) ÷ 100 '
            '= ${fmtEur(_bvpRueck)}',
        if (_mode == 1)
          'Maximale Selbstkosten = Barverkaufspreis ÷ (100 + ${fmtNum(v(gewinn))}) × 100 '
              '= ${fmtEur(_skMax)}'
        else
          'Gewinn = Barverkaufspreis − Selbstkosten = ${fmtEur(_gewinnDiff)}',
      ]);
    }
    return s;
  }
}
