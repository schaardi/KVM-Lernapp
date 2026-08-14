import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/calc_kit.dart';

/// Deckungsbeitrag, Break-Even, Preisuntergrenzen und Engpassrechnung.
class TeilkostenCalc extends StatefulWidget {
  const TeilkostenCalc({super.key});
  @override
  State<TeilkostenCalc> createState() => _TeilkostenCalcState();
}

class _TeilkostenCalcState extends State<TeilkostenCalc> {
  final preis = TextEditingController();
  final kv = TextEditingController();
  final kf = TextEditingController();
  final menge = TextEditingController();
  final ziel = TextEditingController();
  final vollkosten = TextEditingController();
  // Engpass
  final engpassA = TextEditingController();
  final engpassB = TextEditingController();
  final dbB = TextEditingController();
  final preisB = TextEditingController();
  final kvB = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      preis, kv, kf, menge, ziel, vollkosten,
      engpassA, engpassB, dbB, preisB, kvB,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() => setState(() {
        for (final c in [
          preis, kv, kf, menge, ziel, vollkosten,
          engpassA, engpassB, dbB, preisB, kvB,
        ]) {
          c.clear();
        }
      });

  void _loadExample() => setState(() {
        preis.text = '50';
        kv.text = '30';
        kf.text = '120.000';
        menge.text = '8.000';
        ziel.text = '40.000';
        vollkosten.text = '45';
        engpassA.text = '3';
        preisB.text = '60';
        kvB.text = '36';
        engpassB.text = '1,5';
      });

  double get _db => v(preis) - v(kv);
  double get _dbRate => v(preis) == 0 ? double.nan : _db / v(preis) * 100;
  double get _dbGesamt => _db * v(menge);
  double get _gewinn => _dbGesamt - v(kf);
  double get _beMenge => _db <= 0 ? double.nan : v(kf) / _db;
  double get _beUmsatz => _db <= 0 ? double.nan : _beMenge * v(preis);
  double get _zielMenge => _db <= 0 ? double.nan : (v(kf) + v(ziel)) / _db;
  double get _sicherheit => (v(menge) == 0 || _beMenge.isNaN)
      ? double.nan
      : (v(menge) - _beMenge) / v(menge) * 100;

  double get _dbA => _db;
  double get _dbBWert => v(preisB) - v(kvB);
  double get _relA => v(engpassA) == 0 ? double.nan : _dbA / v(engpassA);
  double get _relB => v(engpassB) == 0 ? double.nan : _dbBWert / v(engpassB);

  @override
  Widget build(BuildContext context) {
    void up() => setState(() {});

    return CalcScaffold(
      title: 'Deckungsbeitrag & Break-Even',
      subtitle: 'Teilkostenrechnung für Entscheidungen',
      onReset: _reset,
      children: [
        CalcCard(
          title: 'Ausgangsdaten',
          subtitle: 'Preis und variable Kosten je Stück, Fixkosten der Periode',
          trailing: ExampleButton(onPressed: _loadExample),
          child: Column(children: [
            SchemeLine(
              label: 'Verkaufspreis je Stück',
              field: NumField(controller: preis, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '−',
              label: 'Variable Kosten je Stück',
              field: NumField(controller: kv, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              op: '=',
              label: 'Deckungsbeitrag je Stück',
              value: _db,
              total: true,
              accent: _db >= 0 ? kOk : kErr,
            ),
            const SizedBox(height: 8),
            SchemeLine(
              label: 'Fixkosten der Periode',
              field: NumField(controller: kf, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Absatzmenge',
              field: NumField(controller: menge, onChanged: up, suffix: 'Stk'),
            ),
          ]),
        ),

        CalcCard(
          title: 'Ergebnis der Periode',
          child: Column(children: [
            SchemeLine(
              label: 'Gesamtdeckungsbeitrag',
              note: 'DB je Stück × Menge',
              value: _dbGesamt,
            ),
            SchemeLine(op: '−', label: 'Fixkosten', value: v(kf)),
            SchemeLine(
              op: '=',
              label: 'Betriebsergebnis',
              value: _gewinn,
              total: true,
              accent: _gewinn >= 0 ? kOk : kErr,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'DB-Rate',
                  value: _dbRate.isNaN ? '–' : fmtPct(_dbRate),
                  color: kPetrol,
                  hint: 'Anteil am Umsatz',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'Umsatz',
                  value: fmtEur(v(preis) * v(menge)),
                  color: kInkSoft,
                ),
              ),
            ]),
          ]),
        ),

        CalcCard(
          title: 'Gewinnschwelle (Break-Even)',
          child: Column(children: [
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'Break-Even-Menge',
                  value: _beMenge.isNaN ? '–' : '${fmtNum(_beMenge, dec: 0)} Stk',
                  color: kAmber,
                  hint: 'Fixkosten ÷ DB',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'Break-Even-Umsatz',
                  value: _beUmsatz.isNaN ? '–' : fmtEur(_beUmsatz),
                  color: kAmber,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'Sicherheitsstrecke',
                  value: _sicherheit.isNaN ? '–' : fmtPct(_sicherheit),
                  color: _sicherheit >= 0 ? kOk : kErr,
                  hint: 'Absatzrückgang verkraftbar',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'Menge für Zielgewinn',
                  value: _zielMenge.isNaN
                      ? '–'
                      : '${fmtNum(_zielMenge, dec: 0)} Stk',
                  color: kDue,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SchemeLine(
              label: 'Zielgewinn',
              field: NumField(controller: ziel, onChanged: up, suffix: '€'),
            ),
          ]),
        ),

        CalcCard(
          title: 'Preisuntergrenzen',
          subtitle: 'Wie weit darfst du im Preis heruntergehen?',
          child: Column(children: [
            SchemeLine(
              label: 'Kurzfristige Preisuntergrenze',
              note: 'variable Stückkosten – deckt nur den Mehraufwand',
              value: v(kv),
              sub: true,
              accent: kAmber,
            ),
            SchemeLine(
              label: 'Selbstkosten je Stück (Vollkosten)',
              field: NumField(controller: vollkosten, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Langfristige Preisuntergrenze',
              note: 'auf Dauer müssen auch die Fixkosten verdient werden',
              value: v(vollkosten),
              sub: true,
              accent: kErr,
            ),
            const SizedBox(height: 10),
            InfoBox(
              color: v(preis) >= v(kv) ? kOk : kErr,
              icon: v(preis) >= v(kv)
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              title: 'Zusatzauftrag zum aktuellen Preis?',
              text: v(preis) >= v(kv)
                  ? 'Der Preis liegt über den variablen Kosten – bei freier '
                      'Kapazität bringt jeder verkaufte Artikel '
                      '${fmtEur(_db)} zur Fixkostendeckung.'
                  : 'Der Preis liegt unter den variablen Kosten. Jedes '
                      'zusätzliche Stück vergrößert den Verlust – ablehnen.',
            ),
          ]),
        ),

        CalcCard(
          title: 'Engpassrechnung',
          subtitle: 'Welches Produkt zuerst, wenn die Kapazität knapp ist?',
          child: Column(children: [
            SchemeLine(
              label: 'Produkt A · Engpassverbrauch je Stück',
              note: 'z. B. Maschinenstunden',
              field: NumField(controller: engpassA, onChanged: up, suffix: 'h'),
            ),
            SchemeLine(label: 'Produkt A · DB je Stück', value: _dbA),
            const SizedBox(height: 10),
            SchemeLine(
              label: 'Produkt B · Preis je Stück',
              field: NumField(controller: preisB, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Produkt B · variable Kosten',
              field: NumField(controller: kvB, onChanged: up, suffix: '€'),
            ),
            SchemeLine(
              label: 'Produkt B · Engpassverbrauch je Stück',
              field: NumField(controller: engpassB, onChanged: up, suffix: 'h'),
            ),
            SchemeLine(label: 'Produkt B · DB je Stück', value: _dbBWert),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ResultTile(
                  label: 'A · relativer DB',
                  value: _relA.isNaN ? '–' : '${fmtNum(_relA)} €/Einheit',
                  color: (!_relA.isNaN && !_relB.isNaN && _relA >= _relB)
                      ? kOk
                      : kInkSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ResultTile(
                  label: 'B · relativer DB',
                  value: _relB.isNaN ? '–' : '${fmtNum(_relB)} €/Einheit',
                  color: (!_relA.isNaN && !_relB.isNaN && _relB > _relA)
                      ? kOk
                      : kInkSoft,
                ),
              ),
            ]),
            if (!_relA.isNaN && !_relB.isNaN) ...[
              const SizedBox(height: 10),
              InfoBox(
                color: kOk,
                icon: Icons.emoji_events_outlined,
                title: 'Vorrang im Produktionsprogramm',
                text: _relA >= _relB
                    ? 'Produkt A bringt je Engpasseinheit mehr Deckungsbeitrag '
                        'und wird zuerst gefertigt.'
                    : 'Produkt B bringt je Engpasseinheit mehr Deckungsbeitrag – '
                        'auch wenn der Stück-DB niedriger sein sollte.',
              ),
            ],
          ]),
        ),

        StepsPanel(steps: [
          'Deckungsbeitrag = Preis − variable Stückkosten = ${fmtEur(v(preis))} − '
              '${fmtEur(v(kv))} = ${fmtEur(_db)}',
          'Gesamtdeckungsbeitrag = DB × Menge = ${fmtEur(_dbGesamt)}',
          'Betriebsergebnis = Gesamt-DB − Fixkosten = ${fmtEur(_gewinn)}',
          'Break-Even-Menge = Fixkosten ÷ DB = ${fmtEur(v(kf))} ÷ ${fmtEur(_db)} '
              '= ${_beMenge.isNaN ? '–' : '${fmtNum(_beMenge, dec: 0)} Stück'}',
          'Sicherheitsstrecke = (Ist-Menge − Break-Even-Menge) ÷ Ist-Menge × 100 '
              '= ${_sicherheit.isNaN ? '–' : fmtPct(_sicherheit)}',
          'Relativer DB = DB je Stück ÷ Engpassverbrauch je Stück',
        ]),

        const InfoBox(
          color: kErr,
          icon: Icons.warning_amber_rounded,
          title: 'Prüfungsfalle',
          text: 'Bei Engpässen entscheidet nicht der höchste Deckungsbeitrag je '
              'Stück, sondern der höchste Deckungsbeitrag je Engpasseinheit. '
              'Wer das verwechselt, wählt das falsche Produkt.',
        ),
      ],
    );
  }
}
