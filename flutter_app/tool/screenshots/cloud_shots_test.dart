// Screenshots der Seite „Vergleich“ und des Dialogs „Lernende“ – mit der
// Test-Attrappe statt Supabase (nicht Teil der normalen Test-Suite):
//   flutter test --update-goldens tool/screenshots/cloud_shots_test.dart
// Schreibt PNGs nach tool/screenshots/goldens/ (nicht eingecheckt).
// Testwerkzeug: nutzt Test-Hilfen (Attrappe, Mock-Speicher) außerhalb von test/.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/cloud/lernende_blatt.dart';
import 'package:kvm_trainer/cloud/vergleich_dienst.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/screens/pages/vergleich_seite.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/pruef_stat.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';
import '../../test/cloud/test_server.dart';

// ---- Helfer wie in shots_test.dart ----

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

/// Realistischer Lernstand: 600 gesehen, 400 gemeistert, Lerntage.
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
  return {'kvm_progress_v1': json.encode(prog), 'kvm_tage': json.encode(tage)};
}

Future<void> _foto(WidgetTester tester, String name) async {
  // zwei Frames: Material-Übergänge (Farbe, Rahmen) sind danach abgeschlossen
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

// ---- Vergleich ----

/// Rangliste mit 13 anderen, einer Anfrage, zwei Freunden und einer Gruppe.
TestServer _demo({bool dabei = true}) {
  final s = TestServer();
  final jetzt = DateTime.now().toUtc();
  s.andere.addAll([
    TestPerson('Cora', reife: 64, antworten: 312, serie: 5, pruefN: 6, pruefOk: 5, pruefSchnitt: 68, chance: 74,
        sichtbarkeit: 'alle', gemeistert: 1240, detailsAm: jetzt, details: {
      'f': {
        '1': {'r': 71, 'm': 420, 'g': 560, 'n': 662},
        '2': {'r': 58, 'm': 380, 'g': 610, 'n': 838},
        '3': {'r': 66, 'm': 300, 'g': 410, 'n': 538},
        '4': {'r': 49, 'm': 250, 'g': 400, 'n': 688},
        '5': {'r': 31, 'm': 190, 'g': 520, 'n': 940},
      },
      't14': [0, 34, 12, 0, 48, 60, 22, 0, 18, 41, 55, 0, 27, 36],
      'tage': 57,
      'echt': {'n': 2, 'best': 74},
      'pr': {
        'RE': {'n': 2, 'ok': 2, 's': 71, 'c': 88},
        'BW': {'n': 1, 'ok': 1, 's': 62, 'c': 77},
        'MI': {'n': 1, 'ok': 1, 's': 66, 'c': 82},
        'ZI': {'n': 1, 'ok': 0, 's': 44, 'c': 34},
        'NT': {'n': 1, 'ok': 1, 's': 58, 'c': 67},
      },
      'pc': {'bq': 12, 'hq': null, 'g': null},
    }),
    TestPerson('Lkw-Profi', reife: 58, antworten: 288, serie: 12, pruefN: 4, pruefOk: 4, pruefSchnitt: 72, chance: 81),
    TestPerson('Brummi_Bernd', reife: 71, antworten: 205, serie: 3, pruefN: 3, pruefOk: 2, pruefSchnitt: 57, chance: 49),
    TestPerson('Anna.K', reife: 45, antworten: 160, serie: 1),
    TestPerson('Disponentin', reife: 39, antworten: 141, serie: 4, pruefN: 2, pruefOk: 1, pruefSchnitt: 51),
    TestPerson('Meister Max', reife: 83, antworten: 122, serie: 9, pruefN: 7, pruefOk: 7, pruefSchnitt: 79, chance: 92),
    TestPerson('Tanja', reife: 52, antworten: 98, serie: 2),
    TestPerson('Speditionsprofi', reife: 36, antworten: 77, serie: 1),
    TestPerson('Kurt', reife: 28, antworten: 61),
    TestPerson('Fuhrpark_Fritz', reife: 47, antworten: 54, serie: 2, pruefN: 1, pruefOk: 1, pruefSchnitt: 63, chance: 58),
    TestPerson('Jana', reife: 33, antworten: 40),
    TestPerson('Holger', reife: 21, antworten: 12),
    TestPerson('Emre', reife: 60),
  ]);
  if (dabei) {
    s.ich = TestPerson('Kai_Lkw', pid: 'pid-ich', reife: 49, antworten: 35, serie: 3);
    s.freunde.addAll(['pid-cora', 'pid-meister max']);
    s.anfragenAnMich.add('pid-tanja');
    s.gesendet.add('pid-brummi_bernd');
    final p = {for (final x in s.andere) x.name: x};
    s.gruppen.add(TestGruppe('g-koeln', 'K7M2QX', 'Meisterkurs IHK Köln', [s.ich!, p['Cora']!, p['Lkw-Profi']!, p['Anna.K']!]));
  }
  return s;
}

/// Eigene Prüfungsergebnisse: Basisqualifikationen vollständig, Fuhrpark gewertet.
PruefStatistik _stat() => const PruefStatistik(
      n: 6,
      ok: 5,
      schnitt: 64,
      bq: 0.58,
      haupt: 0.58,
      bereiche: {
        'RE': PruefBereichStat(kurz: 'Recht', n: 1, ok: 1, schnitt: 70, chance: 0.886),
        'BW': PruefBereichStat(kurz: 'BWL', n: 1, ok: 1, schnitt: 62, chance: 0.769),
        'MI': PruefBereichStat(kurz: 'Methoden', n: 1, ok: 1, schnitt: 70, chance: 0.886),
        'ZI': PruefBereichStat(kurz: 'Zusammenarbeit', n: 1, ok: 1, schnitt: 66, chance: 0.84),
        'NT': PruefBereichStat(kurz: 'Naturwiss. & Technik', n: 1, ok: 1, schnitt: 61, chance: 0.75),
        'FT': PruefBereichStat(kurz: 'Fuhrpark', n: 1, ok: 0, schnitt: 45, chance: 0.395),
      },
    );

Future<void> _app(WidgetTester tester, Size groesse, TestServer s, {bool dunkel = false, double dpr = 2}) async {
  debugDisableShadows = false;
  tester.view.physicalSize = groesse * dpr;
  tester.view.devicePixelRatio = dpr;
  SharedPreferences.setMockInitialValues(_stand());
  await tester.runAsync(() async {
    await _schriften();
    await DataService.instance.load();
    await ThemeController.instance.load();
  });
  ThemeController.instance.set(dunkel ? ThemeMode.dark : ThemeMode.light);
  AppState.instance.seite = AppSeite.start;
  pruefStatistik = _stat;
  await tester.pumpWidget(const KvmApp());
  for (var k = 0; k < 30; k++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  final d = VergleichDienst.instance;
  d.testStart(s);
  await d.laden(erzwingen: true);
  AppState.instance.geheZu(AppSeite.vergleich);
  await tester.pump(const Duration(milliseconds: 300));
}

BuildContext _ctx(WidgetTester tester) => tester.element(find.byType(VergleichSeite));

Future<void> _blatt(WidgetTester tester, {String? tab, String? profil}) async {
  oeffneLernende(_ctx(tester), tab: tab, profilName: profil);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _blattZu(WidgetTester tester) async {
  Navigator.of(_ctx(tester)).pop();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Im Blatt nach unten: erst zieht es sich ganz auf, dann scrollt der Inhalt.
Future<void> _blattRunter(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _nachUnten(WidgetTester tester) async {
  final scroll = find.descendant(of: find.byType(VergleichSeite), matching: find.byType(Scrollable)).first;
  await tester.drag(scroll, const Offset(0, -2000));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  const handy = Size(390, 844);
  const lang = Size(390, 1500);
  const schmal = Size(320, 1400);
  const desktop = Size(1280, 800);

  testWidgets('Vergleich hell', (tester) async {
    await _app(tester, lang, _demo(dabei: false));
    await _foto(tester, 'vergleich_1_beitritt');

    final d = VergleichDienst.instance;
    d.testStart(_demo());
    await d.laden(erzwingen: true);
    await _foto(tester, 'vergleich_2_woche');
    await d.waehleModus(RanglistenModus.pruef);
    await _foto(tester, 'vergleich_3_pruefungen');
    await d.waehleAnsicht('freunde');
    await _foto(tester, 'vergleich_4_freunde_pruef');
    await d.waehleModus(RanglistenModus.woche);
    await _foto(tester, 'vergleich_5_freunde');
    await d.waehleAnsicht('g-koeln');
    await _foto(tester, 'vergleich_6_gruppe');
    d.gformUmschalten();
    await _foto(tester, 'vergleich_7_neue_gruppe');
    debugDisableShadows = true;
  });

  testWidgets('Lernende hell', (tester) async {
    await _app(tester, handy, _demo());
    await _foto(tester, 'vergleich_8_handy');
    await _blatt(tester);
    await _foto(tester, 'lernende_1_freunde');
    VergleichDienst.instance.lernendeTab('alle');
    await tester.pump(const Duration(milliseconds: 300));
    await _foto(tester, 'lernende_2_alle');
    VergleichDienst.instance.lernendeTab('profil');
    await tester.pump(const Duration(milliseconds: 300));
    await _foto(tester, 'lernende_3_mein_profil');
    await _blattZu(tester);
    await _blatt(tester, profil: 'Cora');
    await _foto(tester, 'lernende_4_profil');
    await _blattRunter(tester);
    await _foto(tester, 'lernende_5_profil_unten');
    await _blattZu(tester);
    await _blatt(tester, profil: 'Brummi_Bernd');
    await _foto(tester, 'lernende_6_profil_gesperrt');
    debugDisableShadows = true;
  });

  testWidgets('Vergleich dunkel', (tester) async {
    await _app(tester, lang, _demo(), dunkel: true);
    await _foto(tester, 'dunkel_vergleich_2_woche');
    final d = VergleichDienst.instance;
    await d.waehleModus(RanglistenModus.pruef);
    await _foto(tester, 'dunkel_vergleich_3_pruefungen');
    await d.waehleModus(RanglistenModus.woche);
    await d.waehleAnsicht('g-koeln');
    await _foto(tester, 'dunkel_vergleich_6_gruppe');
    d.testStart(_demo(dabei: false));
    await d.laden(erzwingen: true);
    await _foto(tester, 'dunkel_vergleich_1_beitritt');
    debugDisableShadows = true;
  });

  testWidgets('Lernende dunkel', (tester) async {
    await _app(tester, handy, _demo(), dunkel: true);
    await _blatt(tester);
    await _foto(tester, 'dunkel_lernende_1_freunde');
    await _blattZu(tester);
    await _blatt(tester, profil: 'Cora');
    await _foto(tester, 'dunkel_lernende_4_profil');
    await _blattRunter(tester);
    await _foto(tester, 'dunkel_lernende_5_profil_unten');
    debugDisableShadows = true;
  });

  testWidgets('Schmal und Desktop', (tester) async {
    await _app(tester, schmal, _demo());
    await _foto(tester, 'schmal_vergleich_woche');
    await VergleichDienst.instance.waehleModus(RanglistenModus.pruef);
    await _foto(tester, 'schmal_vergleich_pruefungen');
    await VergleichDienst.instance.waehleModus(RanglistenModus.woche);
    await _blatt(tester, profil: 'Cora');
    await _foto(tester, 'schmal_lernende_profil');
    await _blattZu(tester);
    await _nachUnten(tester);
    await _foto(tester, 'schmal_vergleich_fuss');
    debugDisableShadows = true;
  });

  testWidgets('Desktop', (tester) async {
    await _app(tester, desktop, _demo(), dpr: 1.25);
    await _foto(tester, 'desktop_vergleich');
    await _blatt(tester, profil: 'Cora');
    await _foto(tester, 'desktop_lernende_profil');
    debugDisableShadows = true;
  });
}
