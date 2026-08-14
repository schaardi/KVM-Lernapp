import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';

/// Divisionskalkulation (ein-/zweistufig) und Äquivalenzziffernkalkulation.
class DivisionCalc extends StatefulWidget {
  const DivisionCalc({super.key});
  @override
  State<DivisionCalc> createState() => _DivisionCalcState();
}

class _Sorte {
  final TextEditingController name;
  final TextEditingController menge = TextEditingController();
  final TextEditingController az = TextEditingController();
  _Sorte(String label) : name = TextEditingController(text: label);
  void dispose() {
    name.dispose();
    menge.dispose();
    az.dispose();
  }
}

class _DivisionCalcState extends State<DivisionCalc> {
  int _mode = 0; // 0 einstufig · 1 zweistufig · 2 Äquivalenzziffern

  final gesamtkosten = TextEditingController();
  final mengeGesamt = TextEditingController();
  final hk = TextEditingController();
  final produktionsmenge = TextEditingController();
  final vwvt = TextEditingController();
  final absatzmenge = TextEditingController();
  final kostenAez = TextEditingController();

  final List<_Sorte> _sorten = [_Sorte('Sorte A'), _Sorte('Sorte B'), _Sorte('Sorte C')];

  @override
  void dispose() {
    for (final c in [
      gesamtkosten, mengeGesamt, hk, produktionsmenge, vwvt, absatzmenge, kostenAez,
    ]) {
      c.dispose();
    }
    for (final s in _sorten) {
      s.dispose();
    }
    super.dispose();
  }

  void _reset() => setState(() {
        for (final c in [
          gesamtkosten, mengeGesamt, hk, produktionsmenge, vwvt, absatzmenge,
          kostenAez,
        ]) {
          c.clear();
        }
        for (final s in _sorten) {
          s.menge.clear();
          s.az.clear();
        }
      });

  void _loadExample() => setState(() {
        gesamtkosten.text = '454.000';
        mengeGesamt.text = '20.000';
        hk.text = '400.000';
        produktionsmenge.text = '20.000';
        vwvt.text = '54.000';
        absatzmenge.text = '18.000';
        kostenAez.text = '231.000';
        const m = ['10.000', '8.000', '5.000'];
        const a = ['1,0', '1,3', '0,8'];
        for (var i = 0; i < _sorten.length && i < 3; i++) {
          _sorten[i].menge.text = m[i];
          _sorten[i].az.text = a[i];
        }
      });

  double get _kEinstufig =>
      v(mengeGesamt) == 0 ? double.nan : v(gesamtkosten) / v(mengeGesamt);
  double get _hkStueck =>
      v(produktionsmenge) == 0 ? double.nan : v(hk) / v(produktionsmenge);
  double get _vwvtStueck =>
      v(absatzmenge) == 0 ? double.nan : v(vwvt) / v(absatzmenge);
  double get _skZweistufig => _hkStueck + _vwvtStueck;

  double _re(_Sorte s) => v(s.menge) * v(s.az);
  double get _reSumme {
    var t = 0.0;
    for (final s in _sorten) {
      t += _re(s);
    }
    return t;
  }

  double get _kJeRe =>
      _reSumme == 0 ? double.nan : v(kostenAez) / _reSumme;

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});

    return CalcScaffold(
      title: 'Divisions- & Äquivalenzziffern',
      subtitle: 'Massen- und Sortenfertigung',
      onReset: _reset,
      children: [
        ModeSwitch(
          labels: const ['Einstufig', 'Zweistufig', 'Äquivalenz'],
          index: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),

        if (_mode == 0)
          CalcCard(
            title: 'Einstufige Divisionskalkulation',
            subtitle: 'Ein Produkt, keine Bestandsveränderung',
            trailing: ExampleButton(onPressed: _loadExample),
            child: Column(children: [
              SchemeLine(
                label: 'Gesamtkosten der Periode',
                field:
                    NumField(controller: gesamtkosten, onChanged: up, suffix: '€'),
              ),
              SchemeLine(
                op: '÷',
                label: 'Produzierte Menge',
                field:
                    NumField(controller: mengeGesamt, onChanged: up, suffix: 'Stk'),
              ),
              SchemeLine(
                op: '=',
                label: 'Selbstkosten je Stück',
                value: _kEinstufig.isNaN ? null : _kEinstufig,
                total: true,
                accent: kPetrol,
              ),
            ]),
          ),

        if (_mode == 1)
          CalcCard(
            title: 'Zweistufige Divisionskalkulation',
            subtitle: 'Produktions- und Absatzmenge weichen voneinander ab',
            trailing: ExampleButton(onPressed: _loadExample),
            child: Column(children: [
              SchemeLine(
                label: 'Herstellkosten',
                field: NumField(controller: hk, onChanged: up, suffix: '€'),
              ),
              SchemeLine(
                op: '÷',
                label: 'Produktionsmenge',
                field: NumField(
                    controller: produktionsmenge, onChanged: up, suffix: 'Stk'),
              ),
              SchemeLine(
                op: '=',
                label: 'Herstellkosten je Stück',
                value: _hkStueck.isNaN ? null : _hkStueck,
                sub: true,
              ),
              const SizedBox(height: 8),
              SchemeLine(
                label: 'Verwaltungs- und Vertriebskosten',
                field: NumField(controller: vwvt, onChanged: up, suffix: '€'),
              ),
              SchemeLine(
                op: '÷',
                label: 'Absatzmenge',
                field:
                    NumField(controller: absatzmenge, onChanged: up, suffix: 'Stk'),
              ),
              SchemeLine(
                op: '=',
                label: 'VwVt-Kosten je verkauftem Stück',
                value: _vwvtStueck.isNaN ? null : _vwvtStueck,
                sub: true,
              ),
              SchemeLine(
                op: '=',
                label: 'Selbstkosten je verkauftem Stück',
                value: _skZweistufig.isNaN ? null : _skZweistufig,
                total: true,
                accent: kPetrolDeep,
              ),
            ]),
          ),

        if (_mode == 2) ...[
          CalcCard(
            title: 'Äquivalenzziffernkalkulation',
            subtitle: 'Sortenfertigung – Standardsorte bekommt die Ziffer 1,0',
            trailing: ExampleButton(onPressed: _loadExample),
            child: Column(children: [
              SchemeLine(
                label: 'Gesamtkosten',
                field: NumField(controller: kostenAez, onChanged: up, suffix: '€'),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        SizedBox(width: 110, child: Text('Sorte',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kMuted))),
                        SizedBox(width: 96, child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('Menge',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: kMuted)),
                        )),
                        SizedBox(width: 78, child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('ÄZ',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: kMuted)),
                        )),
                        SizedBox(width: 96, child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('Rechn.-Einh.',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: kPetrolDeep)),
                        )),
                        SizedBox(width: 34),
                      ]),
                      const Divider(height: 10, color: kLine),
                      for (var i = 0; i < _sorten.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: _sorten[i].name,
                                style: const TextStyle(fontSize: 13, color: kInk),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: NumField(
                                  controller: _sorten[i].menge,
                                  onChanged: up,
                                  width: 90),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: NumField(
                                  controller: _sorten[i].az,
                                  onChanged: up,
                                  width: 72),
                            ),
                            SizedBox(
                              width: 96,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(fmtNum(_re(_sorten[i]), dec: 0),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: kPetrolDeep)),
                              ),
                            ),
                            SizedBox(
                              width: 34,
                              child: IconButton(
                                onPressed: _sorten.length > 1
                                    ? () => setState(() {
                                          final s = _sorten.removeAt(i);
                                          s.dispose();
                                        })
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 18, color: kMuted),
                              ),
                            ),
                          ]),
                        ),
                    ]),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                      () => _sorten.add(_Sorte('Sorte ${_sorten.length + 1}'))),
                  style: TextButton.styleFrom(foregroundColor: kPetrol),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Sorte ergänzen'),
                ),
              ),
              SchemeLine(
                op: '=',
                label: 'Summe Rechnungseinheiten',
                display: fmtNum(_reSumme, dec: 0),
                sub: true,
              ),
              SchemeLine(
                op: '=',
                label: 'Kosten je Rechnungseinheit',
                value: _kJeRe.isNaN ? null : _kJeRe,
                total: true,
                accent: kPetrol,
              ),
            ]),
          ),
          CalcCard(
            title: 'Stückkosten je Sorte',
            subtitle: 'Kosten je Rechnungseinheit × Äquivalenzziffer',
            child: Column(children: [
              for (final s in _sorten)
                SchemeLine(
                  label: s.name.text.isEmpty ? 'Sorte' : s.name.text,
                  note: 'ÄZ ${fmtNum(v(s.az), dec: 2)}',
                  value: _kJeRe.isNaN ? null : _kJeRe * v(s.az),
                ),
            ]),
          ),
        ],

        StepsPanel(steps: _mode == 2
            ? [
                'Rechnungseinheiten je Sorte = Menge × Äquivalenzziffer',
                'Summe aller Rechnungseinheiten = ${fmtNum(_reSumme, dec: 0)}',
                'Kosten je Rechnungseinheit = Gesamtkosten ÷ Σ RE = '
                    '${fmtEur(v(kostenAez))} ÷ ${fmtNum(_reSumme, dec: 0)} = '
                    '${_kJeRe.isNaN ? '–' : fmtEur(_kJeRe)}',
                'Stückkosten je Sorte = Kosten je RE × Äquivalenzziffer',
              ]
            : (_mode == 1
                ? [
                    'Herstellkosten je Stück = HK ÷ Produktionsmenge = '
                        '${_hkStueck.isNaN ? '–' : fmtEur(_hkStueck)}',
                    'VwVt je verkauftem Stück = VwVt-Kosten ÷ Absatzmenge = '
                        '${_vwvtStueck.isNaN ? '–' : fmtEur(_vwvtStueck)}',
                    'Selbstkosten je Stück = Summe beider Beträge = '
                        '${_skZweistufig.isNaN ? '–' : fmtEur(_skZweistufig)}',
                  ]
                : [
                    'Stückkosten = Gesamtkosten ÷ Menge = '
                        '${fmtEur(v(gesamtkosten))} ÷ ${fmtNum(v(mengeGesamt), dec: 0)} = '
                        '${_kEinstufig.isNaN ? '–' : fmtEur(_kEinstufig)}',
                  ])),

        const InfoBox(
          color: kAmber,
          icon: Icons.tips_and_updates_outlined,
          title: 'Wann welches Verfahren?',
          text: 'Ein einziges Massenprodukt → Division. Produktions- und '
              'Absatzmenge unterschiedlich → zweistufig, weil Verwaltung und '
              'Vertrieb nur für verkaufte Stücke anfallen. Artverwandte Sorten '
              'aus einem Prozess → Äquivalenzziffern.',
        ),
      ],
    );
  }
}
