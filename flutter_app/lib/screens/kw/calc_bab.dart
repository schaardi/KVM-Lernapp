import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';
import '../../services/kw_bridge.dart';

/// Betriebsabrechnungsbogen: Gemeinkosten auf vier Hauptkostenstellen
/// verteilen und daraus die Zuschlagssätze bilden.
class BabCalc extends StatefulWidget {
  const BabCalc({super.key});
  @override
  State<BabCalc> createState() => _BabCalcState();
}

class _GkRow {
  final TextEditingController name;
  final List<TextEditingController> cells;
  _GkRow(String label)
      : name = TextEditingController(text: label),
        cells = List.generate(4, (_) => TextEditingController());

  void dispose() {
    name.dispose();
    for (final c in cells) {
      c.dispose();
    }
  }
}

class _BabCalcState extends State<BabCalc> {
  static const _stellen = ['Material', 'Fertigung', 'Verwaltung', 'Vertrieb'];

  final List<_GkRow> _rows = [
    _GkRow('Hilfslöhne'),
    _GkRow('Gehälter'),
    _GkRow('Sozialkosten'),
    _GkRow('Energie'),
    _GkRow('Kalk. Abschreibungen'),
    _GkRow('Sonstige Gemeinkosten'),
  ];

  final mek = TextEditingController(); // Fertigungsmaterial
  final fl = TextEditingController(); // Fertigungslöhne

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    mek.dispose();
    fl.dispose();
    super.dispose();
  }

  double _sumSpalte(int i) {
    var s = 0.0;
    for (final r in _rows) {
      s += v(r.cells[i]);
    }
    return s;
  }

  double get _gkMaterial => _sumSpalte(0);
  double get _gkFertigung => _sumSpalte(1);
  double get _gkVerwaltung => _sumSpalte(2);
  double get _gkVertrieb => _sumSpalte(3);
  double get _gkGesamt =>
      _gkMaterial + _gkFertigung + _gkVerwaltung + _gkVertrieb;

  double get _hk => v(mek) + _gkMaterial + v(fl) + _gkFertigung;

  double get _satzMgk => v(mek) == 0 ? double.nan : _gkMaterial / v(mek) * 100;
  double get _satzFgk => v(fl) == 0 ? double.nan : _gkFertigung / v(fl) * 100;
  double get _satzVwgk => _hk == 0 ? double.nan : _gkVerwaltung / _hk * 100;
  double get _satzVtgk => _hk == 0 ? double.nan : _gkVertrieb / _hk * 100;

  void _reset() {
    setState(() {
      for (final r in _rows) {
        for (final c in r.cells) {
          c.clear();
        }
      }
      mek.clear();
      fl.clear();
    });
  }

  void _loadExample() {
    setState(() {
      const data = [
        ['4.000', '38.000', '2.000', '1.500'],
        ['6.000', '24.000', '15.000', '9.000'],
        ['2.400', '20.400', '4.200', '2.400'],
        ['1.200', '46.000', '900', '700'],
        ['3.600', '41.600', '3.200', '2.400'],
        ['6.800', '19.000', '2.420', '2.480'],
      ];
      for (var i = 0; i < _rows.length && i < data.length; i++) {
        for (var j = 0; j < 4; j++) {
          _rows[i].cells[j].text = data[i][j];
        }
      }
      mek.text = '160.000';
      fl.text = '90.000';
    });
  }

  void _addRow() => setState(() => _rows.add(_GkRow('Weitere Kostenart')));

  void _removeRow(int i) => setState(() {
        final r = _rows.removeAt(i);
        r.dispose();
      });

  void _uebernehmen() {
    if (_satzMgk.isNaN || _satzFgk.isNaN || _satzVwgk.isNaN || _satzVtgk.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Bitte zuerst Fertigungsmaterial und Fertigungslöhne eintragen.')));
      return;
    }
    KwRates.set(
      mgkSatz: _satzMgk,
      fgkSatz: _satzFgk,
      vwgkSatz: _satzVwgk,
      vtgkSatz: _satzVtgk,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Zuschlagssätze gespeichert – sie stehen jetzt in der Zuschlagskalkulation.')));
  }

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});

    return CalcScaffold(
      title: 'Betriebsabrechnungsbogen',
      subtitle: 'Gemeinkosten verteilen · Zuschlagssätze',
      onReset: _reset,
      children: [
        const InfoBox(
          icon: Icons.grid_on,
          title: 'So arbeitest du den BAB ab',
          text: 'Erst die Gemeinkosten mit passenden Schlüsseln auf die vier '
              'Kostenstellen verteilen, dann die Spalten summieren, zuletzt die '
              'Zuschlagssätze bilden. Die Tabelle lässt sich seitlich schieben.',
        ),
        CalcCard(
          title: 'Verteilung der Gemeinkosten',
          subtitle: 'Beträge je Kostenstelle in €',
          trailing: ExampleButton(onPressed: _loadExample),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Kopfzeile
                Row(children: [
                  const SizedBox(width: 150, child: Text('Kostenart',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: kMuted))),
                  for (final s in _stellen)
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: kPetrolDeep)),
                      ),
                    ),
                  const SizedBox(width: 34),
                ]),
                const SizedBox(height: 6),
                const Divider(height: 1, color: kLine),
                // Datenzeilen
                for (var i = 0; i < _rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _rows[i].name,
                          style: const TextStyle(fontSize: 13, color: kInk),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      for (var j = 0; j < 4; j++)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: NumField(
                              controller: _rows[i].cells[j],
                              onChanged: up,
                              width: 94),
                        ),
                      SizedBox(
                        width: 34,
                        child: IconButton(
                          tooltip: 'Zeile entfernen',
                          onPressed: _rows.length > 1 ? () => _removeRow(i) : null,
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 18, color: kMuted),
                        ),
                      ),
                    ]),
                  ),
                const Divider(height: 12, color: kLine),
                // Summenzeile
                Row(children: [
                  const SizedBox(
                    width: 150,
                    child: Text('Summe Gemeinkosten',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: kInk)),
                  ),
                  for (final s in [
                    _gkMaterial,
                    _gkFertigung,
                    _gkVerwaltung,
                    _gkVertrieb
                  ])
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(fmtNum(s),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: kPetrolDeep)),
                      ),
                    ),
                  const SizedBox(width: 34),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addRow,
                style: TextButton.styleFrom(foregroundColor: kPetrol),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Kostenart ergänzen'),
              ),
            ),
            SchemeLine(
                op: '=',
                label: 'Gemeinkosten gesamt',
                value: _gkGesamt,
                total: true),
          ]),
        ),

        CalcCard(
          title: 'Bezugsgrößen (Einzelkosten)',
          subtitle: 'Grundlage für die Zuschlagssätze',
          child: Column(children: [
            SchemeLine(
              label: 'Fertigungsmaterial',
              field: NumField(controller: mek, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Fertigungslöhne',
              field: NumField(controller: fl, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Herstellkosten der Erzeugung',
              note: 'FM + MGK + FL + FGK',
              value: _hk,
              total: true,
              accent: kPetrol,
            ),
          ]),
        ),

        CalcCard(
          title: 'Zuschlagssätze',
          subtitle: 'Ergebnis des BAB – Basis jeder Kalkulation',
          child: Column(children: [
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'Materialgemeinkosten',
                  value: _satzMgk.isNaN ? '–' : fmtPct(_satzMgk),
                  color: kPetrol,
                  hint: 'auf Fertigungsmaterial',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'Fertigungsgemeinkosten',
                  value: _satzFgk.isNaN ? '–' : fmtPct(_satzFgk),
                  color: kAmber,
                  hint: 'auf Fertigungslöhne',
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'Verwaltungsgemeinkosten',
                  value: _satzVwgk.isNaN ? '–' : fmtPct(_satzVwgk),
                  color: kOk,
                  hint: 'auf Herstellkosten',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'Vertriebsgemeinkosten',
                  value: _satzVtgk.isNaN ? '–' : fmtPct(_satzVtgk),
                  color: kDue,
                  hint: 'auf Herstellkosten',
                ),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _uebernehmen,
                style: FilledButton.styleFrom(
                    backgroundColor: kPetrol,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('In die Zuschlagskalkulation übernehmen'),
              ),
            ),
          ]),
        ),

        StepsPanel(steps: [
          'Materialgemeinkostensatz = Summe Material-GK ÷ Fertigungsmaterial × 100 '
              '= ${fmtNum(_gkMaterial)} ÷ ${fmtNum(v(mek))} × 100 '
              '= ${_satzMgk.isNaN ? '–' : fmtPct(_satzMgk)}',
          'Fertigungsgemeinkostensatz = Summe Fertigungs-GK ÷ Fertigungslöhne × 100 '
              '= ${_satzFgk.isNaN ? '–' : fmtPct(_satzFgk)}',
          'Herstellkosten = Fertigungsmaterial + MGK + Fertigungslöhne + FGK '
              '= ${fmtEur(_hk)}',
          'Verwaltungsgemeinkostensatz = Verwaltungs-GK ÷ Herstellkosten × 100 '
              '= ${_satzVwgk.isNaN ? '–' : fmtPct(_satzVwgk)}',
          'Vertriebsgemeinkostensatz = Vertriebs-GK ÷ Herstellkosten × 100 '
              '= ${_satzVtgk.isNaN ? '–' : fmtPct(_satzVtgk)}',
        ]),

        const InfoBox(
          color: kAmber,
          icon: Icons.tips_and_updates_outlined,
          title: 'Typische Verteilungsschlüssel',
          text: 'Raumkosten nach Quadratmetern, Energie nach kWh oder '
              'installierter Leistung, Sozialkosten nach der Lohn- und '
              'Gehaltssumme, Abschreibungen nach den Anlagenwerten der Stelle.',
        ),
      ],
    );
  }
}
