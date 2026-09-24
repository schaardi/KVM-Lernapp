import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/constants.dart';
import 'package:kvm_trainer/main.dart' show themaFuer;
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/werkzeuge/rechner_modell.dart';
import 'package:kvm_trainer/widgets/calculator.dart';
import 'package:kvm_trainer/widgets/drawing_pad.dart';
import 'package:kvm_trainer/widgets/werkzeug_dock.dart';

/// Werkzeug-Dock (FR-002 C), Taschenrechner-Oberfläche (FR-005 C–E),
/// Formelbuch-Vorlage (FR-002 C.4) und Rechenblatt.
void main() {
  final uebernommen = <String>[];

  Future<void> starten(WidgetTester tester, {Size groesse = const Size(390, 844), Widget? home}) async {
    tester.view.physicalSize = groesse * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await DataService.instance.load();
      await RechnerModell.instance.laden();
    });
    RechnerModell.instance.zuruecksetzen();
    rechnerZiel.value = null;
    uebernommen.clear();
    await tester.pumpWidget(MaterialApp(
      key: UniqueKey(),
      theme: themaFuer(KvmPalette.light),
      home: home ??
          Scaffold(
            appBar: AppBar(title: const Text('Probe')),
            body: ListView(children: const [Text('Aufgabe'), SizedBox(height: 900), Text('Ende')]),
            bottomNavigationBar: WerkzeugDock(onUebernehmen: uebernommen.add, onSprache: () {}),
          ),
    ));
    await tester.pump();
  }

  Future<void> tasten(WidgetTester tester, String folge) async {
    for (final k in folge.split(' ')) {
      // Die Tasten stehen im Baum hinter der Anzeige – .last trifft die Taste,
      // auch wenn die Anzeige gerade dieselbe Zahl zeigt.
      await tester.tap(find.descendant(of: find.byType(CalculatorSheet), matching: find.text(k)).last);
      await tester.pump();
    }
  }

  testWidgets('Dock: Rechner · Blatt · Formeln · Sprache; ohne onSprache drei', (tester) async {
    await starten(tester);
    for (final t in ['Rechner', 'Blatt', 'Formeln', 'Sprache']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.pumpWidget(MaterialApp(
      key: UniqueKey(),
      home: Scaffold(body: const SizedBox(), bottomNavigationBar: WerkzeugDock(onUebernehmen: uebernommen.add)),
    ));
    expect(find.text('Sprache'), findsNothing);
    expect(find.text('Rechner'), findsOneWidget);
  });

  testWidgets('Handy: Rechner dockt unten an, Seite bleibt darüber, Übernehmen setzt „1234,5“', (tester) async {
    await starten(tester);
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsOneWidget);
    expect(find.text('Blatt'), findsNothing, reason: 'der Rechner liegt über der Leiste');
    // Die Seite wird niedriger – nichts verschwindet hinter dem Rechner.
    final seite = tester.getRect(find.byType(ListView).first);
    final rechner = tester.getRect(find.byType(CalculatorSheet));
    expect(seite.bottom, lessThanOrEqualTo(rechner.top + 1));
    expect(rechner.height / 844, inInclusiveRange(0.45, 0.66));

    expect(find.textContaining('Übernehmen'), findsNothing, reason: 'erst mit gültigem Ergebnis');
    await tasten(tester, '1 2 3 4 5 ÷ 1 0 =');
    expect(find.text('1.234,5'), findsOneWidget);
    expect(find.text('12.345 ÷ 10 ='), findsOneWidget);
    await tester.tap(find.textContaining('Übernehmen'));
    await tester.pump();
    expect(uebernommen, ['1234,5']);

    rechnerZiel.value = 'ins Ergebnisfeld';
    await tester.pump();
    expect(find.text('Übernehmen ins Ergebnisfeld'), findsOneWidget);

    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsNothing);
    expect(find.text('Blatt'), findsOneWidget);
  });

  testWidgets('Einklappen blendet die Tasten aus, Antippen der Anzeige klappt auf', (tester) async {
    await starten(tester);
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tasten einklappen'));
    await tester.pump();
    expect(find.text('7'), findsNothing);
    expect(RechnerModell.instance.mini, isTrue);
    await tester.tap(find.text('0').first);
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('Verlauf: Antippen setzt das Ergebnis ein, „Verlauf leeren“', (tester) async {
    await starten(tester);
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    await tasten(tester, '2 0 0 + 1 9 % =');
    await tasten(tester, 'C');
    expect(find.text('Verlauf leeren'), findsOneWidget);
    await tester.tap(find.text('= 238'));
    await tester.pump();
    expect(RechnerModell.instance.ergebnisText, '238');
    await tester.tap(find.text('Verlauf leeren'));
    await tester.pump();
    expect(find.text('Verlauf leeren'), findsNothing);
  });

  testWidgets('Fehler steht statt des Ergebnisses', (tester) async {
    await starten(tester);
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    await tasten(tester, '5 + =');
    expect(find.text('Rechnung unvollständig'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Breit: schwebendes Fenster oben rechts, Leiste bleibt, Fenster ziehbar', (tester) async {
    await starten(tester, groesse: const Size(1024, 768));
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsOneWidget);
    expect(find.text('Formeln'), findsOneWidget);
    final vorher = tester.getRect(find.byType(CalculatorSheet));
    expect(vorher.width, closeTo(324, 2.5), reason: '324 samt Rahmen');
    expect(vorher.right, closeTo(1024 - 16, 1));
    expect(rechnerAusweichen.value, 0, reason: 'erst ab 1100 dp');
    await tester.drag(find.text('TASCHENRECHNER'), const Offset(-300, 40));
    await tester.pump();
    final nachher = tester.getRect(find.byType(CalculatorSheet));
    expect(nachher.left, closeTo(vorher.left - 300, 2));
    // Rechner-Taste schließt wieder.
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsNothing);
  });

  testWidgets('Sehr breit: Inhalt soll nach links ausweichen, bis das Fenster verschoben wird', (tester) async {
    await starten(tester, groesse: const Size(1280, 800));
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    expect(rechnerAusweichen.value, 364);
    await tester.drag(find.text('TASCHENRECHNER'), const Offset(-100, 0));
    await tester.pump();
    expect(rechnerAusweichen.value, 0);
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
  });

  testWidgets('oeffneRechner: im Dock der Route, sonst als Blatt; Future endet beim Schließen', (tester) async {
    late BuildContext innen;
    await starten(
      tester,
      home: Scaffold(
        body: Builder(builder: (c) {
          innen = c;
          return const SizedBox.expand();
        }),
        bottomNavigationBar: WerkzeugDock(onUebernehmen: uebernommen.add),
      ),
    );
    var fertig = false;
    oeffneRechner(innen).then((_) => fertig = true);
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsOneWidget);
    expect(find.text('Rechner'), findsNothing, reason: 'angedockt statt der Leiste');
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(fertig, isTrue);

    // Ohne Dock: Blatt, das die Seite nicht sperrt.
    late BuildContext ohne;
    await tester.pumpWidget(MaterialApp(
      key: UniqueKey(),
      home: Scaffold(body: Builder(builder: (c) {
        ohne = c;
        return const SizedBox.expand();
      })),
    ));
    fertig = false;
    oeffneRechner(ohne, onUebernehmen: uebernommen.add).then((_) => fertig = true);
    await tester.pumpAndSettle();
    expect(find.text('TASCHENRECHNER'), findsOneWidget);
    await tasten(tester, '4 4 0 0 ÷ 2 2 =');
    await tester.tap(find.textContaining('Übernehmen'));
    expect(uebernommen.last, '200');
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(fertig, isTrue);
    expect(find.text('TASCHENRECHNER'), findsNothing);
  });

  testWidgets('Hardware-Tastatur tippt, aber nicht, solange ein Textfeld den Fokus hat', (tester) async {
    await starten(
      tester,
      home: Scaffold(
        body: const Padding(padding: EdgeInsets.all(20), child: TextField()),
        bottomNavigationBar: WerkzeugDock(onUebernehmen: uebernommen.add),
      ),
    );
    await tester.tap(find.text('Rechner'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(RechnerModell.instance.ergebnisText, '15');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(RechnerModell.instance.ergebnisText, '0');

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '99');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    expect(RechnerModell.instance.ergebnisText, '0', reason: 'Textfeld hat Vorrang');
  });

  testWidgets('Als Blatt in 460 Höhe (bisheriger Einbau) ohne Überlauf', (tester) async {
    await starten(
      tester,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(height: 460, child: CalculatorSheet(onUebernehmen: uebernommen.add)),
        ),
      ),
    );
    RechnerModell.instance.tasten('1 0 zeit − 6 zeit 4 5 = 2 π = 5 + 3'.split(' '));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('8'), findsWidgets);
    expect(find.textContaining('Übernehmen'), findsOneWidget);
  });

  testWidgets('Formelbuch: Vorlage ins Antwortfeld – mit Ziel, mit Namen, sonst Zwischenablage', (tester) async {
    await starten(tester, groesse: const Size(360, 740));
    await tester.tap(find.text('Formeln'));
    await tester.pumpAndSettle();
    expect(find.text('FORMELBUCH'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'kein Überlauf auf 360 dp');
    final knopf = find.text('Vorlage ins Antwortfeld').first;
    await tester.ensureVisible(knopf);
    await tester.pumpAndSettle();
    await tester.tap(knopf);
    await tester.pump();
    expect(uebernommen.single, startsWith('Zuschlagskalkulation (Industrie)\nMaterialeinzelkosten: '));
    expect(uebernommen.single, isNot(contains('­')), reason: 'Vorlagen ohne weiche Trennstellen');
    expect(find.text('Als Vorlage in deine Antwort übernommen – dort ausfüllen.'), findsOneWidget);

    // Callback mit Rückgabe: das Formelbuch nennt das Ziel.
    String? ziel(String text) {
      uebernommen.add(text);
      return 'Aufgabe 1 a)';
    }

    late BuildContext c;
    await tester.pumpWidget(MaterialApp(
        key: UniqueKey(),
        home: Scaffold(body: Builder(builder: (b) {
          c = b;
          return const SizedBox.expand();
        }))));
    oeffneFormelbuchBlatt(c, onUebernehmen: ziel);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Vorlage ins Antwortfeld').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vorlage ins Antwortfeld').first);
    await tester.pump();
    expect(find.text('Als Vorlage in die Antwort zu Aufgabe 1 a) übernommen – dort ausfüllen.'), findsOneWidget);

    // Ohne Ziel (Startseite): Zwischenablage.
    String? ablage;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') ablage = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    Navigator.of(c).pop();
    await tester.pumpAndSettle();
    oeffneFormelbuchBlatt(c);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Vorlage ins Antwortfeld').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vorlage ins Antwortfeld').first);
    await tester.pump();
    expect(ablage, startsWith('Zuschlagskalkulation (Industrie)'));
    expect(find.text('Keine Prüfung offen – die Vorlage liegt jetzt in der Zwischenablage.'), findsOneWidget);
  });

  testWidgets('Rechenblatt: Striche bleiben beim Schließen erhalten, „Leeren“ löscht', (tester) async {
    await starten(tester, groesse: const Size(360, 740));
    await tester.tap(find.text('Blatt'));
    await tester.pumpAndSettle();
    expect(find.text('RECHENBLATT'), findsOneWidget);
    final vorher = DrawingPad.anzahlStriche;
    final mitte = tester.getCenter(find.byType(DrawingPad));
    final g = await tester.startGesture(mitte);
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, 12)); // senkrecht – das Blatt darf nicht mitgehen
    }
    await g.up();
    await tester.pump();
    expect(DrawingPad.anzahlStriche, vorher + 1);
    expect(find.text('RECHENBLATT'), findsOneWidget);

    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blatt'));
    await tester.pumpAndSettle();
    expect(DrawingPad.anzahlStriche, vorher + 1, reason: 'solange die App offen ist');
    await tester.ensureVisible(find.text('Leeren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leeren'));
    await tester.pump();
    expect(DrawingPad.anzahlStriche, 0);
  });
}
