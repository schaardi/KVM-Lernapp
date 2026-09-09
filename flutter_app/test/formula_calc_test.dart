import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/services/formula_calc.dart';

/// Prüft den Rechenkern des Formelbuchs gegen die amtlichen Lösungen der
/// IHK-Prüfungen. Die Zahlen stammen aus den Original-Lösungshinweisen.
void main() {
  group('Ausdrucksparser', () {
    test('Grundrechenarten und Vorrang', () {
      expect(evalFormula('2+3*4', {}), 14);
      expect(evalFormula('(2+3)*4', {}), 20);
      expect(evalFormula('2^3^2', {}), 512); // rechtsassoziativ
      expect(evalFormula('-3+5', {}), 2);
    });

    test('Funktionen und Konstanten', () {
      expect(evalFormula('sqrt(36)', {}), 6);
      expect(evalFormula('min(3,7)', {}), 3);
      expect(evalFormula('max(3,7)', {}), 7);
      expect(evalFormula('sin(30)', {}), closeTo(0.5, 1e-12));
      expect(evalFormula('cos(60)', {}), closeTo(0.5, 1e-12));
      expect(evalFormula('2*pi*n/60', {'n': 2160}), closeTo(226.1947, 1e-4));
    });

    test('Fehler werden gemeldet', () {
      expect(() => evalFormula('1/0', {}), throwsA(isA<FormulaError>()));
      expect(() => evalFormula('foo+1', {}), throwsA(isA<FormulaError>()));
      expect(() => evalFormula('2+', {}), throwsA(isA<FormulaError>()));
    });

    test('Rechenweg setzt Zahlen ein', () {
      final weg = traceFormula('Pab/Pzu*100', {'Pab': 2.2, 'Pzu': 3.17},
          (x) => x.toString());
      expect(weg, '2.2 ÷ 3.17 · 100');
    });
  });

  group('Formeln aus den Prüfungen', () {
    test('Andler – optimale Bestellmenge (BQ BWL H2025, A2c)', () {
      final x = evalFormula('sqrt(200*JB*kB/(EP*LKS))',
          {'JB': 90, 'kB': 180, 'EP': 4500, 'LKS': 20});
      expect(x, closeTo(6, 1e-9));
    });

    test('Akkordlohn (BQ BWL H2025, A4a)', () {
      final ar = evalFormula('GL*(1+z/100)', {'GL': 30, 'z': 10});
      expect(ar, closeTo(33, 1e-9));
      final nl = evalFormula('60/tv', {'tv': 5});
      final sg = evalFormula('AR/NL', {'AR': ar, 'NL': nl});
      expect(sg, closeTo(2.75, 1e-9));
      expect(evalFormula('SG*m', {'SG': sg, 'm': 13}), closeTo(35.75, 1e-9));
    });

    test('Break-even (BQ BWL H2025, A6a)', () {
      final kv = evalFormula('(K2-K1)/(x2-x1)',
          {'K2': 4778700, 'K1': 3940200, 'x2': 940, 'x1': 680});
      expect(kv, closeTo(3225, 1e-9));
      final kf = evalFormula('K-kv*x', {'K': 4778700, 'kv': kv, 'x': 940});
      expect(kf, closeTo(1747200, 1e-9));
      final bep = evalFormula('Kf/(p-kv)', {'Kf': kf, 'p': 5625, 'kv': kv});
      expect(bep, closeTo(728, 1e-9));
      expect(evalFormula('xbep/kap*100', {'xbep': bep, 'kap': 1060}),
          closeTo(68.68, 0.01));
    });

    test('Naturwissenschaft und Technik (BQ NTG H2025)', () {
      // A2a – Zumischmenge auf 40 °C
      expect(
          evalFormula('m1*(T1-TM)/(TM-T2)',
              {'m1': 15, 'T1': 80, 'TM': 40, 'T2': 15}),
          closeTo(24, 1e-9));
      // A3a – Hangabtriebsbeschleunigung bei 30°
      expect(evalFormula('g*sin(alpha)', {'g': 9.81, 'alpha': 30}),
          closeTo(4.905, 1e-9));
      // A4a – Einfüllmenge Benzin
      expect(
          evalFormula('Vzul*(1-gamma*dT)',
              {'Vzul': 22.5, 'gamma': 0.0011, 'dT': 12}),
          closeTo(22.203, 1e-9));
      // A5c – Drehmoment an der Motorwelle
      final w = evalFormula('2*pi*n/60', {'n': 2160});
      expect(evalFormula('P/w', {'P': 2200, 'w': w}), closeTo(9.73, 0.01));
    });
  });

  group('Kalkulationsschema', () {
    List<Map<String, dynamic>> zeilen() {
      final raw = File('assets/data/formulas.json').readAsStringSync();
      final groups = (json.decode(raw) as List)
          .map((e) => FormulaGroup.fromJson(e as Map<String, dynamic>))
          .toList();
      final schema = groups
          .expand((g) => g.schemas)
          .firstWhere((s) => s.id == 'zuschlag');
      return schema.rows;
    }

    test('vorwärts: Einzelkosten ergeben den Listenverkaufspreis', () {
      final r = solveSchema(
        zeilen(),
        {'MEK': 2550, 'FEK': 3900, 'SEF': 510, 'SEV': 455},
        {'MGK': 25, 'FGK': 210, 'VwGK': 15, 'VtGK': 5, 'GEW': 10},
      );
      expect(r.unbekannt, isNull);
      expect(r.werte['MK'], closeTo(3187.50, 0.01));
      expect(r.werte['FK'], closeTo(12600, 0.01));
      expect(r.werte['HK'], closeTo(15787.50, 0.01));
      expect(r.werte['SK'], closeTo(19400, 0.01));
      expect(r.werte['LVP'], closeTo(21340, 0.01));
    });

    test('rückwärts: Materialeinzelkosten aus dem Listenverkaufspreis '
        '(BQ BWL H2025, A7a → amtlich 2.550 €)', () {
      final r = solveSchema(
        zeilen(),
        {'FEK': 3900, 'SEF': 510, 'SEV': 455, 'LVP': 21340},
        {'MGK': 25, 'FGK': 210, 'VwGK': 15, 'VtGK': 5, 'GEW': 10},
      );
      expect(r.unbekannt, 'MEK');
      expect(r.hinweis, isNull);
      expect(r.werte['MEK'], closeTo(2550, 0.01));
      expect(r.werte['MK'], closeTo(3187.50, 0.01));
      expect(r.werte['SK'], closeTo(19400, 0.01));
    });

    test('„im Hundert": Skonto und Rabatt beziehen sich auf den höheren Preis',
        () {
      final r = solveSchema(
        zeilen(),
        {'MEK': 0, 'FEK': 0, 'SEF': 0, 'SEV': 100},
        {'MGK': 0, 'FGK': 0, 'VwGK': 0, 'VtGK': 0, 'GEW': 0,
         'SKO': 2, 'PRO': 0, 'RAB': 20},
      );
      // Barverkaufspreis 100 € → Ziel 100 / 0,98 → Liste / 0,80
      expect(r.werte['BVP'], closeTo(100, 0.01));
      expect(r.werte['ZVP'], closeTo(100 / 0.98, 0.01));
      expect(r.werte['SKO'], closeTo(100 / 0.98 * 0.02, 0.01));
      expect(r.werte['LVP'], closeTo(100 / 0.98 / 0.80, 0.01));
    });

    test('mehrere freie Zeilen: Hinweis statt Rateversuch', () {
      final r = solveSchema(zeilen(), {'LVP': 21340}, {'MGK': 25});
      expect(r.unbekannt, isNull);
      expect(r.hinweis, isNotNull);
    });
  });
}
