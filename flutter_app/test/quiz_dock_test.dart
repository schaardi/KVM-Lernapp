import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/lernen/uebernahme.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/screens/quiz_screen.dart';
import 'package:kvm_trainer/services/answer_store.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/round_builder.dart';
import 'package:kvm_trainer/widgets/werkzeug_dock.dart';

/// Quiz (FR-002 C/D): „Übernehmen“ aus dem Werkzeug-Dock ins aktive
/// Antwortfeld und die einklappbare Ausgangssituation.
void main() {
  group('Übernahme – Logik', () {
    test('Ergebnisfeld: Zahl ohne Tausenderpunkt, ersetzt den Inhalt', () {
      expect(inErgebnisfeld('1.234,5'), '1234,5');
      expect(inErgebnisfeld('1234,5'), '1234,5');
      expect(inErgebnisfeld('4.400'), '4400');
      expect(inErgebnisfeld('−3'), '-3');
      expect(inErgebnisfeld(' 12 '), '12');
      expect(inErgebnisfeld('0,333333333'), '0,333333');
      // eine Formelvorlage oder Rechnung passt nicht ins Ergebnisfeld
      expect(inErgebnisfeld('Selbstkosten = Herstellkosten + Vw-GK'), isNull);
      expect(inErgebnisfeld('12345 ÷ 10'), isNull);
      expect(inErgebnisfeld('Zeile 1\nZeile 2'), isNull);
      expect(inErgebnisfeld(''), isNull);
    });

    test('Ergebnisfeld liest Tausenderpunkte und Minuszeichen', () {
      expect(zahlLesen('4.400'), 4400);
      expect(zahlLesen('1.5'), 1.5);
      expect(zahlLesen('1.234,5'), 1234.5);
      expect(zahlLesen('−3'), -3);
    });

    test('Textantwort: Wert an der Cursorstelle, Vorlage mit Leerzeile angehängt', () {
      expect(inAntwort('', '42').text, '42');
      expect(inAntwort('Ergebnis:', '1.234,5'), (text: 'Ergebnis: 1.234,5', cursor: 17));
      expect(inAntwort('Wert (', '5').text, 'Wert (5');
      expect(inAntwort('abc def', 'X', start: 3, ende: 3), (text: 'abc X def', cursor: 5));
      expect(inAntwort('abc def', 'X', start: 4, ende: 7).text, 'abc X');
      expect(inAntwort('Meine Antwort  \n', 'Zeile 1\nZeile 2').text, 'Meine Antwort\n\nZeile 1\nZeile 2');
      expect(inAntwort('', 'Zeile 1\nZeile 2').text, 'Zeile 1\nZeile 2');
    });
  });

  group('Quiz', () {
    Future<void> laden(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await DataService.instance.load();
        await ProgressService.instance.load();
        await LerntageService.instance.load();
        await AnswerStore.instance.init();
      });
    }

    Question frage(String id) => DataService.instance.questions.firstWhere((q) => q.id == id);

    Future<void> quiz(WidgetTester tester, List<Question> pool) async {
      await tester.pumpWidget(MaterialApp(home: QuizScreen(mode: RoundMode.train, pool: pool, fach: 2, sub: '*')));
      await tester.pump();
    }

    WerkzeugDock dock(WidgetTester tester) => tester.widget<WerkzeugDock>(find.byType(WerkzeugDock));

    testWidgets('Rechenaufgabe: Rechnerwert landet im Ergebnisfeld, „Antwort prüfen“ wird aktiv', (tester) async {
      await laden(tester);
      await quiz(tester, [frage('B-KR-901')]);
      final pruefen = find.widgetWithText(FilledButton, 'Antwort prüfen');
      expect(tester.widget<FilledButton>(pruefen).onPressed, isNull);
      expect(dock(tester).onSprache, isNotNull, reason: 'Sprache sitzt im Dock');
      dock(tester).onUebernehmen!('3.000');
      await tester.pump();
      expect(find.widgetWithText(TextField, '3000'), findsOneWidget);
      expect(tester.widget<FilledButton>(pruefen).onPressed, isNotNull);
      await tester.tap(pruefen);
      await tester.pump();
      expect(find.text('RICHTIG'), findsOneWidget);
      expect(ProgressService.instance.get('B-KR-901')!.correct, 1);
      expect(LerntageService.instance.anTag(LerntageService.heute()), 1);
      // nach dem Prüfen gibt es kein Antwortfeld mehr
      expect(dock(tester).onUebernehmen, isNull);
    });

    testWidgets('Rechenaufgabe: eine Formelvorlage geht in die Zwischenablage', (tester) async {
      await laden(tester);
      String? ablage;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') ablage = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await quiz(tester, [frage('B-KR-901')]);
      dock(tester).onUebernehmen!('Break-even-Menge = Fixkosten ÷ DB je Stück');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(ablage, 'Break-even-Menge = Fixkosten ÷ DB je Stück');
      expect(find.text('Die Vorlage passt nicht ins Ergebnisfeld – sie liegt jetzt in der Zwischenablage.'), findsOneWidget);
    });

    testWidgets('Offene Frage: Übernehmen schreibt in die Antwort und speichert sie', (tester) async {
      await laden(tester);
      final q = frage('B-VW-033');
      await quiz(tester, [q]);
      await tester.enterText(find.byType(TextField), 'Beim Minimalprinzip');
      dock(tester).onUebernehmen!('42');
      await tester.pump();
      expect(AnswerStore.instance.get(q.id), 'Beim Minimalprinzip 42');
      dock(tester).onUebernehmen!('Ziel = Ertrag ÷ Aufwand\nWirtschaftlichkeit = …');
      await tester.pump();
      expect(AnswerStore.instance.get(q.id), 'Beim Minimalprinzip 42\n\nZiel = Ertrag ÷ Aufwand\nWirtschaftlichkeit = …');
      expect(find.widgetWithText(TextField, 'Beim Minimalprinzip 42\n\nZiel = Ertrag ÷ Aufwand\nWirtschaftlichkeit = …'),
          findsOneWidget);
      // nach dem Senden ist das Antwortfeld zu
      await tester.tap(find.text('Senden'));
      await tester.pump();
      expect(dock(tester).onUebernehmen, isNull);
    });

    testWidgets('Auswahlfrage: kein Antwortfeld zum Übernehmen, Begründung nach dem Prüfen', (tester) async {
      await laden(tester);
      await quiz(tester, [frage('B-VW-001')]);
      expect(dock(tester).onUebernehmen, isNull);
      await tester.tap(find.text('Rohstoffe, Arbeit und Kapital'));
      await tester.pump();
      await tester.tap(find.text('Antwort prüfen'));
      await tester.pump();
      expect(find.text('LEIDER FALSCH'), findsOneWidget);
      // Begründungen der falschen Optionen erscheinen, die richtige hat keine
      expect(find.textContaining('Rohstoffe sind kein originärer Produktionsfaktor'), findsOneWidget);
      expect(find.textContaining('Unternehmerisches Wissen zählt nicht'), findsOneWidget);
    });

    testWidgets('Ausgangssituation: bei Teil 1 offen, ab Teil 2 zu – außer selbst geöffnet', (tester) async {
      await laden(tester);
      final fall = DataService.instance.cases.firstWhere(
          (c) => !c.id.startsWith('P-') && c.steps.length >= 3 && c.steps.take(3).every((s) => s.type != 'open'));
      final pool = fall.asPool();
      await quiz(tester, pool);
      final kontext = find.textContaining(fall.context.substring(0, 30));
      expect(kontext, findsOneWidget);
      expect(find.text('FALLAUFGABE'), findsOneWidget);

      Future<void> tippe(Finder f) async {
        // Die Liste baut nur, was (fast) im Bild ist.
        if (f.evaluate().isEmpty) {
          await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
        }
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        await tester.pump();
      }

      // Teil beantworten – worauf, ist hier gleich
      Future<void> weiter(Question q) async {
        if (q.type == 'mc') {
          await tippe(find.text(q.o.first.t).first);
          await tippe(find.text('Antwort prüfen'));
        } else {
          await tippe(find.text('Lösung zeigen'));
        }
        await tippe(find.text('Weiter'));
      }

      await weiter(pool[0]);
      expect(kontext, findsNothing, reason: 'ab Teil 2 zugeklappt');
      // selbst aufklappen – dann bleibt sie offen
      await tippe(find.textContaining('AUSGANGSSITUATION'));
      expect(kontext, findsOneWidget);
      await weiter(pool[1]);
      expect(kontext, findsOneWidget, reason: 'vom Nutzer geöffnet');
    });
  });
}
