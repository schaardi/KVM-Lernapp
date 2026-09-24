import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/cloud/lernende_blatt.dart';
import 'package:kvm_trainer/cloud/vergleich_dienst.dart';
import 'package:kvm_trainer/cloud/werte.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/screens/pages/vergleich_seite.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/pruef_stat.dart';
import 'package:kvm_trainer/services/selection_service.dart';
import 'package:kvm_trainer/theme/palette.dart';
import 'cloud/test_server.dart';

/// Seite „Vergleich“ (FR-004, FR-010, FR-012, FR-014 7) mit der Test-Attrappe.

TestServer _server({bool dabei = true}) {
  final s = TestServer();
  s.andere.addAll([
    TestPerson('Cora', reife: 64, antworten: 312, serie: 5, pruefN: 3, pruefOk: 2, pruefSchnitt: 61, chance: 71),
    TestPerson('Bert', reife: 40, antworten: 120, serie: 2),
    TestPerson('Anna', reife: 81),
  ]);
  if (dabei) s.ich = TestPerson('Lkw_Profi', pid: 'pid-ich', reife: 50, antworten: 80, serie: 3);
  return s;
}

/// Nur im Dialog „Lernende“ suchen – die Seite dahinter zeigt dieselben Namen.
Finder _imBlatt(Finder f) => find.descendant(of: find.byType(LernendeBlatt), matching: f);

Future<void> _seite(WidgetTester tester, TestServer s, {bool laden = true}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final d = VergleichDienst.instance;
  d.testStart(s);
  await tester.pumpWidget(MaterialApp(
    theme: themaFuer(KvmPalette.light),
    home: const Scaffold(body: VergleichSeite()),
  ));
  if (laden) {
    await d.laden(erzwingen: true);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await DataService.instance.load();
    await SelectionService.instance.load();
    await ProgressService.instance.load();
    await LerntageService.instance.load();
  });

  setUp(() => pruefStatistik = () => PruefStatistik.leer);

  testWidgets('Vor dem Laden: „Rangliste wird geladen …“', (tester) async {
    await _seite(tester, _server(), laden: false);
    expect(find.text('VERGLEICH'), findsOneWidget);
    expect(find.text('Rangliste wird geladen …'), findsOneWidget);
  });

  testWidgets('Beitritt: Einführung, zu kurzer Name, dann Wochenrangliste mit eigener Zeile', (tester) async {
    final s = _server(dabei: false);
    await _seite(tester, s);
    expect(find.text('3 dabei'), findsOneWidget);
    expect(find.textContaining('Vergleiche dich mit anderen Lernenden'), findsOneWidget);
    expect(find.textContaining('finden und ihren Lernstand je Fach sehen'), findsOneWidget); // mit Profilen
    expect(find.textContaining('samt Profil und Freundschaften'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Mitmachen'));
    await tester.pumpAndSettle();
    expect(find.text(kTextNameRegel), findsOneWidget);
    expect(s.anzahl('rangliste_melden'), 0);

    await tester.enterText(find.byType(TextField), 'Lkw_Profi');
    await tester.tap(find.text('Mitmachen'));
    await tester.pumpAndSettle();
    expect(find.text('WOCHENRANGLISTE · ${kwText(VergleichDienst.instance.kw)}'), findsOneWidget);
    expect(find.text('Du bist dabei als Lkw_Profi'), findsOneWidget);
    expect(find.text('4 dabei'), findsOneWidget);
    expect(find.text('Cora'), findsOneWidget);
    // Kopfzeile, Reiter und Fuß
    expect(find.text('ANTW.'), findsOneWidget);
    expect(find.text('Alle'), findsOneWidget);
    expect(find.text('Freunde'), findsOneWidget);
    expect(find.text('+ Gruppe'), findsOneWidget);
    expect(find.text('Lernende & Freunde'), findsOneWidget);
    expect(find.text('Spitzname ändern'), findsOneWidget);
  });

  testWidgets('Kennzahlen: Reife-Vergleich und Platz der Woche', (tester) async {
    final s = _server();
    await _seite(tester, s);
    // 3 andere, 1 mit weniger Reife → 33 %
    expect(find.text('33 %'), findsOneWidget);
    expect(find.text('der anderen liegen bei der Prüfungsreife hinter dir'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
    expect(find.text('Platz diese Woche von 3 · 80 Antworten'), findsOneWidget);
    expect(find.text('Lkw_Profi · du'), findsOneWidget);
  });

  testWidgets('Allein und ohne Antworten: die Texte aus dem Web', (tester) async {
    final s = TestServer()..ich = TestPerson('Lkw_Profi', pid: 'pid-ich');
    await _seite(tester, s);
    expect(find.text('Noch bist du allein – lade andere ein, dann gibt es einen Vergleich.'), findsOneWidget);
    expect(find.text('Diese Woche noch ohne Antwort – ab der ersten bist du in der Wochenliste.'), findsOneWidget);
    expect(find.text('Diese Woche hat noch niemand geantwortet. Fang an!'), findsOneWidget);
  });

  testWidgets('Ohne Skripte für Gruppen und Profile: keine Reiter, kein „Lernende & Freunde“', (tester) async {
    final s = _server()..fehlt.addAll(['gruppen_meine', 'freunde_stand', 'rangliste_pruefungen']);
    await _seite(tester, s);
    expect(find.text('WOCHENRANGLISTE · ${kwText(VergleichDienst.instance.kw)}'), findsOneWidget);
    expect(find.text('+ Gruppe'), findsNothing);
    expect(find.text('Freunde'), findsNothing);
    expect(find.text('Lernende & Freunde'), findsNothing);
    expect(find.text('Prüfungen'), findsNothing);
  });

  testWidgets('Umschalter „Prüfungen“: Spalten Bestanden und Chance, Fußnote', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('Prüfungen'));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSRANGLISTE · BESTANDENE ORIGINAL-PRÜFUNGEN'), findsOneWidget);
    expect(find.text('BESTANDEN'), findsOneWidget);
    expect(find.text('CHANCE'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('71 %'), findsOneWidget);
    expect(find.text(kPruefFussnote), findsOneWidget);
    expect(find.text('Ab der ersten gewerteten Prüfung stehst du in der Prüfungsrangliste.'), findsOneWidget);
  });

  testWidgets('Prüfungsmodus in Gruppe und bei Freunden: bestanden, dann Schnitt', (tester) async {
    pruefStatistik = () => const PruefStatistik(n: 4, ok: 2, schnitt: 70);
    final s = _server();
    final p = {for (final x in s.andere) x.name: x};
    p['Bert']!
      ..pruefN = 4
      ..pruefOk = 3
      ..pruefSchnitt = 55;
    p['Anna']!
      ..pruefN = 2
      ..pruefOk = 2
      ..pruefSchnitt = 80;
    s.freunde.addAll(['pid-bert', 'pid-anna']);
    s.gruppen.add(TestGruppe('g1', 'K7M2QX', 'Kurs', [s.ich!, p['Cora']!, p['Bert']!, p['Anna']!]));
    await _seite(tester, s);
    await tester.tap(find.text('Prüfungen'));
    await tester.pumpAndSettle();

    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    await tester.tap(find.text('Kurs'));
    await tester.pumpAndSettle();
    expect(find.text('KURS · 4 MITGLIEDER · PRÜFUNGEN'), findsOneWidget);
    // Bert 3 bestanden; Cora, Anna und ich je 2 – dann Schnitt 80 (Anna), 70 (ich), 61 (Cora)
    expect(y('Bert'), lessThan(y('Anna')));
    expect(y('Anna'), lessThan(y('Lkw_Profi · du')));
    expect(y('Lkw_Profi · du'), lessThan(y('Cora')));

    await tester.tap(find.text('Freunde'));
    await tester.pumpAndSettle();
    expect(find.text('DU UND DEINE FREUNDE · PRÜFUNGEN'), findsOneWidget);
    expect(y('Bert'), lessThan(y('Anna')));
    expect(y('Anna'), lessThan(y('Lkw_Profi · du')));
    expect(find.text('Cora'), findsNothing); // keine Freundin
    expect(find.text('2/4'), findsOneWidget); // eigener Stand aus der lokalen Statistik
  });

  testWidgets('Freunde-Reiter: ohne Freunde „Lernende finden“, mit Freund sortiert', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('Freunde'));
    await tester.pumpAndSettle();
    expect(find.text('DU UND DEINE FREUNDE · ${kwText(VergleichDienst.instance.kw)}'), findsOneWidget);
    expect(find.text('Lernende finden'), findsOneWidget);

    s.freunde.add('pid-cora');
    await VergleichDienst.instance.waehleAnsicht('freunde');
    await tester.pumpAndSettle();
    expect(find.text('Lernende finden'), findsNothing);
    final cora = tester.getTopLeft(find.text('Cora'));
    final ich = tester.getTopLeft(find.text('Lkw_Profi · du'));
    expect(cora.dy, lessThan(ich.dy)); // 312 vor 80 Antworten
  });

  testWidgets('Gruppe: gründen über „+ Gruppe“, Code, Einladen kopiert, verlassen mit Rückfrage', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('+ Gruppe'));
    await tester.pumpAndSettle();
    expect(find.text('Mit Code beitreten'), findsOneWidget);
    expect(find.text('Neue Gruppe gründen'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'ab');
    await tester.tap(find.text('Gründen'));
    await tester.pumpAndSettle();
    expect(find.text('Der Gruppenname braucht 3–40 Zeichen.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, ' Meisterkurs Herbst 2026 ');
    await tester.tap(find.text('Gründen'));
    await tester.pumpAndSettle();
    expect(find.text('Meisterkurs Herbst 2026'), findsOneWidget); // Reiter
    expect(find.text('MEISTERKURS HERBST 2026 · 1 MITGLIED · ${kwText(VergleichDienst.instance.kw)}'), findsOneWidget);
    expect(find.text('Code K7M2QX'), findsOneWidget);
    expect(find.textContaining('Noch bist du allein in der Gruppe.'), findsOneWidget);

    String? kopiert;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') kopiert = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Einladen'));
    await tester.pumpAndSettle();
    expect(find.text('Einladung kopiert – einfach in euren Chat einfügen.'), findsOneWidget);
    expect(kopiert, startsWith('Lerngruppe „Meisterkurs Herbst 2026“ im Meister-Trainer – lern mit! Code: K7M2QX\n'));
    expect(kopiert, endsWith('#gruppe=K7M2QX'));

    await tester.tap(find.text('Gruppe verlassen'));
    await tester.pumpAndSettle();
    expect(find.text('Du kannst später mit dem Code wieder beitreten.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Gruppe verlassen'));
    await tester.pumpAndSettle();
    expect(find.text('Meisterkurs Herbst 2026'), findsNothing);
    expect(find.text('WOCHENRANGLISTE · ${kwText(VergleichDienst.instance.kw)}'), findsOneWidget);
    expect(s.gruppen, isEmpty);
  });

  testWidgets('Anfrage an mich: Band, „Ansehen“ öffnet „Lernende“, Annehmen', (tester) async {
    final s = _server()..anfragenAnMich.add('pid-cora');
    await _seite(tester, s);
    expect(find.text('Cora möchte mit dir befreundet sein.'), findsOneWidget);
    await tester.tap(find.text('Ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Lernende'), findsOneWidget);
    expect(find.text('ANFRAGEN AN DICH'), findsOneWidget);
    await tester.tap(find.text('Annehmen'));
    await tester.pumpAndSettle();
    expect(find.text('Ihr seid jetzt befreundet.'), findsOneWidget);
    expect(find.text('ANFRAGEN AN DICH'), findsNothing);
    expect(find.text('DEINE FREUNDE'), findsOneWidget);
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('Cora möchte mit dir befreundet sein.'), findsNothing);
  });

  testWidgets('Lernende: Suche, Anfrage senden, Profil mit Schloss', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('Lernende & Freunde'));
    await tester.pumpAndSettle();
    expect(find.text('3 Personen in der Rangliste · aktivste dieser Woche zuerst'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Spitzname suchen …'), 'ber');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('1 Person gefunden · aktivste dieser Woche zuerst'), findsOneWidget);
    await tester.tap(find.text('Anfragen'));
    await tester.pumpAndSettle();
    expect(find.text('Anfrage an Bert gesendet.'), findsOneWidget);
    expect(find.text('Angefragt'), findsOneWidget);

    await tester.tap(_imBlatt(find.text('Bert')));
    await tester.pumpAndSettle();
    expect(find.text('‹ Zurück'), findsOneWidget);
    expect(find.text('Den Lernstand je Fach zeigt Bert nur Freunden.'), findsOneWidget);
    expect(find.text('Deine Anfrage ist unterwegs.'), findsOneWidget);
    expect(find.text('Zurückziehen'), findsOneWidget);
    expect(_imBlatt(find.text('40 %')), findsOneWidget);
    await tester.tap(find.text('‹ Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Mein Profil'), findsOneWidget);
  });

  testWidgets('Profil mit Sichtbarkeit „alle“: Fächer, Aktivität, Prüfungen je Bereich', (tester) async {
    final s = _server();
    s.andere.first
      ..sichtbarkeit = 'alle'
      ..gemeistert = 420
      ..detailsAm = DateTime.now().toUtc()
      ..details = {
        'f': {
          '1': {'r': 64, 'm': 150, 'g': 200, 'n': 662},
          '5': {'r': 31, 'm': 90, 'g': 300, 'n': 940},
        },
        't14': [0, 3, 0, 12, 40, 0, 8, 22, 0, 0, 15, 30, 9, 18],
        'tage': 41,
        'echt': {'n': 2, 'best': 74},
        'pr': {
          'RE': {'n': 2, 'ok': 1, 's': 55, 'c': 64},
        },
        'pc': {'bq': null, 'hq': null, 'g': null},
      };
    await _seite(tester, s);
    await tester.tap(find.text('Cora'));
    await tester.pumpAndSettle();
    expect(find.text('dabei seit September 2026'), findsOneWidget);
    expect(find.text('Freundschaft anfragen'), findsOneWidget);
    expect(find.text('Fragen gemeistert'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Prüfungen bestanden'), findsOneWidget);
    await tester.dragUntilVisible(find.text('bestes Ergebnis dabei'), find.byType(ListView), const Offset(0, -200));
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
    expect(find.text('150 von 662 gemeistert · 200 gesehen'), findsOneWidget);
    expect(find.text('AKTIVITÄT · 14\u00A0TAGE'), findsOneWidget);
    expect(find.text('157 Antworten · 9 Tage'), findsOneWidget);
    expect(find.text('1 von 2 bestanden · Ø 55 P'), findsOneWidget);
    expect(find.text('Lerntage in 120 Tagen'), findsOneWidget);
    expect(find.text('74 %'), findsOneWidget);
  });

  testWidgets('Mein Profil: Sichtbarkeit umschalten', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('Lernende & Freunde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mein Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allen Lernenden'));
    await tester.pumpAndSettle();
    expect(find.text('Alle Lernenden sehen jetzt deinen Lernstand je Fach.'), findsOneWidget);
    expect(s.ich!.sichtbarkeit, 'alle');
    await tester.tap(find.text('Mein Profil ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Das bist du'), findsOneWidget);
    expect(find.textContaining('Lernstand für alle sichtbar'), findsOneWidget);
  });

  testWidgets('Spitzname ändern und Austreten mit Rückfrage', (tester) async {
    final s = _server();
    await _seite(tester, s);
    await tester.tap(find.text('Spitzname ändern'));
    await tester.pumpAndSettle();
    expect(find.text('Neuer Spitzname für die Rangliste:'), findsOneWidget);
    expect(find.text('Speichern'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Cora');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Dieser Spitzname ist schon vergeben.'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Austreten'));
    await tester.pumpAndSettle();
    expect(find.text('Aus der Rangliste austreten?'), findsOneWidget);
    expect(find.text('Dein Eintrag wird gelöscht – samt Profil und Freundschaften.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Austreten'));
    await tester.pumpAndSettle();
    expect(s.ich, isNull);
    expect(find.text('Mitmachen'), findsOneWidget);
  });
}
