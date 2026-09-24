import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/constants.dart';
import 'package:kvm_trainer/features/gefahrgut.dart';
import 'package:kvm_trainer/main.dart' show themaFuer;
import 'package:kvm_trainer/screens/gefahrgut_screen.dart';
import 'package:kvm_trainer/werkzeuge/adr_daten.dart';
import 'package:kvm_trainer/werkzeuge/gefahrzettel.dart';

/// Gefahrgut (ADR): Kemler-Decoder, Übersicht, Quiz, Warntafel.
void main() {
  List<String> deute(String k) => kemlerDeuten(k).map(zeilenText).toList();

  group('Kemler-Decoder (Web decodeKemler)', () {
    test('Verdoppelung verstärkt die Gefahr', () {
      expect(deute('33'), [
        '33 = Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen – Verdoppelung = Verstärkung der Gefahr',
      ]);
    });

    test('„0“ an zweiter Stelle: keine weitere Gefahr', () {
      expect(deute('30'), [
        '3 (Hauptgefahr) = Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen',
        '0 = keine weitere Gefahr',
      ]);
      expect(deute('80'), ['8 (Hauptgefahr) = Ätzwirkung', '0 = keine weitere Gefahr']);
      expect(deute('90'), ['9 (Hauptgefahr) = Gefahr einer spontanen heftigen Reaktion', '0 = keine weitere Gefahr']);
    });

    test('Mehrere Ziffern, Hauptgefahr zuerst', () {
      expect(deute('23'), [
        '2 (Hauptgefahr) = Entweichen von Gas durch Druck oder chemische Reaktion',
        '3 = Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen',
      ]);
      expect(deute('268'), [
        '2 (Hauptgefahr) = Entweichen von Gas durch Druck oder chemische Reaktion',
        '6 = Giftigkeit oder Ansteckungsgefahr',
        '8 = Ätzwirkung',
      ]);
      // Die „0“ in der Mitte einer dreistelligen Zahl wird nicht erklärt.
      expect(deute('606'), [
        '6 (Hauptgefahr) = Giftigkeit oder Ansteckungsgefahr',
        '6 = Giftigkeit oder Ansteckungsgefahr',
      ]);
    });

    test('Vorangestelltes X: reagiert gefährlich mit Wasser', () {
      expect(deute('X423'), [
        'X = der Stoff reagiert gefährlich mit Wasser',
        '4 (Hauptgefahr) = Entzündbarkeit fester Stoffe',
        '2 = Entweichen von Gas durch Druck oder chemische Reaktion',
        '3 = Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen',
      ]);
      expect(deute('X88').first, 'X = der Stoff reagiert gefährlich mit Wasser');
      expect(deute('X88')[1], '88 = Ätzwirkung – Verdoppelung = Verstärkung der Gefahr');
    });

    test('Verdoppelung mit weiterer Ziffer, fette Stellen', () {
      expect(deute('336'), [
        '33 = Entzündbarkeit von flüssigen Stoffen (Dämpfen) und Gasen – Verdoppelung = Verstärkung der Gefahr',
        '6 = Giftigkeit oder Ansteckungsgefahr',
      ]);
      final z = kemlerDeuten('336').first;
      expect(z.where((t) => t.fett).map((t) => t.text), ['33', 'Verdoppelung = Verstärkung der Gefahr']);
      expect(kemlerDeuten(''), isEmpty);
    });

    test('Daten wie im Web', () {
      expect(kAdrKlassen, hasLength(15));
      expect(kAdrKlassen.map((k) => k.klasse).toList(),
          ['1', '2.1', '2.2', '2.3', '3', '4.1', '4.2', '4.3', '5.1', '5.2', '6.1', '6.2', '7', '8', '9']);
      expect(kAdrBeispiele, hasLength(8));
      expect(kAdrBeispiele.first.stoff, 'Benzin (Ottokraftstoff)');
    });
  });

  Future<void> zeige(WidgetTester tester, Widget kind, {bool dunkel = false}) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    KvmPalette.current = dunkel ? KvmPalette.dark : KvmPalette.light;
    addTearDown(() => KvmPalette.current = KvmPalette.light);
    await tester.pumpWidget(MaterialApp(theme: themaFuer(KvmPalette.current), home: kind));
    await tester.pumpAndSettle();
  }

  testWidgets('oeffneGefahrgut öffnet die Übersicht mit allen Gefahrzetteln', (tester) async {
    await zeige(
      tester,
      Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => oeffneGefahrgut(c), child: const Text('ADR')))),
    );
    await tester.tap(find.text('ADR'));
    await tester.pumpAndSettle();
    expect(find.text('Gefahrgut-Symbole (ADR)'), findsOneWidget);
    for (final t in ['Übersicht', 'Quiz', 'Warntafel']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('Klasse 1'), findsOneWidget);
    expect(find.text('Explosive Stoffe und Gegenstände'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Klasse 9'), 300,
        scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
    expect(find.text('Verschiedene gefährliche Stoffe und Gegenstände'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Placard, mind. 25 × 25 cm'), 300,
        scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
    expect(find.textContaining('Placard, mind. 25 × 25 cm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quiz: Antwort wertet, markiert richtig/falsch, „Nächste“, Stand bleibt beim Reiterwechsel',
      (tester) async {
    await zeige(tester, GefahrgutScreen(zufall: math.Random(7), reiter: 1));
    expect(find.text('Welche Gefahrgutklasse zeigt dieser Gefahrzettel?'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    final zettel = tester.widget<Gefahrzettel>(find.byType(Gefahrzettel));
    final optionen = find.textContaining(RegExp(r'^Klasse .+ – '));
    expect(optionen, findsNWidgets(4));

    // Eine falsche Antwort wählen.
    final falsch = find.textContaining(RegExp(r'^Klasse .+ – ')).evaluate().map((e) => (e.widget as Text).data!).firstWhere(
        (t) => !t.endsWith(zettel.klasse.name));
    await tester.tap(find.text(falsch));
    await tester.pump();
    expect(find.text('0 / 1'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'die richtige wird gezeigt');
    await tester.tap(find.text('Klasse ${zettel.klasse.klasse} – ${zettel.klasse.name}'));
    await tester.pump();
    expect(find.text('0 / 1'), findsOneWidget, reason: 'nach der Antwort gesperrt');

    await tester.tap(find.text('Nächste'));
    await tester.pump();
    final neu = tester.widget<Gefahrzettel>(find.byType(Gefahrzettel)).klasse;
    await tester.tap(find.text('Klasse ${neu.klasse} – ${neu.name}'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.text('Warntafel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('Warntafel: Benzin 33/1203, Wechsel auf Natrium X423/1428', (tester) async {
    await zeige(tester, const GefahrgutScreen(reiter: 2), dunkel: true);
    expect(find.byType(Warntafel), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    expect(find.text('1203'), findsOneWidget);
    expect(find.textContaining('Verdoppelung = Verstärkung der Gefahr'), findsOneWidget);
    expect(find.text('Vorangestelltes X: Stoff reagiert gefährlich mit Wasser'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Natrium  (X423 / 1428)').last);
    await tester.pumpAndSettle();
    expect(find.text('X423'), findsOneWidget);
    expect(find.text('1428'), findsOneWidget);
    expect(find.textContaining('der Stoff reagiert gefährlich mit Wasser'), findsOneWidget);
    expect(find.textContaining('(Hauptgefahr) = Entzündbarkeit fester Stoffe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
