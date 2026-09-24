import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/pruefung/echt.dart';
import 'package:kvm_trainer/pruefung/ergebnisse.dart';
import 'package:kvm_trainer/screens/aufgabenblatt_screen.dart';
import 'package:kvm_trainer/screens/pruefungen_screen.dart';
import 'package:kvm_trainer/services/answer_store.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/letzte_pruefung.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/selection_service.dart';
import 'package:kvm_trainer/widgets/anlage_tabelle.dart';
import 'package:kvm_trainer/widgets/werkzeug_dock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abläufe im Aufgabenblatt und im Ergebnis nach den Abnahmekriterien von
/// FR-003 B, FR-007, FR-013 und FR-014.
CaseStudy _fall(String id) => DataService.instance.cases.firstWhere((c) => c.id == id);

Future<void> _laden(WidgetTester tester, [Map<String, Object> werte = const {}]) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(werte);
  await tester.runAsync(() async {
    await DataService.instance.load();
    await SelectionService.instance.load();
    await ProgressService.instance.load();
    await LerntageService.instance.load();
    await LetztePruefung.instance.load();
    await AnswerStore.instance.init();
    await Echtbedingungen.instance.load();
    await PruefErgebnisse.instance.load();
  });
}

Future<void> _zeigen(WidgetTester tester, Widget w) async {
  // Eigener Schlüssel: jedes Mal ein frischer Navigator ohne alte Routen.
  await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: w));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tippen(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Punkte für alle Teile einer Prüfung – bis auf [ohne] die volle Punktzahl.
Map<String, int> _punkte(CaseStudy c, Map<String, int> ohne) =>
    {for (final s in c.steps) s.id: ohne[s.id] ?? s.pts};

void main() {
  testWidgets('FR-014: werten, erneut „Zum Ergebnis“, neu starten, wiederholen', (tester) async {
    await _laden(tester);
    final nt = _fall('P-NT-20150429');
    // 70 von 100 Punkten: Aufgabe 5 (15) leer, 4 b) (10) leer, 6 (10) halb.
    final p = _punkte(nt, {'P-NT-20150429-s11': 0, 'P-NT-20150429-s10': 0, 'P-NT-20150429-s12': 5});
    p.forEach(AnswerStore.instance.setPoints);
    final letzte = nt.steps.indexWhere((s) => s.nr == nt.aufgaben.last.nr);

    await _zeigen(tester, AufgabenblattScreen(fall: nt, startIndex: letzte));
    await _tippen(tester, find.text('Zum Ergebnis →'));
    expect(find.text('BESTANDEN · NOTE 3 (BEFRIEDIGEND)'), findsOneWidget);
    expect(find.textContaining('Bestehenschance Naturwiss. & Technik:'), findsOneWidget);
    expect(find.text('Prüfung neu starten'), findsOneWidget);
    expect(find.text('Alle Prüfungen'), findsOneWidget);
    expect(PruefErgebnisse.instance.alle.length, 1);
    final erster = PruefErgebnisse.instance.alle.single;
    expect(erster.pkt, 70);
    expect(erster.gewertet, isTrue);

    // Noch einmal „Zum Ergebnis“ → derselbe Durchgang.
    await _zeigen(tester, AufgabenblattScreen(fall: nt, startIndex: letzte));
    await _tippen(tester, find.text('Zum Ergebnis →'));
    expect(PruefErgebnisse.instance.alle.length, 1);

    // Neu starten: Nachfrage, danach leere Blätter bei Aufgabe 1.
    await _tippen(tester, find.text('Prüfung neu starten'));
    expect(find.text('Prüfung neu starten?'), findsOneWidget);
    await _tippen(tester, find.text('Neu starten'));
    expect(find.text('AUFGABE 1'), findsOneWidget);
    expect(nt.steps.every((s) => AnswerStore.instance.points(s.id) == null), isTrue);
    expect(PruefErgebnisse.instance.alle.length, 1);

    // Wiederholen und werten: Hinweis „Wiederholung“, Chance unverändert.
    final vorher = PruefErgebnisse.instance.statistik().bereiche['NT']!.chance;
    _punkte(nt, {'P-NT-20150429-s11': 5}).forEach(AnswerStore.instance.setPoints);
    await _zeigen(tester, AufgabenblattScreen(fall: nt, startIndex: letzte));
    await _tippen(tester, find.text('Zum Ergebnis →'));
    expect(find.textContaining('Wiederholung:'), findsOneWidget);
    expect(PruefErgebnisse.instance.statistik().bereiche['NT']!.chance, vorher);
    expect(PruefErgebnisse.instance.alle.map((e) => e.pkt).toList(), [70, 90]);

    // In der Liste (nach Bereich gefiltert): „2 Durchgänge: 70 → 90 P“.
    await _zeigen(tester, const Scaffold(body: PruefungenListe()));
    expect(find.text('DEINE ERGEBNISSE'), findsOneWidget);
    await _tippen(tester, find.text('Naturwiss. & Technik').last);
    await tester.scrollUntilVisible(find.text('2 Durchgänge: 70 → 90 P'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('2 Durchgänge: 70 → 90 P'), findsOneWidget);
  });

  testWidgets('FR-014: nur teilweise bewertet zählt nicht', (tester) async {
    await _laden(tester);
    final nt = _fall('P-NT-20150429');
    AnswerStore.instance.setPoints('P-NT-20150429-s0', 1);
    AnswerStore.instance.setPoints('P-NT-20150429-s1', 3);
    final letzte = nt.steps.indexWhere((s) => s.nr == nt.aufgaben.last.nr);
    await _zeigen(tester, AufgabenblattScreen(fall: nt, startIndex: letzte));
    await _tippen(tester, find.text('Zum Ergebnis →'));
    expect(find.text('NOCH NICHT VOLLSTÄNDIG BEWERTET'), findsOneWidget);
    expect(find.textContaining('2 von 19 Teilaufgaben haben Punkte'), findsOneWidget);
    expect(PruefErgebnisse.instance.alle.single.gewertet, isFalse);
    expect(PruefErgebnisse.instance.statistik().n, 0);
  });

  testWidgets('FR-007: Uhr, keine Aufdecken-Knöpfe, Abgabe nach Ablauf, Ergebnis mit Bearbeitungszeit', (tester) async {
    await _laden(tester, {
      'kvm_open_answers': json.encode({'P-NT-20150429-s0': 'Schwefelsäure'}),
    });
    final nt = _fall('P-NT-20150429');
    PruefErgebnisse.instance.echtStarten(nt);
    // Leere Blätter beim Start
    expect(AnswerStore.instance.get('P-NT-20150429-s0'), '');
    await _zeigen(tester, AufgabenblattScreen(fall: nt));
    expect(find.textContaining(RegExp(r'^(1:00:00|59:\d\d)$')), findsOneWidget);
    expect(find.textContaining('aufdecken'), findsNothing);
    expect(find.text('Abgeben'), findsOneWidget);
    expect(find.textContaining('Unter Prüfungsbedingungen:'), findsOneWidget);

    // 61 Minuten zurückstellen: beim Öffnen automatisch abgegeben.
    final jetzt = DateTime.now().millisecondsSinceEpoch;
    Echtbedingungen.instance.setzen(EchtLauf(id: nt.id, start: jetzt - 61 * 60000, min: 60));
    await _zeigen(tester, const SizedBox());
    await _zeigen(tester, AufgabenblattScreen(fall: nt));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Zeit abgelaufen – deine Antworten sind abgegeben.'), findsOneWidget);
    expect(Echtbedingungen.instance.von(nt.id)!.zeitUm, isTrue);
    expect(find.text('DEINE ANTWORT'), findsWidgets); // Lösungen sind offen

    // Drei Teile bewerten und zum Ergebnis: gewertet, Rest zählt 0.
    for (final id in ['P-NT-20150429-s0', 'P-NT-20150429-s1', 'P-NT-20150429-s2']) {
      AnswerStore.instance.setPoints(id, 1);
    }
    final letzte = nt.steps.indexWhere((s) => s.nr == nt.aufgaben.last.nr);
    await _zeigen(tester, AufgabenblattScreen(fall: nt, startIndex: letzte));
    await _tippen(tester, find.text('Zum Ergebnis →'));
    expect(find.textContaining('Bearbeitungszeit 1 h von 1 h (Zeit abgelaufen)'), findsOneWidget);
    final d = PruefErgebnisse.instance.alle.single;
    expect(d.echt, isTrue);
    expect(d.gewertet, isTrue);
    expect(d.pkt, 3);
    expect(Echtbedingungen.instance.lauf, isNull);
  });

  testWidgets('FR-014: laufende Prüfungsbedingungen über „Neu starten“ abbrechen – Uhr weg', (tester) async {
    await _laden(tester);
    final nt = _fall('P-NT-20150429');
    PruefErgebnisse.instance.echtStarten(nt);
    AnswerStore.instance.set('P-NT-20150429-s0', 'Schwefelsäure');
    final kennung = PruefErgebnisse.instance.lauf(nt.id);

    await _zeigen(tester, const Scaffold(body: PruefungenListe()));
    await _tippen(tester, find.text('Naturwiss. & Technik').last);
    await tester.scrollUntilVisible(find.textContaining('Läuft · noch'), 300, scrollable: find.byType(Scrollable).first);
    await _tippen(tester, find.text('Neu starten'));
    expect(find.textContaining('Der laufende Durchgang unter Prüfungsbedingungen wird abgebrochen.'), findsOneWidget);
    await _tippen(tester, find.text('Neu starten').last);

    expect(Echtbedingungen.instance.lauf, isNull);
    expect(find.text('AUFGABE 1'), findsOneWidget);
    expect(find.text('Abgeben'), findsNothing);
    expect(find.textContaining(RegExp(r'^\d+:\d\d(:\d\d)?$')), findsNothing);
    expect(find.text('Lösung zu a) aufdecken'), findsOneWidget);
    expect(AnswerStore.instance.get('P-NT-20150429-s0'), '');
    expect(PruefErgebnisse.instance.lauf(nt.id), isNot(kennung));
  });

  testWidgets('FR-013: Zeichenaufgabe mit offener Skizze, andere Teile auf Knopfdruck', (tester) async {
    await _laden(tester);
    final mi = _fall('P-MI-20241106');
    await _zeigen(tester, AufgabenblattScreen(fall: mi, startIndex: 4));
    expect(find.text('SKIZZE'), findsOneWidget); // nur 2 a) „Flussdiagramm“
    expect(find.text('Hoch'), findsOneWidget);
    expect(find.text('Erläuterung zur Skizze, z. B. gewählte Diagrammart …'), findsOneWidget);
    final knoepfe = find.widgetWithText(OutlinedButton, 'Skizze');
    expect(knoepfe, findsNWidgets(2));
    await _tippen(tester, knoepfe.first);
    expect(find.text('SKIZZE'), findsNWidgets(2));
  });

  testWidgets('FR-003 B: Rechenweg rechnet, speichert und steht nach dem Aufdecken unter „Deine Antwort“', (tester) async {
    await _laden(tester);
    final ok = _fall('P-OK-20221115');
    await _zeigen(tester, AufgabenblattScreen(fall: ok, startIndex: 6));
    expect(find.text('RECHENWEG'), findsWidgets);
    final rechnung = find.widgetWithText(TextField, 'Rechnung, z. B. 4.400 ÷ 22').first;
    await tester.ensureVisible(rechnung);
    await tester.enterText(rechnung, '4.400 ÷ 22');
    await tester.pump();
    expect(find.text('= 200'), findsOneWidget);
    expect(AnswerStore.instance.calc('P-OK-20221115-s6').single['f'], '4.400 ÷ 22');
    expect(AnswerStore.instance.hatAntwort('P-OK-20221115-s6'), isTrue);
    await _tippen(tester, find.text('Lösung zu a) aufdecken'));
    final text = tester.widgetList<RichText>(find.byType(RichText)).map((r) => r.text.toPlainText()).join('\n');
    expect(text, contains('4.400 ÷ 22 = 200'));
    expect(AnswerStore.instance.antwortText('P-OK-20221115-s6'), '4.400 ÷ 22 = 200');
  });

  testWidgets('FR-002 G: Ausgangssituation offen beim Start, beim Wechsel zu – außer selbst geöffnet', (tester) async {
    await _laden(tester);
    final ok = _fall('P-OK-20221115');
    await _zeigen(tester, AufgabenblattScreen(fall: ok));
    bool sichtbar() => find.textContaining('Fuhrparkleiter').evaluate().isNotEmpty;
    expect(sichtbar(), isTrue);
    await _tippen(tester, find.text('Aufgabe 2 →'));
    expect(sichtbar(), isFalse);
    await _tippen(tester, find.text('LESEN'));
    expect(sichtbar(), isTrue);
    await _tippen(tester, find.text('Aufgabe 3 →'));
    expect(sichtbar(), isTrue);
  });

  // Übernehmen gibt die Teilaufgabe zurück („Aufgabe 3 a)“), damit der Hinweis
  // des Formelbuchs sie nennt; ohne Ziel null.
  Future<String?> uebernehmen(WidgetTester tester, String text) async {
    final Function f = tester.widget<WerkzeugDock>(find.byType(WerkzeugDock)).onUebernehmen!;
    final ziel = f(text) as String?;
    await tester.pump();
    return ziel;
  }

  testWidgets('Werkzeug-Dock: Vorlage landet in der Antwort der offenen Teilaufgabe', (tester) async {
    await _laden(tester);
    final ok = _fall('P-OK-20221115');
    await _zeigen(tester, AufgabenblattScreen(fall: ok, startIndex: 6));
    expect(await uebernehmen(tester, 'Kosten je km:\nWert = …'), 'Aufgabe 3 a)');
    expect(AnswerStore.instance.get('P-OK-20221115-s6'), 'Kosten je km:\nWert = …');
    expect(await uebernehmen(tester, 'Zweite Vorlage:\nx = …'), 'Aufgabe 3 a)');
    expect(AnswerStore.instance.get('P-OK-20221115-s6'), 'Kosten je km:\nWert = …\n\nZweite Vorlage:\nx = …');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Werkzeug-Dock: Rechner-Wert an der Schreibmarke, in Tabellen ohne Tausenderpunkt', (tester) async {
    await _laden(tester);
    final ok = _fall('P-OK-20221115');
    await _zeigen(tester, AufgabenblattScreen(fall: ok, startIndex: 6));
    final rechnung = find.widgetWithText(TextField, 'Rechnung, z. B. 4.400 ÷ 22').first;
    await tester.ensureVisible(rechnung);
    await tester.tap(rechnung);
    await tester.pump();
    expect(await uebernehmen(tester, '1.815'), 'Aufgabe 3 a)');
    expect(AnswerStore.instance.calc('P-OK-20221115-s6').single['f'], '1.815');
    expect(find.text('= 1.815'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));

    final mi = _fall('P-MI-20200505');
    await _zeigen(tester, AufgabenblattScreen(fall: mi, startIndex: 4));
    final zelle = find.descendant(of: find.byType(AnlageTabelle), matching: find.byType(TextField)).first;
    await tester.ensureVisible(zelle);
    await tester.tap(zelle);
    await tester.pump();
    expect(await uebernehmen(tester, '1.234,5'), 'Aufgabe 2 a)');
    expect(AnswerStore.instance.tabWerte('P-MI-20200505-s4#s0')['0-3'], '1234,5');
    await tester.pump(const Duration(milliseconds: 1500));

    // Alle Teile aufgedeckt: kein Ziel.
    await _zeigen(tester, AufgabenblattScreen(fall: ok, startIndex: 6));
    await _tippen(tester, find.text('Alle Lösungen aufdecken'));
    expect(await uebernehmen(tester, 'Vorlage:\nx'), isNull);
  });
}
