import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/widgets/calc_kit.dart';

/// FR-005 F: Ergebnisfelder lesen Zahlen wie `parseCalcNum` im Web.
void main() {
  group('FR-005 F: Ergebnisfeld liest wie parseCalcNum', () {
    test('Tausenderpunkte, Dezimalpunkt, Komma, Minus', () {
      expect(parseDe('4.400'), 4400);
      expect(parseDe('1.5'), 1.5);
      expect(parseDe('1.234,5'), 1234.5);
      expect(parseDe('1234,5'), 1234.5);
      expect(parseDe('40.000.000'), 40000000);
      expect(parseDe('1234.567'), 1234.567);
      expect(parseDe('−12,5'), -12.5);
      expect(parseDe('–3'), -3);
      expect(parseDe('-1.250'), -1250);
      expect(parseDe(' 12 € '), 12);
      expect(parseDe(''), isNull);
      expect(parseDe('−'), isNull);
      expect(parseDe('abc'), isNull);
    });
  });
}
