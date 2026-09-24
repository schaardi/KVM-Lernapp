import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/services/rechenkern.dart';

/// Rechenkern für Taschenrechner und Rechenweg: alle Referenzwerte aus
/// FR-003 B und FR-005 A (Web-Stand), dazu Zahlenformat und Randfälle.
void main() {
  /// Ergebnis im Format des Rechenwegs; „ungültig“, wenn die Rechnung nicht geht.
  String erg(String s, [String einheit = '']) {
    final v = rechne(s);
    return v.isFinite ? fmtErgebnis(v, einheit) : 'ungültig';
  }

  group('FR-005 A: Referenzwerte', () {
    const faelle = {
      '200 + 19 %': '238',
      '238 − 16 %': '199,92',
      '1.000 − 10 % − 2 %': '882',
      '200 × 19 %': '38',
      '38 ÷ 19 %': '200',
      '200 + 3 · 10 %': '200,3',
      '(200 + 19 %) · 2': '476',
      '2π': '6,2832',
      '(60² − 50²) · π ÷ 4': '863,938',
      '2√9': '6',
      '2(3+4)': '14',
      '9,81 · sin 30°': '4,905',
      'tan⁻¹ 0,15': '8,5308',
      'arcsin 2': 'ungültig',
      'tan 90': 'ungültig',
      '12.100 ÷ 1,1^2': '10.000',
      '-2²': '−4',
      '(−2)²': '4',
      '10 h − 6 h 45 min': '3,25',
      '5 h 75': 'ungültig',
      '12 h · 30 €/h': '360',
    };
    faelle.forEach((eingabe, erwartet) {
      test(eingabe, () => expect(erg(eingabe), erwartet));
    });

    test('Zeile als Text im Rechenweg', () {
      expect(zeileText(f: '10 h − 6 h 45 min', u: 'h'), '10 − 6 h 45 min = 3,25 h');
      expect(zeileText(f: 'cos 30° · 2500', u: 'daN'), 'cos 30° · 2.500 = 2.165,0635 daN');
      expect(zeileText(f: 'sin⁻¹(0,5)'), 'sin⁻¹(0,5) = 30');
    });
  });

  group('FR-003 B: Referenzwerte', () {
    test('Ergebnisse', () {
      expect(erg('4.400 ÷ 22'), '200');
      expect(erg('30.250 · 6 %'), '1.815');
      expect(erg('√(2·7000·120÷(12·0,14))'), '1.000');
      expect(erg('1.5+1'), '2,5');
      expect(erg('1.500+1'), '1.501');
      expect(erg('(20+6+4)·2'), '60');
      expect(erg('5²'), '25');
      expect(erg('2^3'), '8');
      expect(erg('10 km/h · 2'), '20');
      expect(erg('3 x 4'), '12');
      expect(erg('-5+2'), '−3');
      expect(erg('99.600 / 3.000', '€'), '33,20');
      expect(erg('12,5 %'), '0,125');
      expect(erg('4400/0'), 'ungültig');
    });

    test('Zeile als Text', () {
      expect(zeileText(f: '4.400 ÷ 22'), '4.400 ÷ 22 = 200');
      expect(zeileText(f: '30.250 · 6 %'), '30.250 · 6 % = 1.815');
      expect(zeileText(f: '√(2·7000·120÷(12·0,14))'), '√(2 · 7.000 · 120 ÷ (12 · 0,14)) = 1.000');
      expect(zeileText(f: '1.5+1'), '1,5 + 1 = 2,5');
      expect(zeileText(f: '1.500+1'), '1.500 + 1 = 1.501');
      expect(zeileText(f: '10 km/h · 2'), '10 · 2 = 20');
      expect(zeileText(f: '3 x 4'), '3 · 4 = 12');
      expect(zeileText(f: '-5+2'), '−5 + 2 = −3');
      expect(zeileText(f: '99.600 / 3.000', u: '€'), '99.600 ÷ 3.000 = 33,20 €');
      expect(zeileText(f: '4400/0'), '4400/0');
    });

    test('Bezeichnung endet auf genau einen Doppelpunkt; nur eine Zahl ohne „=“', () {
      expect(zeileText(l: 'Kosten je Auftrag', f: '4.400 ÷ 22', u: '€'), 'Kosten je Auftrag: 4.400 ÷ 22 = 200 €');
      expect(zeileText(l: 'Kosten je Auftrag:  ', f: '4.400 ÷ 22', u: '€'), 'Kosten je Auftrag: 4.400 ÷ 22 = 200 €');
      expect(zeileText(l: 'Fixkosten', f: '4400', u: '€'), 'Fixkosten: 4.400 €');
      expect(zeileText(l: 'Nur Text'), 'Nur Text');
      expect(zeileText(f: '7,5', u: '€'), '7,50 €');
    });
  });

  group('Zerlegen', () {
    test('Hinter „=“ wird nicht weitergelesen', () {
      expect(erg('4.400 ÷ 22 = 200'), '200');
      expect(schoen('4.400 ÷ 22 = 999'), '4.400 ÷ 22');
    });

    test('Mal darf vor π, √, Funktion und Klammer fehlen', () {
      expect(rechne('2π'), closeTo(2 * math.pi, 1e-12));
      expect(rechne('2 sin 30'), closeTo(1, 1e-12));
      expect(rechne('(1+1)(2+2)'), 8);
      expect(rechne('3 %(10)'), closeTo(0.3, 1e-12));
    });

    test('Umkehrfunktionen in Grad, auch als arcsin', () {
      expect(rechne('sin⁻¹ 0,5'), closeTo(30, 1e-9));
      expect(rechne('arccos 0,5'), closeTo(60, 1e-9));
      expect(rechne('arctan 1'), closeTo(45, 1e-9));
      expect(rechne('cos 90'), 0);
      expect(rechne('sin 180'), 0);
      expect(rechne('tan 270').isNaN, isTrue);
      expect(rechne('tan(−90)').isNaN, isTrue);
      expect(rechne('tan 45'), closeTo(1, 1e-12));
    });

    test('Zeit: Minuten 0–59, „45 min“ allein bleibt 45', () {
      expect(rechne('6 h 45'), 6.75);
      expect(rechne('6 h 45 min'), 6.75);
      expect(rechne('45 min'), 45);
      expect(rechne('6 h 60').isNaN, isTrue);
      expect(schoen('6 h 5'), '6 h 05 min');
    });

    test('Potenz rechtsassoziativ, Vorzeichen, Prozent nach Klammer', () {
      expect(rechne('2^3^2'), 512);
      expect(rechne('2^-1'), 0.5);
      expect(rechne('--3'), 3);
      expect(rechne('100 + (10) %'), closeTo(110, 1e-12));
      expect(rechne('100 − (5 + 5) %'), closeTo(90, 1e-12));
      expect(rechne('2³'), 8);
    });

    test('Ungültiges', () {
      expect(rechne('').isNaN, isTrue);
      expect(rechne('5 +').isNaN, isTrue);
      expect(rechne('(5').isNaN, isTrue);
      expect(rechne('5)').isNaN, isTrue);
      expect(rechne('2 3').isNaN, isTrue);
      expect(rechne('5 & 3').isNaN, isTrue);
      expect(rechne('√-4').isNaN, isTrue);
      expect(rechne('12,').isNaN, isTrue);
      expect(zerlege('5 & 3'), isNull);
    });
  });

  group('Zahlen lesen', () {
    test('rkZahl wie rwZahl', () {
      expect(rkZahl('4.400'), 4400);
      expect(rkZahl('1.5'), 1.5);
      expect(rkZahl(',5'), 0.5);
      expect(rkZahl('1.000,5'), 1000.5);
      expect(rkZahl('12,'), 12);
      expect(rkZahl('1.234.567'), 1234567);
    });

    test('leseZahl wie parseCalcNum (Ergebnisfeld)', () {
      expect(leseZahl('4.400'), 4400);
      expect(leseZahl('1.5'), 1.5);
      expect(leseZahl('1.234,5'), 1234.5);
      expect(leseZahl('1234,5'), 1234.5);
      expect(leseZahl('−3'), -3);
      expect(leseZahl('– 3,5'), -3.5);
      expect(leseZahl('12 €'), 12);
      expect(leseZahl('abc'), isNull);
      expect(leseZahl(''), isNull);
    });
  });

  group('Zahlenformat', () {
    test('Rechenweg: höchstens 4 Nachkommastellen, € mit Cent', () {
      expect(fmtErgebnis(1234.56789), '1.234,5679');
      expect(fmtErgebnis(0.1 + 0.2), '0,3');
      expect(fmtErgebnis(-1500), '−1.500');
      expect(fmtErgebnis(12.5, '€'), '12,50');
      expect(fmtErgebnis(12, '€'), '12');
      expect(fmtErgebnis(double.nan), '');
      expect(fmtErgebnis(double.infinity), '');
    });

    test('Rechner: 12 gültige Stellen, ganze Zahlen bis 10¹⁵, „−“', () {
      expect(fmtRechner(2 * math.pi), '6,28318530718');
      expect(fmtRechner(math.sin(math.pi / 6)), '0,5');
      expect(fmtRechner(1234.5), '1.234,5');
      expect(fmtRechner(1234.5, ohnePunkte: true), '1234,5');
      expect(fmtRechner(-1234.5), '−1.234,5');
      expect(fmtRechner(2 / 3), '0,666666666667');
      expect(fmtRechner(123456.7890123456), '123.456,789012');
      expect(fmtRechner(999999999999999), '999.999.999.999.999');
      expect(fmtRechner(1e15), '1.000.000.000.000.000');
      expect(fmtRechner(1.2345678901234568e18), '1.234.567.890.120.000.000');
      expect(fmtRechner(1e-7), '0,0000001');
      expect(fmtRechner(1e-13), '0');
      expect(fmtRechner(-1e-13), '0');
      expect(fmtRechner(double.nan), '–');
    });

    test('Zeit: „3 h 15 min“, nie „3:15“', () {
      expect(fmtZeit(3.25), '3 h 15 min');
      expect(fmtZeit(6.75), '6 h 45 min');
      expect(fmtZeit(0.5), '0 h 30 min');
      expect(fmtZeit(1.999), '2 h 00 min');
      expect(fmtZeit(2.9999999999), '3 h 00 min');
      expect(fmtZeit(-1.5), '−1 h 30 min');
    });

    test('Zahl wie eingegeben mit Tausenderpunkt', () {
      expect(zahlText('7000'), '7.000');
      expect(zahlText('4.400'), '4.400');
      expect(zahlText('1.5'), '1,5');
      expect(zahlText('0,14'), '0,14');
      expect(zahlText('1234,50'), '1.234,50');
    });

    test('jsRunden rundet halbe Werte Richtung +∞', () {
      expect(jsRunden(2.5), 3);
      expect(jsRunden(-2.5), -2);
      expect(jsRunden(0.49999999999999994), 0);
      expect(jsRunden(-0.4), -0.0);
    });
  });
}
