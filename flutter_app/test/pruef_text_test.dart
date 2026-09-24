import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/pruefung/pruef_text.dart';

/// Prüfungstexte strukturiert darstellen (FR-003 A): Testfälle aus der
/// Anforderung und ein Durchlauf über alle Original-Prüfungen.
void main() {
  final faelle = (json.decode(File('assets/data/cases.json').readAsStringSync()) as List<dynamic>)
      .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
      .toList();
  final pruefungen = faelle.where((c) => c.id.startsWith('P-')).toList();
  Question schritt(String id) => faelle.expand((c) => c.steps).firstWhere((s) => s.id == id);
  Aufgabe aufgabe(String id, int nr) => faelle.firstWhere((c) => c.id == id).aufgabeVon(nr)!;

  group('Testfälle aus FR-003 A', () {
    test('P-OK-20221115, Aufgabe 3: Absatz, dann drei Wertelisten mit Beschriftung', () {
      final b = ptBloecke(aufgabe('P-OK-20221115', 3).sit);
      expect(b.map((x) => x.runtimeType).toList(), [
        PtAbsatz,
        PtBeschriftung,
        PtTabelle,
        PtBeschriftung,
        PtTabelle,
        PtBeschriftung,
        PtTabelle,
      ]);
      final tabellen = b.whereType<PtTabelle>().toList();
      expect(tabellen.every((t) => t.werteliste && !t.kopf), isTrue);
      expect(tabellen[1].zeilen.length, 3);
      expect(ptKlartext(b), isNot(contains(' | ')));
    });

    test('P-MI-20200505, Aufgabe 2: Tabelle mit Kopf und 9 Zeilen', () {
      final t = ptBloecke(aufgabe('P-MI-20200505', 2).sit).whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first, ['Nr.', 'Vorgang', 'Dauer in Tagen', 'Vorgänger']);
      expect(t.koerper.length, 9);
    });

    test('P-OK-20231121-s10: Rechenblock mit Ergebnis „10%“, Beschriftung, Liste, Punkte-Marke', () {
      final b = ptBloecke(schritt('P-OK-20231121-s10').a);
      final r = b.first as PtRechenblock;
      expect(r.zeilen.length, 2);
      expect(ptRechnung(r.zeilen.last).ergebnis, '10%');
      expect(b.whereType<PtBeschriftung>().first.text, 'Maßnahmen:');
      expect(b.whereType<PtListe>().single.punkte.length, 4);
      final letzter = b.last as PtAbsatz;
      expect(ptPunkte.hasMatch(letzter.text), isTrue);
    });

    test('P-BW-20230504-s14: Liste, Absatz, Rechenblock; Rechnung hinter „=“ ohne Hervorhebung', () {
      final b = ptBloecke(schritt('P-BW-20230504-s14').a);
      expect(b[0], isA<PtListe>());
      expect(b[1], isA<PtAbsatz>());
      expect(b[2], isA<PtRechenblock>());
      final zeilen = b.whereType<PtRechenblock>().expand((r) => r.zeilen).toList();
      final ohne = zeilen.firstWhere((z) => z.startsWith('BE = 3.000.000'));
      expect(ptRechnung(ohne).ergebnis, isNull);
      expect(ptRechnung('BE = 400.000 €').ergebnis, '400.000 €');
      expect(ptRechnung(zeilen.last).ergebnis, '400.000 €');
    });

    test('P-OK-20221115-s3: Tabelle mit leerem Eckfeld hat Kopfzeile', () {
      final t = ptBloecke(schritt('P-OK-20221115-s3').a).whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first.first, '');
      expect(t.zeilen.first[1], '… aus Sicht der Mitarbeiter');
    });

    test('P-OK-20211116-s0: Checkliste als Formular, danach Datum und Unterschrift', () {
      final b = ptBloecke(schritt('P-OK-20211116-s0').a);
      final t = b.whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first,
          ['Prüfpunkt', 'Ja', 'Nein', 'Nicht zutreffend', 'Maßnahme', 'Termin/verantwortlich']);
      expect(t.koerper.length, 21);
      final beschriftungen = b.whereType<PtBeschriftung>().map((x) => x.text).toList();
      expect(beschriftungen, containsAll(['Datum:', 'Unterschrift:']));
    });

    test('P-OK-20251112-s12: Bewertungsbogen mit Skala als Kopf und Kästchen, Hinweis', () {
      final b = ptBloecke(schritt('P-OK-20251112-s12').a);
      final t = b.whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first, ['', '++', '+', '0', '−', '− −']);
      expect(t.koerper.first.skip(1).every((z) => z == '☐'), isTrue);
      final h = b.whereType<PtHinweis>().single;
      expect(h.praefix, 'Hinweis für den Korrektor:');
    });

    test('P-OK-20260507-s6: Kostenvergleich mit Kopf und 6 Zeilen', () {
      final t = ptBloecke(schritt('P-OK-20260507-s6').a).whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first, ['Kosten pro Jahr', 'Diesel-Lkw', 'Batterie-Lkw']);
      expect(t.koerper.length, 6);
    });
  });

  group('Regeln', () {
    test('kurze Zeilen werden hinter der ersten Zelle aufgefüllt', () {
      final t = ptBloecke('a | b | c\nd | e').single as PtTabelle;
      expect(t.zeilen[1], ['d', '', 'e']);
    });

    test('eine Zeile mit langer Zelle ist ein Absatz', () {
      final lang = 'x' * 61;
      final b = ptBloecke('$lang | kurz').single;
      expect(b, isA<PtZellenAbsatz>());
    });

    test('Sätze mit Gleichheitszeichen bleiben Absätze', () {
      expect(ptIstRechnung('Die Kosten werden jeweils anteilig verteilt, sodass gilt = gleich viel'), isFalse);
      expect(ptIstRechnung('Umlauf: (20 min + 6 min + 4 min) · 2 = 60 min'), isTrue);
    });

    test('Leerzeile gibt größeren Abstand', () {
      final b = ptBloecke('eins\n\nzwei');
      expect(b[1].abstand, isTrue);
      expect(b[0].abstand, isFalse);
    });
  });

  test('Alle Original-Prüfungen: kein „ | “ mehr, kein Zeichen verloren', () {
    var texte = 0, tabellen = 0, mitKopf = 0, rechen = 0, listen = 0, verluste = 0;
    String zeichen(String s) => s.replaceAll(RegExp(r'\s'), '');
    final liste = RegExp(r'^\s*(?:[–•▪■◦]|-(?=\s))\s+', multiLine: true);
    void pruefe(String? text, String wo) {
      if (text == null || text.trim().isEmpty) return;
      texte++;
      final b = ptBloecke(text);
      for (final x in b) {
        if (x is PtTabelle) {
          tabellen++;
          if (x.kopf) mitKopf++;
        }
        if (x is PtRechenblock) rechen++;
        if (x is PtListe) listen++;
      }
      // Vergleich ohne Leerraum, Tabellenstriche und Aufzählungszeichen
      final soll = zeichen(text.split('\n').map((l) {
        if (ptIstTabellenzeile(l)) return l.replaceAll('|', ' ');
        return l.replaceFirst(liste, '');
      }).join('\n'));
      final ist = zeichen(ptKlartext(b));
      if (soll != ist) {
        verluste++;
        fail('$wo: Text verändert\nsoll: $soll\nist:  $ist');
      }
      for (final x in b) {
        if (x is PtAbsatz) expect(x.text.contains(' | '), isFalse, reason: wo);
      }
    }

    for (final c in pruefungen) {
      pruefe(c.context, '${c.id} context');
      for (final a in c.aufgaben) {
        pruefe(a.sit, '${c.id} Aufgabe ${a.nr}');
      }
      for (final s in c.steps) {
        pruefe(s.q, '${s.id} q');
        pruefe(s.a, '${s.id} a');
      }
    }
    // ignore: avoid_print
    print('$texte Texte, $tabellen Tabellen ($mitKopf mit Kopf), $rechen Rechenblöcke, '
        '$listen Listen, $verluste Verluste');
    expect(verluste, 0);
    expect(tabellen, greaterThan(100));
  });

  testWidgets('PruefText zeigt Tabellen ohne Striche und Punkte ohne Klammern', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final texte = [
      aufgabe('P-OK-20221115', 3).sit,
      schritt('P-OK-20231121-s10').a!,
      schritt('P-OK-20211116-s0').a!,
      schritt('P-OK-20260507-s6').a!,
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [for (final t in texte) PruefText(t)]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final sichtbar = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('\n');
    expect(sichtbar.contains(' | '), isFalse);
    expect(sichtbar, contains('Anzahl Bahnhöfe'));
    expect(sichtbar, contains('520 Personen'));
    expect(find.text('Berechnung 2 Punkte, je Maßnahme 1 Punkt, insgesamt max. 5 Punkte'), findsOneWidget);
  });
}
