import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/pruefung/rechenweg_kern.dart';

/// Rechenkern des Rechenwegs – die Referenzwerte stammen aus FR-003 B und
/// FR-005 A (Web-Stand) und müssen exakt so herauskommen. Fällt mit
/// `lib/pruefung/rechenweg_kern.dart` weg, sobald der Rechenweg auf den
/// gemeinsamen Kern umgestellt ist.
void main() {
  String erg(String f, [String u = '']) {
    final v = rechne(f);
    return v.isFinite ? rwFmt(v, u) : 'ungültig';
  }

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
      expect(rwZeileText('', '4.400 ÷ 22', ''), '4.400 ÷ 22 = 200');
      expect(rwZeileText('', '30.250 · 6 %', ''), '30.250 · 6 % = 1.815');
      expect(rwZeileText('', '√(2·7000·120÷(12·0,14))', ''), '√(2 · 7.000 · 120 ÷ (12 · 0,14)) = 1.000');
      expect(rwZeileText('', '1.5+1', ''), '1,5 + 1 = 2,5');
      expect(rwZeileText('', '1.500+1', ''), '1.500 + 1 = 1.501');
      expect(rwZeileText('', '10 km/h · 2', ''), '10 · 2 = 20');
      expect(rwZeileText('', '3 x 4', ''), '3 · 4 = 12');
      expect(rwZeileText('', '-5+2', ''), '−5 + 2 = −3');
      expect(rwZeileText('', '99.600 / 3.000', '€'), '99.600 ÷ 3.000 = 33,20 €');
      expect(rwZeileText('', '4400/0', ''), '4400/0');
    });

    test('Bezeichnung endet auf genau einen Doppelpunkt, bloße Zahl ohne Rechnung', () {
      expect(rwZeileText('Kosten je Auftrag', '4.400 ÷ 22', '€'), 'Kosten je Auftrag: 4.400 ÷ 22 = 200 €');
      expect(rwZeileText('Kosten je Auftrag:', '4.400 ÷ 22', '€'), 'Kosten je Auftrag: 4.400 ÷ 22 = 200 €');
      expect(rwZeileText('Fixkosten', '1.200', '€'), 'Fixkosten: 1.200 €');
      expect(rwZeileText('Nur Text', '', ''), 'Nur Text');
      expect(rwZeileText('', '', ''), '');
    });
  });

  group('FR-005 A: Referenzwerte', () {
    test('Prozent wie auf dem Tischrechner', () {
      expect(erg('200 + 19 %'), '238');
      expect(erg('238 − 16 %'), '199,92');
      expect(erg('1.000 − 10 % − 2 %'), '882');
      expect(erg('200 × 19 %'), '38');
      expect(erg('38 ÷ 19 %'), '200');
      expect(erg('200 + 3 · 10 %'), '200,3');
      expect(erg('(200 + 19 %) · 2'), '476');
    });

    test('π, Wurzel, Klammern ohne Mal', () {
      expect(erg('2π'), '6,2832');
      expect(erg('(60² − 50²) · π ÷ 4'), '863,938');
      expect(erg('2√9'), '6');
      expect(erg('2(3+4)'), '14');
    });

    test('Winkel in Grad samt Umkehrung', () {
      expect(erg('9,81 · sin 30°'), '4,905');
      expect(erg('tan⁻¹ 0,15'), '8,5308');
      expect(erg('arcsin 2'), 'ungültig');
      expect(erg('tan 90'), 'ungültig');
    });

    test('Potenz, Vorzeichen und Zeit', () {
      expect(erg('12.100 ÷ 1,1^2'), '10.000');
      expect(erg('-2²'), '−4');
      expect(erg('(−2)²'), '4');
      expect(erg('10 h − 6 h 45 min'), '3,25');
      expect(erg('5 h 75'), 'ungültig');
      expect(erg('12 h · 30 €/h'), '360');
      expect(erg('45 min'), '45');
    });

    test('Zeile als Text', () {
      expect(rwZeileText('', '10 h − 6 h 45 min', 'h'), '10 − 6 h 45 min = 3,25 h');
      expect(rwZeileText('', 'cos 30° · 2500', 'daN'), 'cos 30° · 2.500 = 2.165,0635 daN');
      expect(rwZeileText('', 'sin⁻¹(0,5)', ''), 'sin⁻¹(0,5) = 30');
    });

    test('Zeichen direkt auswerten (Rechner reicht Zahlen ohne Text durch)', () {
      final t = [
        const RwZeichen.zahl(1 / 3),
        const RwZeichen.op('*'),
        const RwZeichen.zahl(3),
      ];
      expect(rwAuswerten(t), closeTo(1, 1e-15));
    });
  });

  group('Grenzfälle', () {
    test('unvollständig und unlesbar ist ungültig', () {
      expect(rechne('5 +').isNaN, isTrue);
      expect(rechne('(2+3').isNaN, isTrue);
      expect(rechne('').isNaN, isTrue);
      expect(rechne('2 # 3').isNaN, isTrue);
    });

    test('hinter „=“ wird nicht weitergelesen', () {
      expect(rechne('4 · 5 = 20'), 20);
    });

    test('Euro mit Cent genau zwei Stellen, sonst höchstens vier', () {
      expect(rwFmt(12.5, '€'), '12,50');
      expect(rwFmt(12, '€'), '12');
      expect(rwFmt(1234567.891234), '1.234.567,8912');
    });
  });
}
