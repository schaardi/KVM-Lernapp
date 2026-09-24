import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:kvm_trainer/constants.dart';
import 'package:kvm_trainer/features/melden.dart';
import 'package:kvm_trainer/main.dart' show themaFuer;
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/werkzeuge/melden_dialog.dart';
import 'package:kvm_trainer/werkzeuge/melden_dienst.dart';

/// Fehler melden (FR-008, Nachtrag FR-013): Knopf nur mit Bereitschaft,
/// Dialog, Senden über eine austauschbare Funktion (ohne Netz), Kontext.
void main() {
  final dienst = MeldenDienst.instance;
  final gesendet = <Map<String, dynamic>>[];
  late Question frage;
  late Question teil;

  Future<void> starten(WidgetTester tester, Widget kind, {Size groesse = const Size(390, 844)}) async {
    tester.view.physicalSize = groesse * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await DataService.instance.load();
      await dienst.laden();
    });
    dienst.zuruecksetzen();
    gesendet.clear();
    dienst.sender = (p) async => gesendet.add(p);
    frage = DataService.instance.questions.firstWhere((q) => q.q.length > 170);
    teil = DataService.instance.cases.firstWhere((c) => c.id.startsWith('P-')).steps.first;
    await tester.pumpWidget(MaterialApp(
      theme: themaFuer(KvmPalette.light),
      home: Scaffold(body: Center(child: kind)),
    ));
  }

  tearDown(() => dienst.zuruecksetzen());

  /// In Sicht scrollen, dann tippen (der Dialog scrollt bei wenig Platz).
  Future<void> tippe(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  testWidgets('Ohne Bereitschaft kein Knopf; mit Bereitschaft „Fehler?“, kompakt nur Symbol', (tester) async {
    await starten(tester, const Column(mainAxisSize: MainAxisSize.min, children: [
      MeldenKnopf(frageId: 'X-1', bezug: 'Frage'),
      MeldenKnopf(frageId: 'X-1', bezug: 'Frage', kompakt: true),
    ]));
    expect(find.text('Fehler?'), findsNothing);
    expect(find.byIcon(Icons.outlined_flag), findsNothing);
    dienst.bereit.value = true;
    await tester.pump();
    expect(find.text('Fehler?'), findsOneWidget);
    expect(find.byIcon(Icons.outlined_flag), findsNWidgets(2));
  });

  testWidgets('Bereitschaft: true zeigt Knöpfe, Fehler (PGRST202) nicht', (tester) async {
    await starten(tester, const SizedBox());
    dienst.abfrage = () async => true;
    await dienst.bereitPruefen();
    expect(dienst.bereit.value, isTrue);
    dienst.abfrage = () async => throw const PostgrestException(message: 'Could not find the function', code: 'PGRST202');
    await dienst.bereitPruefen();
    expect(dienst.bereit.value, isFalse);
  });

  testWidgets('Dialog: Nummer und Auszug, senden erst mit Art, Erfolg, „Gemeldet ✓“', (tester) async {
    await starten(tester, const SizedBox());
    await tester.pumpWidget(MaterialApp(
      theme: themaFuer(KvmPalette.light),
      home: Scaffold(body: Center(child: MeldenKnopf(frageId: frage.id, bezug: frage.q))),
    ));
    dienst.bereit.value = true;
    await tester.pump();
    await tester.tap(find.text('Fehler?'));
    await tester.pumpAndSettle();

    expect(find.text('FEHLER MELDEN'), findsOneWidget);
    final auszug = frage.q.replaceAll(RegExp(r'\s+'), ' ').trim().substring(0, 160);
    expect(find.textContaining(frage.id), findsWidgets);
    expect(find.textContaining('$auszug …'), findsOneWidget);
    for (final (_, t) in kMeldeArten) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Was stimmt nicht?'), findsOneWidget);
    expect(
        find.text('Gesendet werden die Fragennummer, deine Angaben und – falls du angemeldet bist – '
            'dein Konto für Rückfragen.'),
        findsOneWidget);

    final senden = find.widgetWithText(FilledButton, 'Meldung senden');
    expect(tester.widget<FilledButton>(senden).onPressed, isNull, reason: 'ohne Art nicht senden');
    await tester.tap(senden);
    await tester.pump();
    expect(gesendet, isEmpty);

    await tester.tap(find.text('Rechnung oder Zahl falsch'));
    await tester.enterText(find.byType(TextField), 'Das Ergebnis muss 200 lauten.');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Meldung senden'));
    await tester.pump();

    expect(gesendet, hasLength(1));
    final p = gesendet.single;
    expect(p['p_frage'], frage.id);
    expect(p['p_art'], 'rechnung');
    expect(p['p_text'], 'Das Ergebnis muss 200 lauten.');
    expect(p['p_quelle'], 'app');
    expect(p['p_kontext'], {'modus': 'quiz', 'fach': frage.f, 'bereich': frage.sub, 'auszug': auszug});
    expect(find.text('Danke! Deine Meldung ist angekommen.'), findsOneWidget);
    expect(find.text('Gesendet ✓'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('FEHLER MELDEN'), findsNothing, reason: 'schließt nach 1,4 s');
    expect(find.text('Gemeldet ✓'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect((jsonDecode(prefs.getString('kvm_gemeldet')!) as Map).keys, [frage.id]);
  });

  testWidgets('Fehler beim Senden: Bremse und offline, Knopf wieder aktiv', (tester) async {
    await starten(tester, const SizedBox());
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      return Scaffold(
          body: Center(
              child: TextButton(
                  onPressed: () => oeffneMelden(c, frageId: frage.id, bezug: frage.q), child: const Text('los'))));
    })));
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lösung falsch'));
    await tester.pump();

    dienst.sender = (_) async => throw const PostgrestException(message: 'zu viele Meldungen', code: 'P0001');
    await tester.tap(find.widgetWithText(FilledButton, 'Meldung senden'));
    await tester.pump();
    expect(find.text('Gerade gehen zu viele Meldungen ein – bitte später noch einmal.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Meldung senden')).onPressed, isNotNull);

    dienst.sender = (_) async => throw Exception('SocketException: Failed host lookup');
    await tester.tap(find.widgetWithText(FilledButton, 'Meldung senden'));
    await tester.pump();
    expect(find.text('Senden hat nicht geklappt. Bist du online? Bitte noch einmal versuchen.'), findsOneWidget);
    expect(dienst.istGemeldet(frage.id), isFalse);
  });

  testWidgets('Teilaufgabe im Aufgabenblatt: Bezug „Aufgabe …“, modus blatt; breit als Dialog', (tester) async {
    await starten(tester, const SizedBox(), groesse: const Size(1024, 768));
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      return Scaffold(
          body: Center(
              child: TextButton(
                  onPressed: () =>
                      oeffneMelden(c, frageId: teil.id, bezug: 'Aufgabe 1 a)', kontext: const {'modus': 'scrBlatt'}),
                  child: const Text('los'))));
    })));
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getSize(find.byType(MeldenDialog)).width, lessThanOrEqualTo(480));
    expect(find.textContaining('Aufgabe 1 a) · '), findsOneWidget);
    await tippe(tester, find.text('Sonstiges'));
    await tippe(tester, find.widgetWithText(FilledButton, 'Meldung senden'));
    final k = gesendet.single['p_kontext'] as Map<String, dynamic>;
    expect(k['modus'], 'blatt');
    expect(k['auszug'], MeldenDienst.auszug(teil.q));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  test('Kontext: Web-Namen umsetzen, Längen kürzen, Größe begrenzen', () async {
    SharedPreferences.setMockInitialValues({});
    await DataService.instance.load();
    final k = MeldenDienst.kontextFuer('X-unbekannt',
        extra: {'modus': 'scrQuiz', 'bereich': 'B' * 120, 'riesig': 'x' * 3000}, bezug: 'A' * 400);
    expect(k['modus'], 'quiz');
    expect((k['bereich'] as String).length, 80);
    expect((k['auszug'] as String).length, 160);
    expect(k.containsKey('riesig'), isFalse, reason: 'Kontext höchstens ~2 kB');
  });

  test('Gemeldete Fragen aus kvm_gemeldet laden', () async {
    SharedPreferences.setMockInitialValues({
      'kvm_gemeldet': jsonEncode({'B-VW-001': 1700000000000})
    });
    await dienst.laden();
    expect(dienst.istGemeldet('B-VW-001'), isTrue);
    expect(dienst.istGemeldet('B-VW-002'), isFalse);
    expect(MeldenDienst.istBremse(Exception('zu viele Meldungen')), isTrue);
  });
}
