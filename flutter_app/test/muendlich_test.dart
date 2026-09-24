import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/features/muendlich.dart';
import 'package:kvm_trainer/lernen/muendlich_logik.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/screens/muendlich_screen.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';

/// Mündliche Prüfung üben (FR-011): Eignung, Begriffe, Ablauf und Lernstand.
class _Sprache implements MuendlichSprache {
  _Sprache({this.erkennung = true});
  @override
  final bool erkennung;
  @override
  bool get vorlesen => true;
  final List<String> gesprochen = [];
  void Function(String text, bool endgueltig)? onText;
  void Function()? onEnde;
  void Function(String fehler)? onFehler;

  @override
  Future<void> sprechen(String text) async => gesprochen.add(text);
  @override
  Future<void> stop() async {}
  @override
  Future<bool> diktatStarten({
    required void Function(String text, bool endgueltig) onText,
    required void Function() onEnde,
    required void Function(String fehler) onFehler,
  }) async {
    this.onText = onText;
    this.onEnde = onEnde;
    this.onFehler = onFehler;
    return true;
  }

  @override
  Future<void> diktatBeenden() async {}
}

List<Question> _alleFragen() => (json.decode(File('assets/data/questions.json').readAsStringSync()) as List)
    .map((e) => Question.fromJson(e as Map<String, dynamic>))
    .toList();

void main() {
  group('Begriffe', () {
    test('Referenzsatz: Großgeschriebene zuerst, keine Füllwörter, höchstens 8', () {
      final b = begriffe('Boden, Arbeit und Kapital sind die originären Produktionsfaktoren …');
      expect(b.first, 'Boden');
      expect(b, contains('Produktionsfaktoren'));
      expect(b, isNot(contains('sind')));
      expect(b, ['Boden', 'Arbeit', 'Kapital', 'Produktionsfaktoren', 'originären']);
      expect(begriffe('Arbeit arbeit ARBEIT Wirtschaft werden während zwischen'), ['Arbeit', 'Wirtschaft']);
      expect(begriffe(List.generate(12, (i) => 'Begriff${String.fromCharCode(97 + i)}').join(' ')).length, 8);
    });

    test('Treffer über den Wortstamm', () {
      expect(wortstamm('Produktionsfaktoren'), 'produkti');
      expect(wortstamm('Leistungen'), 'leist');
      expect(wortstamm('Kapital'), 'kapital');
      expect(begriffGetroffen('Produktionsfaktoren', 'die produktionsfaktor boden'), isTrue);
      expect(begriffGetroffen('Arbeit', 'Die ARBEITSKRAFT zählt'), isTrue);
      expect(begriffGetroffen('Kapital', 'Boden und Arbeit'), isFalse);
    });

    test('Quelle: bei Auswahlfragen die richtige Option, sonst die Musterlösung', () {
      final fragen = _alleFragen();
      final mc = fragen.firstWhere((q) => q.id == 'B-VW-001');
      expect(begriffeQuelle(mc), 'Boden, Arbeit und Kapital');
      expect(muendlichLoesung(mc), startsWith('Boden, Arbeit und Kapital\n\n'));
      final offen = fragen.firstWhere((q) => q.id == 'B-VW-033');
      expect(begriffeQuelle(offen), offen.a);
    });
  });

  group('Eignung', () {
    Question mc(String q, {bool richtig = true}) =>
        Question(id: 'x', f: 1, sub: 's', type: 'mc', q: q, o: [Opt(t: 'A', ok: richtig), const Opt(t: 'B')]);

    test('Auswahlfragen nur, wenn sie allein verständlich sind', () {
      expect(muendlichGeeignet(mc('Wie heißt das Gremium der Arbeitnehmer?')), isTrue);
      expect(muendlichGeeignet(mc('Welche Aussage zum Kündigungsschutz trifft zu?')), isFalse);
      expect(muendlichGeeignet(mc('Was gehört nicht zu den Pflichten?')), isFalse);
      expect(muendlichGeeignet(mc('Wie heißt das Gremium der Arbeitnehmer')), isFalse);
      expect(muendlichGeeignet(mc('Wie heißt das Gremium der Arbeitnehmer?', richtig: false)), isFalse);
      expect(muendlichGeeignet(mc('${'Sehr lange Frage ' * 13}?')), isFalse);
      expect(muendlichGeeignet(const Question(id: 'o', f: 1, sub: 's', type: 'open', q: 'Erläutern Sie …', a: 'Lösung')),
          isTrue);
      expect(muendlichGeeignet(const Question(id: 'c', f: 1, sub: 's', type: 'calc', q: 'Wie viel?')), isFalse);
    });

    test('Im Fragenbestand: 2.353 Auswahl- und 88 offene Fragen (wie im Web)', () {
      final geeignet = _alleFragen().where(muendlichGeeignet).toList();
      expect(geeignet.where((q) => q.type == 'mc').length, 2353);
      expect(geeignet.where((q) => q.type == 'open').length, 88);
    });
  });

  group('Ablauf', () {
    Future<void> laden(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        await DataService.instance.load();
        await ProgressService.instance.load();
        await LerntageService.instance.load();
      });
    }

    Future<void> tippe(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pump();
      await tester.tap(find.text(text));
      await tester.pump();
    }

    testWidgets('Zuhören, korrigieren, Lösung, Selbstcheck – der Lernstand zählt wie im Web', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await laden(tester);
      final data = DataService.instance;
      final pool = [
        data.questions.firstWhere((q) => q.id == 'B-VW-001'),
        data.questions.firstWhere((q) => q.id == 'B-VW-033'),
        data.questions.firstWhere((q) => q.id == 'B-VW-101'),
      ];
      final sprache = _Sprache();
      await tester.pumpWidget(MaterialApp(home: MuendlichScreen(pool: pool, fach: 2, sub: 'Volkswirtschaft', sprache: sprache)));
      await tester.pump();

      // Frage 1/3 wird vorgelesen
      expect(find.text('Frage 1/3'), findsOneWidget);
      expect(find.text('BWL · MÜNDLICH'), findsOneWidget);
      expect(sprache.gesprochen, [pool[0].q]);
      expect(find.text('Antworten'), findsOneWidget);
      expect(find.text('Ohne Mikrofon'), findsOneWidget);

      // Antworten → „Ich höre zu …“ mit Live-Mitschrift → Fertig → korrigierbar
      await tippe(tester, 'Antworten');
      expect(find.text('Ich höre zu …'), findsOneWidget);
      sprache.onText!('Die Produktionsfaktoren sind Boden', false);
      await tester.pump();
      expect(find.textContaining('Produktionsfaktoren sind Boden', findRichText: true), findsOneWidget);
      await tippe(tester, 'Fertig');
      expect(find.text('Deine Antwort · bei Hörfehlern einfach korrigieren'.toUpperCase()), findsOneWidget);
      // die letzten Worte kommen nach „Fertig“ noch an
      sprache.onText!('Die Produktionsfaktoren sind Boden und Arbeit', true);
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Die Produktionsfaktoren sind Boden und Arbeit'), findsOneWidget);

      // Lösung: eigene Antwort, richtige Antwort, Begriffe mit Treffern
      await tippe(tester, 'Lösung zeigen');
      expect(find.text('RICHTIGE ANTWORT'), findsOneWidget);
      expect(find.textContaining('2 von 3', findRichText: true), findsOneWidget);

      // Gewusst → Frage 2/3, erster Punkt grün, Lernstand richtig
      await tippe(tester, 'Gewusst');
      expect(find.text('Frage 2/3'), findsOneWidget);
      expect(ProgressService.instance.get(pool[0].id)!.correct, 1);
      expect(sprache.gesprochen.last, pool[1].q);

      // Ohne Mikrofon → Stichpunkte → Teilweise: Box bleibt, nur der Lerntag zählt
      await tippe(tester, 'Ohne Mikrofon');
      await tester.enterText(find.byType(TextField), 'Minimalprinzip');
      await tippe(tester, 'Lösung zeigen');
      expect(find.text('MUSTERLÖSUNG'), findsOneWidget);
      await tippe(tester, 'Teilweise');
      expect(ProgressService.instance.get(pool[1].id), isNull);

      // Nicht gewusst → falsch; danach das Ergebnis
      await tippe(tester, 'Ohne Mikrofon');
      await tippe(tester, 'Lösung zeigen');
      expect(find.text('— keine Antwort notiert —'), findsOneWidget);
      await tippe(tester, 'Nicht gewusst');
      await tester.pumpAndSettle();
      expect(ProgressService.instance.get(pool[2].id)!.wrong, 1);
      expect(LerntageService.instance.anTag(LerntageService.heute()), 3);
      expect(find.text('MÜNDLICH ÜBEN'), findsOneWidget);
      expect(find.textContaining('1 von 3 richtig', findRichText: true), findsOneWidget);
      // „Teilweise“ und „Nicht gewusst“ landen bei den Fehlern
      expect(find.text('Nur Fehler wiederholen (2)'), findsOneWidget);
    });

    testWidgets('Ohne Spracherkennung: Stichpunkt-Feld statt Mikrofon', (tester) async {
      await laden(tester);
      final q = DataService.instance.questions.firstWhere((q) => q.id == 'B-VW-001');
      await tester.pumpWidget(
          MaterialApp(home: MuendlichScreen(pool: [q, q, q], fach: 2, sub: '*', sprache: _Sprache(erkennung: false))));
      await tester.pump();
      expect(find.text('Antworten'), findsNothing);
      expect(find.text('DEINE ANTWORT · STICHPUNKTE'), findsOneWidget);
      expect(find.text('Lösung zeigen'), findsOneWidget);
    });

    testWidgets('Kein Mikrofonrecht: Hinweis, Antwort per Hand', (tester) async {
      await laden(tester);
      final q = DataService.instance.questions.firstWhere((q) => q.id == 'B-VW-001');
      final sprache = _Sprache();
      await tester.pumpWidget(MaterialApp(home: MuendlichScreen(pool: [q, q, q], fach: 2, sub: '*', sprache: sprache)));
      await tester.pump();
      await tippe(tester, 'Antworten');
      sprache.onFehler!('error_permission');
      sprache.onEnde!();
      await tester.pump();
      expect(find.text(kKeinMikrofon), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Zu wenige passende Fragen: Hinweis statt Übung', (tester) async {
      await laden(tester);
      AppState.instance.fach = 2;
      AppState.instance.sub = 'Gibt es nicht';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () => starteMuendlich(c), child: const Text('los')))),
      ));
      await tester.tap(find.text('los'));
      await tester.pump();
      expect(find.text('Für diesen Bereich gibt es noch keine passenden Fragen fürs Fachgespräch.'), findsOneWidget);
      expect(muendlichMoeglich(), isFalse);
      AppState.instance.sub = 'Volkswirtschaft';
      expect(muendlichMoeglich(), isTrue);
      expect(muendlichBeschreibung(), startsWith('10 Fragen aus „Volkswirtschaft“ werden vorgelesen – du antwortest frei'));
      AppState.instance.sub = '*';
    });
  });
}
