import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/pruefung/pruef_text.dart';

import 'pruefdaten.dart';

// Testfälle aus FR-003 A. Die Texte sind erfunden, aber wie die genannten
// Original-Prüfungen aufgebaut (die stehen nicht im Repository).

/// Wie P-OK-20221115, Aufgabe 3: Absatz, dann drei Wertelisten mit Beschriftung.
const _wertelisten = '''Ein Beispielunternehmen will sich um eine neue Schnellbuslinie bewerben und beauftragt Sie, die nötigen Anforderungen zu berechnen.
Für die bisherige Verbindung liegen folgende Daten vor (Anlage 3):
Anzahl Haltestellen | 6
Fahrgäste in der Hauptverkehrszeit zwischen 06:00 Uhr und 09:00 Uhr | 480 Personen
Betriebsleistung (ohne Leerkilometer) | 5,2 Mio. Platzkilometer/Jahr
Strecke | 12 km
Für den Betrieb mit den Schnellbussen ist geplant:
Reisegeschwindigkeit | 32 km/h
Wendezeit an beiden Endpunkten | jeweils 5 min
Aufenthalt je Haltestelle | 1 min
Daten der Busse aus dem eigenen Fuhrpark:
Sitzplätze | 60
Kraftstoffverbrauch | 40 l/100 km
Nutzungszeit | 12 Jahre''';

/// Wie P-MI-20200505, Aufgabe 2: Absatz, Tabelle mit Kopf und 9 Zeilen, Absatz.
const _ablaufplan = '''Ihr Team legt Ihnen den folgenden Ablaufplan für ein Beispielprojekt vor.
Nr. | Vorgang | Dauer in Tagen | Vorgänger
1 | A | 2 | Start
2 | B | 1 | Start
3 | C | 3 | A
4 | D | 2 | B, C
5 | E | 4 | C
6 | F | 1 | D
7 | G | 3 | E
8 | H | 2 | G
9 | I | 2 | F, G
In Anlage 1 finden Sie einen begonnenen Netzplan.''';

/// Wie P-OK-20231121-s10: Rechenblock, Absatz, Beschriftung, Liste, Punkte-Marke.
const _quote = '''Fehlerquote = Zahl der Fehler pro Woche ÷ Zahl der Aufträge pro Woche
(12 ÷ 120) · 100 = 10%
Abweichung: +2 %
Maßnahmen:
– Abläufe überprüfen
– Mitarbeitende schulen
– Ladungssicherung kontrollieren
– Übergaben dokumentieren
(Rechnung 2 Punkte, je Maßnahme 1 Punkt, zusammen höchstens 6 Punkte)''';

/// Wie P-BW-20230504-s14: Liste, Absatz, Rechenblock und mehr.
const _gewinnschwelle = '''– die Fixkosten
In der Gewinnschwelle decken die Deckungsbeiträge genau die Fixkosten von 2.000.000 €, es entsteht weder Gewinn noch Verlust.
G = DB - Kf
G = 0 → DB = Kf
– den Umsatz in der Gewinnschwelle
In der Gewinnschwelle sind Umsatz und Gesamtkosten gleich.
Es gilt: U = K
U = 2.000.000 € + 6.000.000 € = 8.000.000 €
G = DB - Kf
G = 2.000.000 € ÷ 80 · 90 − 2.000.000 €
G = 250.000 €''';

/// Wie P-OK-20221115-s3: Tabelle mit leerem Eckfeld.
const _eckfeld = '''Gründe für ein Jahresgespräch, z. B.:
 | … aus Sicht der Mitarbeitenden | … aus Sicht der Führungskraft | … aus Sicht des Betriebs
1. | Rückmeldung an die Führungskraft | Ziele für das nächste Jahr abstimmen | Bindung an den Betrieb stärken
2. | Erwartungen klären | Arbeitsqualität verbessern | Motivation fördern
3. | Weiterbildung ansprechen | Führungsrolle wahrnehmen | Kommunikation verbessern''';

/// Wie P-OK-20211116-s0: Checkliste als Formular (21 Zeilen, auch lange
/// Zellen), danach Datum und Unterschrift.
final _checkliste = [
  'Checkliste, z. B.:',
  'Prüfpunkt | Ja | Nein | Entfällt | Maßnahme | Termin/zuständig',
  'Prüfungen vor Arbeitsbeginn |  |  |  |  |',
  for (var i = 1; i <= 20; i++)
    i % 7 == 3
        ? '$i. Sind alle Schutzeinrichtungen am Beispielgerät vollständig und ohne Schäden (auch an den Befestigungen und Sperren)? |  |  |  |  |'
        : '$i. Ist Prüfpunkt $i am Beispielgerät in Ordnung? |  |  |  |  |',
  'Datum:',
  'Unterschrift:',
  '(je Prüfpunkt 1 Punkt und 2 Punkte für die Form, zusammen höchstens 22 Punkte)',
].join('\n');

/// Wie P-OK-20251112-s12: Bewertungsbogen mit Skala als Kopf und Kästchen, Hinweis.
const _bewertungsbogen = '''Z. B.:
Bewertungsbogen
Schulung Modul … (Beispiel)
| ++ | + | 0 | − | − −
Die Inhalte wurden verständlich vermittelt. | ☐ | ☐ | ☐ | ☐ | ☐
Die Zeit für Fragen war angemessen. | ☐ | ☐ | ☐ | ☐ | ☐
Die Unterlagen waren hilfreich. | ☐ | ☐ | ☐ | ☐ | ☐
Das Wissen lässt sich in der Praxis anwenden. | ☐ | ☐ | ☐ | ☐ | ☐
Hinweis für den Korrektor: Auch andere sinnvolle Kriterien sind zu werten.''';

/// Wie P-OK-20260507-s6: Kostenvergleich mit Kopf und 6 Zeilen.
const _kostenvergleich = '''Kosten pro Jahr | Diesel-Lkw | Batterie-Lkw
Abschreibung | 100.000 € ÷ 8 a = 12.500 €/a | 240.000 € ÷ 8 a = 30.000 €/a
Verzinsung des Kaufpreises | (100.000 € ÷ 2) · 3 % = 1.500 €/a | (240.000 € ÷ 2) · 3 % = 3.600 €/a
Kraftstoff- bzw. Energiekosten | (60.000 km ÷ 100 km) · 1,60 €/l · 25 l = 24.000 €/a | 60.000 km · 0,25 €/kWh · 1,4 kWh/km = 21.000 €/a
Abschreibung Ladestation (anteilig) |  | 30.000 € ÷ 15 a = 2.000 €/a
Verzinsung Ladestation (anteilig) |  | (30.000 € ÷ 2) · 3 % = 450 €/a
Summe | 38.000 €/a | 57.050 €/a''';

/// Prüfungstexte strukturiert darstellen (FR-003 A): Testfälle aus der
/// Anforderung und – mit dem privaten Paket – ein Durchlauf über alle
/// Original-Prüfungen.
void main() {
  group('Testfälle aus FR-003 A', () {
    test('Absatz, dann drei Wertelisten mit Beschriftung', () {
      final b = ptBloecke(_wertelisten);
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

    test('Tabelle mit Kopf und 9 Zeilen', () {
      final t = ptBloecke(_ablaufplan).whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first, ['Nr.', 'Vorgang', 'Dauer in Tagen', 'Vorgänger']);
      expect(t.koerper.length, 9);
    });

    test('Rechenblock mit Ergebnis „10%“, Beschriftung, Liste, Punkte-Marke', () {
      final b = ptBloecke(_quote);
      final r = b.first as PtRechenblock;
      expect(r.zeilen.length, 2);
      expect(ptRechnung(r.zeilen.last).ergebnis, '10%');
      expect(b.whereType<PtBeschriftung>().first.text, 'Maßnahmen:');
      expect(b.whereType<PtListe>().single.punkte.length, 4);
      final letzter = b.last as PtAbsatz;
      expect(ptPunkte.hasMatch(letzter.text), isTrue);
    });

    test('Liste, Absatz, Rechenblock; Rechnung hinter „=“ ohne Hervorhebung', () {
      final b = ptBloecke(_gewinnschwelle);
      expect(b[0], isA<PtListe>());
      expect(b[1], isA<PtAbsatz>());
      expect(b[2], isA<PtRechenblock>());
      final zeilen = b.whereType<PtRechenblock>().expand((r) => r.zeilen).toList();
      final ohne = zeilen.firstWhere((z) => z.startsWith('G = 2.000.000'));
      expect(ptRechnung(ohne).ergebnis, isNull);
      expect(ptRechnung('G = 250.000 €').ergebnis, '250.000 €');
      expect(ptRechnung(zeilen.last).ergebnis, '250.000 €');
    });

    test('Tabelle mit leerem Eckfeld hat Kopfzeile', () {
      final t = ptBloecke(_eckfeld).whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first.first, '');
      expect(t.zeilen.first[1], '… aus Sicht der Mitarbeitenden');
    });

    test('Checkliste als Formular, danach Datum und Unterschrift', () {
      final b = ptBloecke(_checkliste);
      final t = b.whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first,
          ['Prüfpunkt', 'Ja', 'Nein', 'Entfällt', 'Maßnahme', 'Termin/zuständig']);
      expect(t.koerper.length, 21);
      final beschriftungen = b.whereType<PtBeschriftung>().map((x) => x.text).toList();
      expect(beschriftungen, containsAll(['Datum:', 'Unterschrift:']));
    });

    test('Bewertungsbogen mit Skala als Kopf und Kästchen, Hinweis', () {
      final b = ptBloecke(_bewertungsbogen);
      final t = b.whereType<PtTabelle>().single;
      expect(t.kopf, isTrue);
      expect(t.zeilen.first, ['', '++', '+', '0', '−', '− −']);
      expect(t.koerper.first.skip(1).every((z) => z == '☐'), isTrue);
      final h = b.whereType<PtHinweis>().single;
      expect(h.praefix, 'Hinweis für den Korrektor:');
    });

    test('Kostenvergleich mit Kopf und 6 Zeilen', () {
      final t = ptBloecke(_kostenvergleich).whereType<PtTabelle>().single;
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
      expect(ptIstRechnung('Umlauf: (15 min + 5 min + 5 min) · 2 = 50 min'), isTrue);
    });

    test('Leerzeile gibt größeren Abstand', () {
      final b = ptBloecke('eins\n\nzwei');
      expect(b[1].abstand, isTrue);
      expect(b[0].abstand, isFalse);
    });
  });

  test('Alle Original-Prüfungen: kein „ | “ mehr, kein Zeichen verloren', () {
    final pruefungen = originalPruefungen();
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
  }, skip: nurMitPrivat);

  testWidgets('PruefText zeigt Tabellen ohne Striche und Punkte ohne Klammern', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final texte = [_wertelisten, _quote, _checkliste, _kostenvergleich];
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
    expect(sichtbar, contains('Anzahl Haltestellen'));
    expect(sichtbar, contains('480 Personen'));
    expect(find.text('Rechnung 2 Punkte, je Maßnahme 1 Punkt, zusammen höchstens 6 Punkte'), findsOneWidget);
  });
}
