import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/werkzeuge/rechner_modell.dart';

/// Taschenrechner als Zeichenliste (FR-005 B–C): Referenz-Tastenfolgen,
/// Anzeige, Fehler, Verlauf, Speicher unter `kvm_rechner`.
void main() {
  late RechnerModell r;

  Future<RechnerModell> neu([Map<String, Object> werte = const {}]) async {
    SharedPreferences.setMockInitialValues(werte);
    final m = RechnerModell();
    await m.laden();
    return m;
  }

  /// Tastenfolge wie in der Tabelle: Leerzeichen trennen die Tasten.
  void tippe(String folge) => r.tasten(folge.split(' ').where((k) => k.isNotEmpty));

  String zeile() => r.anzeigeZeile.map((t) => t.text).join();

  setUp(() async => r = await neu());

  group('Referenz-Tastenfolgen (FR-005 B)', () {
    const faelle = {
      '2 0 0 + 1 9 % =': '238',
      '1 0 0 0 − 1 0 % − 2 % =': '882',
      '1 6 √ =': '4',
      '√ 1 6 =': '4',
      '5 + 9 √ =': '8',
      '2 π =': '6,28318530718',
      '3 0 sin =': '0,5',
      'inv tan 1 =': '45',
      '1 0 zeit − 6 zeit 4 5 =': '3,25',
      '5 − 9 ± =': '14',
      '1 2 + 3 = × 2 =': '30',
      '1 2 + 3 = 7': '7',
      '5 + =': 'Rechnung unvollständig',
    };
    faelle.forEach((folge, erwartet) {
      test(folge, () async {
        r = await neu();
        tippe(folge);
        expect(r.ergebnisText, erwartet);
      });
    });

    test('Zeit: „10 h 00 min − 6 h 45 min“, Zeitfeld „3 h 15 min“', () {
      tippe('1 0 zeit − 6 zeit 4 5');
      expect(zeile(), '10 h 00 min − 6 h 45 min');
      expect(r.anzeigeZeile[1].blass, isTrue, reason: 'leere Minuten blass');
      tippe('=');
      expect(r.zeitText, '3 h 15 min');
      expect(r.verlauf.single.a, '10 h 00 min − 6 h 45 min');
      expect(r.verlauf.single.wertText, '= 3,25 (3 h 15 min)');
      expect(zeile(), '10 h 00 min − 6 h 45 min =');
    });

    test('„1 2 + 3 = 7“ beginnt eine neue Rechnung, der Verlauf bleibt', () {
      tippe('1 2 + 3 = 7');
      expect(zeile(), '7');
      expect(r.verlauf.single.a, '12 + 3');
      expect(r.verlauf.single.v, 15);
    });
  });

  group('Fehler', () {
    test('Rechnung bleibt stehen, Anzeige wackelt', () {
      tippe('5 +');
      final vorher = r.wackeln;
      tippe('=');
      expect(r.ergebnisArt, ErgebnisArt.fehler);
      expect(r.wackeln, vorher + 1);
      expect(zeile(), '5 +');
      expect(r.kannUebernehmen, isFalse);
      tippe('3');
      expect(r.ergebnisText, '8', reason: 'die nächste Taste löscht den Fehler');
    });

    test('„Nicht definiert“: ÷ 0, √ aus Negativem, tan 90°, sin⁻¹ 2', () {
      for (final f in ['5 ÷ 0 =', '√ − 4 =', 'tan 9 0 =', 'inv sin 2 =']) {
        r.taste('C');
        tippe(f);
        expect(r.ergebnisText, 'Nicht definiert', reason: f);
      }
    });

    test('Minuten über 59', () {
      tippe('1 zeit 7 5 =');
      expect(r.ergebnisText, 'Minuten gehen nur bis 59');
    });
  });

  group('Tasten', () {
    test('Ziffern: „0“ wird ersetzt, höchstens 15 Ziffern', () {
      tippe('0 5');
      expect(zeile(), '5');
      r.taste('C');
      tippe(List.filled(17, '9').join(' '));
      expect(r.eintraege.single.s.length, 15);
    });

    test('Komma nur einmal, ohne Zahl davor „0,“', () {
      tippe(', 5');
      expect(zeile(), '0,5');
      r.taste('C');
      tippe('1 , , 5');
      expect(zeile(), '1,5');
      expect(r.ergebnisText, '1,5');
    });

    test('Tausenderpunkte beim Tippen', () {
      tippe('1 2 3 4 5 6 7 , 5');
      expect(zeile(), '1.234.567,5');
    });

    test('Rechenzeichen ersetzt das davor; Minus nach × ist Vorzeichen', () {
      tippe('5 + ×');
      expect(zeile(), '5 ×');
      tippe('−');
      expect(zeile(), '5 × −');
      tippe('+');
      expect(zeile(), '5 +');
      r.taste('C');
      tippe('− 3 =');
      expect(r.ergebnisText, '−3');
      r.taste('C');
      tippe('×');
      expect(r.eintraege, isEmpty, reason: 'am Anfang nur Vorzeichen-Minus');
    });

    test('% und x² nur hinter einem Zahl-Ende', () {
      tippe('% ²');
      expect(r.eintraege, isEmpty);
      tippe('5 % %');
      expect(zeile(), '5 %');
      r.taste('C');
      tippe('( 2 + 1 ) ² =');
      expect(r.ergebnisText, '9');
    });

    test('Klammern: „)“ nur mit offener Klammer und Zahl davor; Mal vor „(“', () {
      tippe(')');
      expect(r.eintraege, isEmpty);
      tippe('( )');
      expect(zeile(), '()', reason: '„)“ direkt nach „(“ zählt nicht');
      expect(r.anzeigeZeile.last.blass, isTrue);
      r.taste('C');
      tippe('2 ( 3 + 4');
      expect(zeile(), '2 × (3 + 4)');
      expect(r.anzeigeZeile.last.text, ')');
      expect(r.anzeigeZeile.last.blass, isTrue, reason: 'fehlende Klammer blass');
      expect(r.ergebnisText, '14', reason: 'offene Klammern schließt der Rechner selbst');
    });

    test('π und Mal davor', () {
      tippe('2 π');
      expect(zeile(), '2 × π');
      tippe('3');
      expect(zeile(), '2 × π × 3');
    });

    test('√ und Winkel wirken auf den letzten Operanden oder nach „=“ aufs Ergebnis', () {
      tippe('( 9 ) √');
      expect(zeile(), '√(9)');
      expect(r.ergebnisText, '3');
      r.taste('C');
      tippe('1 6 = √');
      expect(zeile(), '√(16)');
      expect(r.ergebnisText, '4');
      r.taste('C');
      tippe('2 × 3 0 sin');
      expect(zeile(), '2 × sin(30)');
      expect(r.ergebnisText, '1');
    });

    test('inv gilt für einen Druck', () {
      tippe('inv');
      expect(r.inv, isTrue);
      tippe('sin 0 , 5 =');
      expect(r.ergebnisText, '30');
      expect(r.inv, isFalse);
      tippe('inv inv');
      expect(r.inv, isFalse);
    });

    test('± wechselt das Vorzeichen, ein zweites hebt es auf', () {
      tippe('5 − 9 ±');
      expect(zeile(), '5 − (−9)');
      tippe('±');
      expect(zeile(), '5 − 9');
      r.taste('C');
      tippe('1 2 ±');
      expect(zeile(), '−12');
      tippe('±');
      expect(zeile(), '12');
      r.taste('C');
      tippe('1 2 = ±');
      expect(r.ergebnisText, '−12');
      expect(r.frisch, isFalse);
      r.taste('C');
      tippe('5 × ±');
      expect(zeile(), '5 × −');
      tippe('±');
      expect(zeile(), '5 ×');
    });

    test('„h min“: Stunden, dann zwei Ziffern Minuten; ⌫ Schritt für Schritt', () {
      tippe('6 zeit 4 5 7');
      expect(zeile(), '6 h 45 min');
      tippe('⌫');
      expect(zeile(), '6 h 4 min');
      tippe('⌫');
      expect(zeile(), '6 h 00 min');
      tippe('⌫');
      expect(zeile(), '6');
      r.taste('C');
      tippe('zeit 3 0 =');
      expect(r.ergebnisText, '0,5');
      expect(r.zeitText, '0 h 30 min');
    });

    test('⌫ löscht Ziffer, ganze Funktion; nach „=“ wie C', () {
      tippe('1 2 ⌫');
      expect(zeile(), '1');
      r.taste('C');
      tippe('√ ⌫');
      expect(r.eintraege, isEmpty);
      tippe('5 + 3 = ⌫');
      expect(r.eintraege, isEmpty);
      expect(r.verlauf, hasLength(1), reason: 'der Verlauf bleibt');
    });

    test('„=“ mit nur einer Zahl kommt nicht in den Verlauf', () {
      tippe('5 =');
      expect(r.verlauf, isEmpty);
      expect(r.frisch, isTrue);
    });

    test('Ergebnis live, unvollständig blass mit letztem gültigem Wert', () {
      tippe('5');
      expect(r.ergebnisText, '5');
      tippe('+');
      expect(r.ergebnisText, '5');
      expect(r.ergebnisArt, ErgebnisArt.blass);
      tippe('C');
      expect(r.ergebnisText, '0');
      expect(r.ergebnisArt, ErgebnisArt.normal);
    });
  });

  group('Verlauf', () {
    test('höchstens 25 Rechnungen, die neueste zuletzt', () {
      for (var i = 1; i <= 27; i++) {
        tippe('${'$i'.split('').join(' ')} + 1 =');
      }
      expect(r.verlauf, hasLength(25));
      expect(r.verlauf.first.a, '3 + 1');
      expect(r.verlauf.last.a, '27 + 1');
    });

    test('Einsetzen als fester Wert, nach einer Zahl mit Mal', () {
      tippe('1 2 + 3 = C 2');
      r.einsetzen(0);
      expect(zeile(), '2 × 15');
      tippe('=');
      expect(r.ergebnisText, '30');
      r.einsetzen(0);
      expect(zeile(), '15', reason: 'nach „=“ beginnt das Einsetzen neu');
    });

    test('Verlauf leeren', () {
      tippe('1 + 1 =');
      r.verlaufLeeren();
      expect(r.verlauf, isEmpty);
      expect(r.ergebnisText, '2');
    });
  });

  group('Übernehmen', () {
    test('Ergebnisfeld ohne Tausenderpunkt, Text mit', () {
      tippe('1 2 3 4 5 ÷ 1 0 =');
      expect(r.kannUebernehmen, isTrue);
      expect(r.uebernahmeWert, '1234,5');
      expect(r.uebernahmeWertMitPunkten, '1.234,5');
      r.taste('C');
      tippe('5 − 8 =');
      expect(r.uebernahmeWert, '-3');
    });

    test('Rechnung für eine leere Rechenweg-Zeile', () {
      tippe('4 4 0 0 ÷ 2 2');
      expect(r.rechnungText, '4.400 ÷ 22');
      tippe('=');
      expect(r.rechnungText, '4.400 ÷ 22');
      expect(r.ergebnisText, '200');
    });
  });

  group('Speicher kvm_rechner', () {
    test('übersteht einen Neustart', () async {
      tippe('4 4 0 0 ÷ 2 2 = 1 +');
      r.miniUmschalten();
      final prefs = await SharedPreferences.getInstance();
      final roh = prefs.getString('kvm_rechner')!;
      final d = jsonDecode(roh) as Map<String, dynamic>;
      expect(d.keys, containsAll(['T', 'v', 'fr', 'l', 'mini']));
      expect(d['v'], [
        {'a': '4.400 ÷ 22', 'v': 200.0, 'z': false}
      ]);

      final zwei = await neu({'kvm_rechner': roh});
      expect(zwei.verlauf.single.a, '4.400 ÷ 22');
      expect(zwei.anzeigeZeile.map((t) => t.text).join(), '1 +');
      expect(zwei.mini, isTrue);
    });

    test('nach „=“ gespeichert: Rechnung und Ergebnis kommen wieder', () async {
      tippe('2 + 3 =');
      final prefs = await SharedPreferences.getInstance();
      final zwei = await neu({'kvm_rechner': prefs.getString('kvm_rechner')!});
      expect(zwei.frisch, isTrue);
      expect(zwei.ergebnisText, '5');
      expect(zwei.anzeigeZeile.single.text, '2 + 3 =');
    });

    test('liest den Web-Stand', () async {
      final m = await neu({
        'kvm_rechner': jsonEncode({
          'T': [
            {'t': 'n', 's': '12'},
            {'t': 'o', 's': '+'},
            {'t': 'n', 'v': 3, 'z': false},
          ],
          'v': [
            {'a': '4.400 ÷ 22', 'v': 200, 'z': false}
          ],
          'fr': false,
          'l': '',
          'mini': false,
        })
      });
      expect(m.ergebnisText, '15');
      expect(m.verlauf.single.v, 200);
    });

    test('kaputter Speicher: leerer Rechner ohne Absturz', () async {
      final m = await neu({'kvm_rechner': '{"T": [{"t": "?"}], "v": "x"'});
      expect(m.eintraege, isEmpty);
      expect(m.ergebnisText, '0');
      final m2 = await neu({
        'kvm_rechner': jsonEncode({
          'T': [
            {'t': 'q'}
          ],
          'v': [
            {'a': 'x'}
          ]
        })
      });
      expect(m2.eintraege, isEmpty);
      expect(m2.verlauf, isEmpty);
    });
  });
}
