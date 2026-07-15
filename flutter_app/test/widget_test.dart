import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/constants.dart';

void main() {
  test('IHK-Notenschlüssel bildet Prozente korrekt auf Noten ab', () {
    expect(ihkGrade(95).note, 1);
    expect(ihkGrade(72).note, 3);
    expect(ihkGrade(50).note, 4);
    expect(ihkGrade(20).note, 6);
  });
}
