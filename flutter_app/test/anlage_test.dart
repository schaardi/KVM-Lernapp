import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/widgets/anlage_tabelle.dart';

/// Tabellenanlagen zum Ausfüllen: Zahlen aus dem Antwortfeld müssen so gelesen
/// werden, wie man sie in der Prüfung schreibt, und jede Lösungstabelle muss
/// zu der Anlage passen, die sie ausfüllt.
void main() {
  group('Zahlen aus einer Anlage lesen', () {
    test('Tausenderpunkte, Komma und Einheiten', () {
      expect(anlageZahl('1.125'), 1125);
      expect(anlageZahl('28.800'), 28800);
      expect(anlageZahl('20128'), 20128);
      expect(anlageZahl('0,506'), closeTo(0.506, 1e-9));
      expect(anlageZahl('9 %'), 9);
      expect(anlageZahl('50,00 €/h'), closeTo(50, 1e-9));
      expect(anlageZahl('keine Zahl'), isNull);
    });

    test('gleich ist, was dieselbe Zahl meint', () {
      expect(anlageGleich('1.125', '1125'), isTrue);
      expect(anlageGleich('9 %', '9'), isTrue);
      expect(anlageGleich('425 %', '425'), isTrue);
      expect(anlageGleich('20.128', '20128'), isTrue);
      expect(anlageGleich('1.125', '1.126'), isFalse);
      expect(anlageGleich('425 %', ''), isFalse);
    });

    test('Text wird ohne Zahl verglichen', () {
      expect(anlageGleich('Krankenversicherung', 'krankenversicherung'), isTrue);
      expect(anlageGleich('Krankenversicherung', 'Rentenversicherung'), isFalse);
    });
  });

  group('Anlagen der gebündelten Prüfungen', () {
    final faelle = (json.decode(File('assets/data/cases.json').readAsStringSync())
            as List<dynamic>)
        .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
        .toList();

    test('jede Lösungstabelle passt zu einer Anlage ihrer Aufgabe', () {
      var geprueft = 0;
      for (final c in faelle) {
        for (final s in c.steps) {
          if (s.tabL == null) continue;
          final auf = c.aufgabeVon(s.nr);
          final alle = [...s.tabs, ...?auf?.tabs];
          expect(alle, isNotEmpty,
              reason: '${s.id} hat eine Lösungstabelle, aber keine Anlage');
          expect(s.tabL!.zeilen, isNotEmpty, reason: '${s.id}: leere Lösung');
          geprueft++;
        }
      }
      expect(geprueft, greaterThan(0));
    });

    test('Anlagen zum Ausfüllen haben eine Kopfzeile', () {
      for (final c in faelle) {
        for (final a in c.aufgaben) {
          for (final t in a.tabs) {
            if (!t.hatLeere) continue;
            expect(t.kopf.isNotEmpty || t.zeilen.first.isNotEmpty, isTrue,
                reason: '${c.id} Aufgabe ${a.nr}: Anlage ohne Beschriftung');
          }
        }
      }
    });
  });
}
