import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/pruefung/pruef_ui.dart';

/// Ziel für „Übernehmen“ aus dem Rechner (FR-005 D): Beschriftung,
/// Einsetzen an der Schreibmarke, Zahlformat in Tabellen.
void main() {
  AktivesFeld feld(String text, FeldArt art, {int? zeile, int? marke}) {
    final c = TextEditingController(text: text);
    if (marke != null) c.selection = TextSelection.collapsed(offset: marke);
    return AktivesFeld(c, () {}, art: art, zeile: zeile);
  }

  test('Beschriftung wie rkZielText', () {
    expect(feld('', FeldArt.rechenweg, zeile: 2).ziel, 'Rechnung in den Rechenweg · Z2');
    expect(feld('4.400 ÷ 22', FeldArt.rechenweg, zeile: 2).ziel, 'in den Rechenweg · Z2');
    expect(feld('', FeldArt.antwort).ziel, 'in deine Antwort');
    expect(feld('', FeldArt.tabelle).ziel, 'in die Tabelle');
    expect(feld(' ', FeldArt.rechenweg, zeile: 1).leereRechnung, isTrue);
    expect(feld('1', FeldArt.rechenweg, zeile: 1).leereRechnung, isFalse);
    expect(feld('', FeldArt.antwort).leereRechnung, isFalse);
  });

  test('Einsetzen: Leerzeichen davor, außer nach Leerraum oder „(“', () {
    final a = feld('Kosten', FeldArt.antwort);
    a.einsetzen('1.815');
    expect(a.controller.text, 'Kosten 1.815');
    final b = feld('√(', FeldArt.rechenweg, zeile: 1);
    b.einsetzen('144');
    expect(b.controller.text, '√(144');
    final c = feld('a  b', FeldArt.antwort, marke: 2);
    c.einsetzen('7');
    expect(c.controller.text, 'a 7 b');
    expect(c.controller.selection.baseOffset, 3);
  });

  test('Tabellen: ohne Tausenderpunkt, einfaches Minus', () {
    expect(tabellenWert('1.234,5'), '1234,5');
    expect(tabellenWert('40.000'), '40000');
    expect(tabellenWert('−3'), '-3');
    expect(tabellenWert('1,5'), '1,5');
    expect(tabellenWert('A – C'), 'A – C');
    final t = feld('', FeldArt.tabelle);
    t.einsetzen('−1.250');
    expect(t.controller.text, '-1250');
  });
}
