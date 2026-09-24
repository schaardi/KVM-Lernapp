// Screenshots des Pakets „Prüfungen“ aus dem Widget-Test – Prüfungsliste,
// Aufgabenblatt mit Rechenweg und Skizze, Prüfungsbedingungen, Ergebnis und
// Bestehenschance, hell und dunkel (nicht Teil der normalen Test-Suite):
//   flutter test --update-goldens tool/screenshots/pruefungen_shots_test.dart
// Schreibt PNGs nach tool/screenshots/goldens/ (nicht eingecheckt).
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/pruefung/echt.dart';
import 'package:kvm_trainer/screens/aufgabenblatt_screen.dart';
import 'package:kvm_trainer/screens/result_screen.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/round_builder.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';

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

/// Stand mit Antworten, Rechenweg, Skizze und ausgewerteten Durchgängen.
Map<String, Object> _stand() {
  final jetzt = DateTime.now().millisecondsSinceEpoch;
  const tag = 86400000;
  Map<String, Object> d(String k, String id, int tageHer, int pkt, {bool echt = false}) => {
        'k': k,
        'id': id,
        't': jetzt - tageHer * tag,
        'g': jetzt - tageHer * tag,
        'pkt': pkt,
        'max': 100,
        'bew': 12,
        'teile': 12,
        'echt': echt ? 1 : 0,
        if (echt) 'dauer': 83 * 60000,
        if (echt) 'min': 90,
      };
  return {
    'kvm_letzte_pruefung': json.encode({'id': 'P-OK-20221115', 'nr': 3}),
    'kvm_open_answers': json.encode({
      'P-OK-20221115-s0': 'Antwort',
      'P-OK-20221115-s1': 'Antwort',
      'P-OK-20221115-s7': 'Zuerst die Wagenkilometer, dann die Kosten.',
    }),
    'kvm_open_points': json.encode({'P-OK-20221115-s0': 6, 'P-OK-20221115-s1': 4}),
    'kvm_open_calc': json.encode({
      'P-OK-20221115-s6': [
        {'l': 'Fahrzeit je Richtung', 'f': '10 · 60 ÷ 30', 'u': 'min'},
        {'l': 'Umlauf', 'f': '(20 + 6 + 4) · 2', 'u': 'min'},
        {'l': 'Fahrten', 'f': '520 ÷ 65', 'u': ''},
        {'l': 'Takt', 'f': '240 ÷ ', 'u': 'min'},
      ],
    }),
    'kvm_open_sketch': json.encode({
      'P-MI-20241106-s4': {
        'v': 1,
        'bg': 'karo',
        'fmt': 'hoch',
        'els': [
          {'t': 'o', 'c': 'k', 's': 3, 'x': 375, 'y': 75, 'w': 250, 'h': 100, 'txt': 'Beginn'},
          {'t': 'a', 'c': 'k', 's': 3, 'x1': 500, 'y1': 175, 'x2': 500, 'y2': 275},
          {'t': 'r', 'c': 'p', 's': 3, 'x': 325, 'y': 275, 'w': 350, 'h': 125, 'txt': 'Auftrag erfassen'},
          {'t': 'a', 'c': 'k', 's': 3, 'x1': 500, 'y1': 400, 'x2': 500, 'y2': 500},
          {'t': 'd', 'c': 'r', 's': 3, 'x': 325, 'y': 500, 'w': 350, 'h': 200, 'txt': 'Ware vorrätig?'},
          {'t': 'x', 'c': 'b', 'x': 700, 'y': 600, 'txt': 'nein'},
        ],
      },
    }),
    'kvm_pruef_erg': json.encode([
      d('a1', 'P-RE-20240425', 40, 72),
      d('a2', 'P-BW-20240425', 35, 58),
      d('a3', 'P-MI-20240425', 30, 41),
      d('a4', 'P-RE-20231121', 20, 64, echt: true),
      d('a5', 'P-ZI-20240425', 10, 66),
      d('a6', 'P-NT-20240425', 5, 53),
      d('a7', 'P-RE-20240425', 2, 90),
    ]),
  };
}

Future<void> _app(WidgetTester tester, Size groesse,
    {bool dunkel = false, double dpr = 2, Map<String, Object> extra = const {}}) async {
  debugDisableShadows = false;
  tester.view.physicalSize = groesse * dpr;
  tester.view.devicePixelRatio = dpr;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({..._stand(), ...extra});
  await tester.runAsync(() async {
    await _schriften();
    await DataService.instance.load();
    await ThemeController.instance.load();
  });
  ThemeController.instance.set(dunkel ? ThemeMode.dark : ThemeMode.light);
  AppState.instance.seite = AppSeite.start;
  await tester.pumpWidget(const KvmApp());
  await _warten(tester, 30);
  AppState.instance.vergleichVerfuegbar.value = true;
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _warten(WidgetTester tester, [int n = 12]) async {
  for (var k = 0; k < n; k++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _foto(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

Future<void> _seite(WidgetTester tester, AppSeite s) async {
  AppState.instance.geheZu(s);
  await tester.pump(const Duration(milliseconds: 300));
}

CaseStudy _fall(String id) => DataService.instance.cases.firstWhere((c) => c.id == id);

Future<void> _oeffnen(WidgetTester tester, Widget seite) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(MaterialPageRoute(builder: (_) => seite));
  await _warten(tester);
}

Future<void> _schliessen(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);
  await _warten(tester, 6);
}

void main() {
  const handy = Size(390, 844);
  const klein = Size(375, 667);

  testWidgets('Prüfungen hell', (tester) async {
    await _app(tester, handy);
    await _foto(tester, 'pr_01_start_chance');
    await _seite(tester, AppSeite.pruefungen);
    await _foto(tester, 'pr_02_liste');
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await _warten(tester, 4);
    await _foto(tester, 'pr_03_liste_termine');
    // FR-002 F: Die Chips passen auf 390 dp in höchstens drei Zeilen.
    final zeilen = {
      for (final t in ['Alle', 'Recht', 'BWL', 'Methoden', 'Zusammenarbeit', 'Naturwiss. & Technik', 'Fuhrpark (FT)', 'Organisation (OK)'])
        tester.getTopLeft(find.text(t).last).dy.round(),
    };
    expect(zeilen.length, lessThanOrEqualTo(3));
    await tester.ensureVisible(find.text('BWL').last);
    await _warten(tester, 2);
    await tester.tap(find.text('BWL').last);
    await _warten(tester, 4);
    await _foto(tester, 'pr_04_liste_filter');

    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-OK-20221115'), startIndex: 6));
    await _foto(tester, 'pr_05_blatt_kopf');
    await tester.ensureVisible(find.text('RECHENWEG').first);
    await _warten(tester, 4);
    await _foto(tester, 'pr_06_blatt_rechenweg');
    await tester.ensureVisible(find.text('Lösung zu a) aufdecken'));
    await _warten(tester, 2);
    await tester.tap(find.text('Lösung zu a) aufdecken'));
    await _warten(tester, 4);
    await tester.ensureVisible(find.text('DEINE ANTWORT').first);
    await _warten(tester, 4);
    await _foto(tester, 'pr_07_blatt_loesung');
    await tester.ensureVisible(find.text('DEINE PUNKTE').first);
    await _warten(tester, 4);
    await _foto(tester, 'pr_08_blatt_punkte');
    await _schliessen(tester);

    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-MI-20241106'), startIndex: 4));
    await tester.ensureVisible(find.text('SKIZZE').first);
    await _warten(tester, 4);
    await _foto(tester, 'pr_09_skizze');
    await _schliessen(tester);

    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-NT-20141112'), startIndex: 12));
    await tester.ensureVisible(find.text('SKIZZE').first);
    await _warten(tester, 8);
    await _foto(tester, 'pr_10_skizze_anlage');
    await _schliessen(tester);

    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-MI-20200505'), startIndex: 4));
    await tester.ensureVisible(find.textContaining('Tragen Sie in den Netzplan').first);
    await _warten(tester, 4);
    await _foto(tester, 'pr_11_blatt_mi_tabelle');
    await _schliessen(tester);

    final ok = _fall('P-OK-20221115');
    await _oeffnen(
        tester,
        ResultScreen(
          mode: RoundMode.cases,
          pool: ok.asPool(),
          results: List<bool?>.filled(ok.steps.length, null),
          wrong: const [],
          fall: ok,
        ));
    await _foto(tester, 'pr_12_ergebnis_offen');
    await _schliessen(tester);
    debugDisableShadows = true;
  });

  testWidgets('Prüfungsbedingungen', (tester) async {
    final jetzt = DateTime.now().millisecondsSinceEpoch;
    await _app(tester, handy, extra: {
      'kvm_echt': json.encode({'id': 'P-NT-20150429', 'start': jetzt - 51 * 60000, 'min': 60}),
    });
    await _seite(tester, AppSeite.pruefungen);
    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-NT-20150429')));
    await _foto(tester, 'pr_13_echt_laeuft');
    Echtbedingungen.instance.abgeben('P-NT-20150429');
    await _schliessen(tester);
    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-NT-20150429')));
    await _foto(tester, 'pr_14_echt_abgegeben');
    final nt = _fall('P-NT-20150429');
    await _schliessen(tester);
    await _oeffnen(
        tester,
        ResultScreen(
          mode: RoundMode.cases,
          pool: nt.asPool(),
          results: List<bool?>.filled(nt.steps.length, null),
          wrong: const [],
          fall: nt,
          echt: Echtbedingungen.instance.von('P-NT-20150429'),
        ));
    await _foto(tester, 'pr_15_ergebnis_echt');
    debugDisableShadows = true;
  });

  testWidgets('Prüfungen dunkel', (tester) async {
    await _app(tester, handy, dunkel: true);
    await _foto(tester, 'dunkel_pr_01_start');
    await _seite(tester, AppSeite.pruefungen);
    await _foto(tester, 'dunkel_pr_02_liste');
    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-OK-20221115'), startIndex: 6));
    await _foto(tester, 'dunkel_pr_05_blatt_kopf');
    await tester.ensureVisible(find.text('RECHENWEG').first);
    await _warten(tester, 4);
    await _foto(tester, 'dunkel_pr_06_blatt_rechenweg');
    await tester.ensureVisible(find.text('Lösung zu a) aufdecken'));
    await _warten(tester, 2);
    await tester.tap(find.text('Lösung zu a) aufdecken'));
    await _warten(tester, 4);
    await tester.ensureVisible(find.text('DEINE ANTWORT').first);
    await _warten(tester, 4);
    await _foto(tester, 'dunkel_pr_07_blatt_loesung');
    await _schliessen(tester);
    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-MI-20241106'), startIndex: 4));
    await tester.ensureVisible(find.text('SKIZZE').first);
    await _warten(tester, 4);
    await _foto(tester, 'dunkel_pr_09_skizze');
    debugDisableShadows = true;
  });

  testWidgets('Klein', (tester) async {
    await _app(tester, klein);
    await _foto(tester, 'klein_pr_01_start');
    await _seite(tester, AppSeite.pruefungen);
    await _foto(tester, 'klein_pr_02_liste');
    await _oeffnen(tester, AufgabenblattScreen(fall: _fall('P-OK-20221115'), startIndex: 6));
    await _foto(tester, 'klein_pr_05_blatt_kopf');
    await tester.ensureVisible(find.text('RECHENWEG').first);
    await _warten(tester, 4);
    await _foto(tester, 'klein_pr_06_blatt_rechenweg');
    debugDisableShadows = true;
  });
}
