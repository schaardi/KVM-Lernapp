// Screenshots des Pakets „Lernen“ (Plan in der Heute-Karte, Lern-Erinnerung,
// Quiz, Mündlich üben) – zum Prüfen von Layout und Dunkelmodus ohne Gerät
// (nicht Teil der normalen Test-Suite):
//   flutter test --update-goldens tool/screenshots/lernen_shots_test.dart
// Schreibt PNGs nach tool/screenshots/goldens/ (nicht eingecheckt).
// Die Helfer stammen aus shots_test.dart.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/lernen/datum.dart';
import 'package:kvm_trainer/lernen/muendlich_logik.dart';
import 'package:kvm_trainer/lernen/termin_formular.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/screens/muendlich_screen.dart';
import 'package:kvm_trainer/screens/pages/start_seite.dart';
import 'package:kvm_trainer/screens/quiz_screen.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/round_builder.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';
import 'package:kvm_trainer/widgets/calculator.dart';

Future<void> _schriften() async {
  Future<void> lade(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await l.load();
  }

  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$root/bin/cache/artifacts/material_fonts';
  await lade('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await lade('BarlowCondensed', ['assets/fonts/BarlowCondensed-SemiBold.ttf', 'assets/fonts/BarlowCondensed-Bold.ttf']);
  await lade('IBMPlexMono', ['assets/fonts/IBMPlexMono-Medium.ttf', 'assets/fonts/IBMPlexMono-SemiBold.ttf']);
  await lade('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
  await lade('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf']);
}

/// Realistischer Lernstand: 600 gesehen, 400 gemeistert, Lerntage, eine
/// Prüfung – dazu optional ein Prüfungstermin in [terminInTagen] Tagen.
Map<String, Object> _stand({int? terminInTagen, bool erinnerung = false}) {
  final qs = (json.decode(File('assets/data/questions.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final heute = (DateTime.now().millisecondsSinceEpoch + DateTime.now().timeZoneOffset.inMilliseconds) ~/ 86400000;
  final heuteUtc = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
  final prog = <String, dynamic>{};
  var i = 0;
  for (final q in qs) {
    if (i >= 600) break;
    final gemeistert = i % 3 != 2;
    prog[q['id'] as String] = {
      's': gemeistert ? 4 : 1,
      'c': gemeistert ? 4 : 0,
      'w': gemeistert ? 0 : 1,
      'b': gemeistert ? 3 : 0,
      'l': gemeistert ? 1 : 0,
      'd': gemeistert ? heuteUtc + 5 : heuteUtc - 1,
    };
    i++;
  }
  final tage = <String, int>{};
  for (final (d, n) in [(0, 18), (1, 40), (2, 22), (4, 55), (5, 12), (7, 30), (9, 8)]) {
    tage['${heute - d}'] = n;
  }
  return {
    'kvm_progress_v1': json.encode(prog),
    'kvm_tage': json.encode(tage),
    'kvm_letzte_pruefung': json.encode({'id': 'P-NT-20150429', 'nr': 2}),
    'kvm_open_answers': json.encode({'P-NT-20150429-s0': 'Antwort', 'P-NT-20150429-s1': 'Antwort'}),
    'kvm_open_points': json.encode({'P-NT-20150429-s0': 4, 'P-NT-20150429-s1': 6}),
    if (terminInTagen != null) 'kvm_pruefung': json.encode({'datum': isoVon(heute + terminInTagen)}),
    if (erinnerung) 'kvm_erinnerung': json.encode({'an': true, 'zeit': '07:30'}),
  };
}

Future<void> _app(WidgetTester tester, Size groesse,
    {bool dunkel = false, double dpr = 2, int? termin, bool erinnerung = false}) async {
  debugDisableShadows = false;
  tester.view.physicalSize = groesse * dpr;
  tester.view.devicePixelRatio = dpr;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(_stand(terminInTagen: termin, erinnerung: erinnerung));
  await tester.runAsync(() async {
    await _schriften();
    await DataService.instance.load();
    await ThemeController.instance.load();
  });
  ThemeController.instance.set(dunkel ? ThemeMode.dark : ThemeMode.light);
  AppState.instance.seite = AppSeite.start;
  AppState.instance.fach = 2;
  AppState.instance.sub = '*';
  await tester.pumpWidget(const KvmApp());
  for (var k = 0; k < 30; k++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  AppState.instance.vergleichVerfuegbar.value = true;
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _foto(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

Future<void> _seite(WidgetTester tester, AppSeite s) async {
  AppState.instance.geheZu(s);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Wie weit ließe sich die Startseite scrollen? 0 = passt ohne Scrollen.
double _startUeberhang(WidgetTester tester) {
  final s = tester.state<ScrollableState>(
      find.descendant(of: find.byType(StartSeite), matching: find.byType(Scrollable)).first);
  return s.position.maxScrollExtent;
}

/// Nach einem push: ein Frame für die Hero-Messung, dann die Überblendung.
Future<void> _neueSeite(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Antippen, auch wenn der Knopf erst ins Bild gescrollt werden muss.
Future<void> _tippe(WidgetTester tester, String text) async {
  // Die Liste baut nur, was im Bild ist – notfalls weiterscrollen.
  for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pump();
  }
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await tester.pump(const Duration(milliseconds: 300));
}

NavigatorState _nav(WidgetTester tester) => tester.state<NavigatorState>(find.byType(Navigator).first);

Question _frage(String id) => DataService.instance.questions.firstWhere((q) => q.id == id);

class _Attrappe implements MuendlichSprache {
  void Function(String text, bool endgueltig)? onText;
  void Function()? onEnde;
  @override
  bool get erkennung => true;
  @override
  bool get vorlesen => true;
  @override
  Future<void> sprechen(String text) async {}
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
    return true;
  }

  @override
  Future<void> diktatBeenden() async {}
}

void main() {
  const handy = Size(390, 844);
  const handyKurz = Size(390, 760);
  const klein = Size(375, 667);
  const desktop = Size(1280, 800);

  for (final dunkel in [false, true]) {
    final m = dunkel ? 'dunkel' : 'hell';
    testWidgets('Start mit Lernplan $m', (tester) async {
      await _app(tester, handy, dunkel: dunkel, termin: 42);
      await _foto(tester, 'lernen_start_plan_$m');
      debugDisableShadows = true;
    });
  }

  testWidgets('Start ohne Termin (Link)', (tester) async {
    await _app(tester, handy);
    await _foto(tester, 'lernen_start_ohne_termin');
    debugDisableShadows = true;
  });

  for (final (name, groesse) in [
    ('390x760', handyKurz),
    ('375x667', klein),
    ('360x740', const Size(360, 740)),
    ('412x732', const Size(412, 732)),
    ('320x640', const Size(320, 640)),
  ]) {
    testWidgets('Start mit Plan passt auf $name', (tester) async {
      await _app(tester, groesse, termin: 42);
      // ignore: avoid_print
      print('Überhang $name mit Plan: ${_startUeberhang(tester)}');
      await _foto(tester, 'lernen_start_plan_$name');
      debugDisableShadows = true;
    });
  }

  testWidgets('320x640 ohne Termin (Vergleich)', (tester) async {
    await _app(tester, const Size(320, 640));
    // ignore: avoid_print
    print('Überhang 320x640 ohne Termin: ${_startUeberhang(tester)}');
    debugDisableShadows = true;
  });

  for (final (name, tage) in [('morgen', 1), ('heute', 0), ('vorbei', -3)]) {
    testWidgets('Plan $name', (tester) async {
      await _app(tester, handy, termin: tage);
      await _foto(tester, 'lernen_plan_$name');
      debugDisableShadows = true;
    });
  }

  testWidgets('Desktop mit und ohne Termin', (tester) async {
    await _app(tester, desktop, dpr: 1.25, termin: 42);
    await _foto(tester, 'lernen_desktop_plan');
    debugDisableShadows = true;
  });

  testWidgets('Desktop ohne Termin', (tester) async {
    await _app(tester, desktop, dpr: 1.25);
    await _foto(tester, 'lernen_desktop_ohne');
    debugDisableShadows = true;
  });

  testWidgets('Termin-Formular', (tester) async {
    await _app(tester, handy, termin: 42);
    terminBearbeiten(tester.element(find.byType(StartSeite)));
    await tester.pump(const Duration(milliseconds: 600));
    await _foto(tester, 'lernen_termin_formular');
    debugDisableShadows = true;
  });

  for (final dunkel in [false, true]) {
    final m = dunkel ? 'dunkel' : 'hell';
    testWidgets('Konto mit Erinnerung $m', (tester) async {
      await _app(tester, handy, dunkel: dunkel, erinnerung: true);
      await _seite(tester, AppSeite.konto);
      await _foto(tester, 'lernen_konto_$m');
      debugDisableShadows = true;
    });
  }

  testWidgets('Konto: Uhrzeit wählen', (tester) async {
    await _app(tester, handy, erinnerung: true);
    await _seite(tester, AppSeite.konto);
    await _tippe(tester, '07:30');
    await tester.pump(const Duration(milliseconds: 400));
    await _foto(tester, 'lernen_konto_uhrzeit');
    debugDisableShadows = true;
  });

  testWidgets('Quiz: Fallaufgabe mit Ausgangssituation', (tester) async {
    await _app(tester, handy);
    final fall = DataService.instance.cases.firstWhere((c) => !c.id.startsWith('P-') && c.steps.first.type == 'mc');
    _nav(tester).push(MaterialPageRoute(
        builder: (_) => QuizScreen(mode: RoundMode.cases, pool: fall.asPool(), fach: fall.f, sub: '*')));
    await _neueSeite(tester);
    await _foto(tester, 'lernen_quiz_fall_1');
    await _tippe(tester, fall.steps.first.o.first.t);
    await _tippe(tester, 'Antwort prüfen');
    await _tippe(tester, 'Weiter');
    await tester.drag(find.byType(ListView).last, const Offset(0, 1000));
    await tester.pump(const Duration(milliseconds: 300));
    await _foto(tester, 'lernen_quiz_fall_2');
    debugDisableShadows = true;
  });

  for (final dunkel in [false, true]) {
    final m = dunkel ? 'dunkel' : 'hell';
    testWidgets('Quiz $m', (tester) async {
      await _app(tester, handy, dunkel: dunkel);
      final pool = [_frage('B-VW-001'), _frage('B-KR-901'), _frage('B-VW-033')];
      _nav(tester).push(MaterialPageRoute(builder: (_) => QuizScreen(mode: RoundMode.train, pool: pool, fach: 2, sub: '*')));
      await _neueSeite(tester);
      // Auswahlfrage: falsche Option mit Begründung wählen und prüfen
      await _tippe(tester, 'Rohstoffe, Arbeit und Kapital');
      await _foto(tester, 'lernen_quiz_1_gewaehlt_$m');
      await _tippe(tester, 'Antwort prüfen');
      await _foto(tester, 'lernen_quiz_2_falsch_$m');
      await _tippe(tester, 'Weiter');
      // Rechenaufgabe: im angedockten Rechner rechnen und übernehmen
      await tester.tap(find.text('Rechner'));
      await tester.pumpAndSettle();
      for (final k in '1 5 0 0 × 2 ='.split(' ')) {
        await tester.tap(find.descendant(of: find.byType(CalculatorSheet), matching: find.text(k)).last);
        await tester.pump();
      }
      await _foto(tester, 'lernen_quiz_3_rechner_$m');
      await tester.tap(find.text('Übernehmen ins Ergebnisfeld'));
      await tester.pump();
      await _foto(tester, 'lernen_quiz_3_rechnen_$m');
      await tester.tap(find.byTooltip('Schließen'));
      await tester.pumpAndSettle();
      await _tippe(tester, 'Antwort prüfen');
      await _foto(tester, 'lernen_quiz_4_richtig_$m');
      await _tippe(tester, 'Weiter');
      await _foto(tester, 'lernen_quiz_5_offen_$m');
      debugDisableShadows = true;
    });
  }

  for (final dunkel in [false, true]) {
    final m = dunkel ? 'dunkel' : 'hell';
    testWidgets('Mündlich $m', (tester) async {
      await _app(tester, handy, dunkel: dunkel);
      final sprache = _Attrappe();
      final pool = [
        _frage('B-VW-001'),
        _frage('B-VW-033'),
        ...muendlichKandidaten(2, 'Volkswirtschaft').where((q) => q.id != 'B-VW-001' && q.id != 'B-VW-033').take(1),
      ];
      _nav(tester).push(MaterialPageRoute(
          builder: (_) => MuendlichScreen(pool: pool, fach: 2, sub: 'Volkswirtschaft', sprache: sprache)));
      await _neueSeite(tester);
      await _foto(tester, 'lernen_muendlich_1_frage_$m');
      await _tippe(tester, 'Antworten');
      // erste Aufnahme: Zwischenstand, dann endgültig – die Sitzung endet
      sprache.onText!('Die Produktionsfaktoren sind', false);
      await tester.pump();
      sprache.onText!('Die Produktionsfaktoren sind Boden', true);
      sprache.onEnde!();
      await tester.pump();
      // „Weiter sprechen“ hängt an; der Zwischenstand steht kursiv dahinter
      await _tippe(tester, 'Weiter sprechen');
      sprache.onText!('und Arbeit', false);
      await tester.pump(const Duration(milliseconds: 250));
      await _foto(tester, 'lernen_muendlich_2_hoeren_$m');
      sprache.onText!('und Arbeit', true);
      sprache.onEnde!();
      await tester.pump();
      await _foto(tester, 'lernen_muendlich_3_gehoert_$m');
      await _tippe(tester, 'Lösung zeigen');
      await _foto(tester, 'lernen_muendlich_4_loesung_$m');
      for (final wert in ['Gewusst', 'Teilweise']) {
        await _tippe(tester, wert);
        await _tippe(tester, 'Ohne Mikrofon');
        await _tippe(tester, 'Lösung zeigen');
      }
      await _tippe(tester, 'Nicht gewusst');
      await _foto(tester, 'lernen_muendlich_5_ergebnis_$m');
      // Lernstand: heute drei Antworten mehr (Gewusst, Teilweise, Nicht gewusst)
      expect(LerntageService.instance.anTag(LerntageService.heute()), 18 + 3);
      debugDisableShadows = true;
    });
  }
}
