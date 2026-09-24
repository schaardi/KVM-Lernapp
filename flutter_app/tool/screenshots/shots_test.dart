// Screenshots der App aus dem Widget-Test – zum Prüfen von Layout, Schriften
// und Dunkelmodus ohne Gerät (nicht Teil der normalen Test-Suite):
//   flutter test --update-goldens tool/screenshots/shots_test.dart
// Schreibt PNGs nach tool/screenshots/goldens/ (nicht eingecheckt).
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/screens/kw/kw_hub.dart';
import 'package:kvm_trainer/screens/login_screen.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
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

/// Realistischer Lernstand: 600 gesehen, 400 gemeistert, Lerntage, eine Prüfung.
Map<String, Object> _stand() {
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
  };
}

Future<void> _app(WidgetTester tester, Size groesse, {bool dunkel = false, double dpr = 2}) async {
  debugDisableShadows = false;
  tester.view.physicalSize = groesse * dpr;
  tester.view.devicePixelRatio = dpr;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(_stand());
  await tester.runAsync(() async {
    await _schriften();
    await DataService.instance.load();
    await ThemeController.instance.load();
  });
  ThemeController.instance.set(dunkel ? ThemeMode.dark : ThemeMode.light);
  AppState.instance.seite = AppSeite.start;
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

void main() {
  const handy = Size(390, 844);
  const klein = Size(375, 667);
  const desktop = Size(1280, 800);

  testWidgets('Handy hell', (tester) async {
    await _app(tester, handy);
    await _foto(tester, 'handy_1_start');
    await tester.tap(find.text('STATISTIK'));
    await tester.pump(const Duration(milliseconds: 400));
    await _foto(tester, 'handy_2_statistik');
    await tester.tap(find.text('STATISTIK'));
    await tester.pump(const Duration(milliseconds: 600));
    for (final (i, s) in [(3, AppSeite.lernen), (4, AppSeite.pruefungen), (5, AppSeite.vergleich), (6, AppSeite.konto)]) {
      await _seite(tester, s);
      await _foto(tester, 'handy_${i}_${s.name}');
    }
    debugDisableShadows = true;
  });

  testWidgets('Handy dunkel', (tester) async {
    await _app(tester, handy, dunkel: true);
    await _foto(tester, 'dunkel_1_start');
    await _seite(tester, AppSeite.lernen);
    await _foto(tester, 'dunkel_3_lernen');
    await _seite(tester, AppSeite.konto);
    await _foto(tester, 'dunkel_6_konto');
    debugDisableShadows = true;
  });

  testWidgets('Kostenwesen und Login', (tester) async {
    for (final dunkel in [false, true]) {
      await _app(tester, handy, dunkel: dunkel);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute(builder: (_) => const KostenwesenScreen()));
      await tester.pump(const Duration(milliseconds: 600));
      await _foto(tester, 'kw_hub_${dunkel ? 'dunkel' : 'hell'}');
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 600));
      await _foto(tester, 'login_${dunkel ? 'dunkel' : 'hell'}');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 400));
    }
    debugDisableShadows = true;
  });

  testWidgets('Klein', (tester) async {
    await _app(tester, klein);
    await _foto(tester, 'klein_1_start');
    debugDisableShadows = true;
  });

  testWidgets('Desktop', (tester) async {
    await _app(tester, desktop, dpr: 1.25);
    await _foto(tester, 'desktop_1_start');
    await _seite(tester, AppSeite.lernen);
    await _foto(tester, 'desktop_3_lernen');
    debugDisableShadows = true;
  });
}
