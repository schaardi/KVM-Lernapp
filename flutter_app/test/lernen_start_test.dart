import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/lernen/datum.dart';
import 'package:kvm_trainer/lernen/erinnerung.dart';
import 'package:kvm_trainer/lernen/erinnerung_service.dart';
import 'package:kvm_trainer/lernen/lernplan.dart';
import 'package:kvm_trainer/lernen/mitteilungen.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/screens/pages/start_seite.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';
import 'package:kvm_trainer/widgets/konto/erinnerung_block.dart';

/// Prüfungstermin in der Heute-Karte (FR-006) und Lern-Erinnerung im Konto
/// (FR-009) in der laufenden App.
class _Mitteilungen implements MitteilungsDienst {
  bool erlaubt = true;
  final Set<int> ids = {};
  @override
  Future<void> starten({VoidCallback? onTippen}) async {}
  @override
  Future<bool> erlaubnisAnfragen() async => erlaubt;
  @override
  Future<void> abbrechen(Iterable<int> l) async => ids.removeAll(l);
  @override
  Future<void> planen(GeplanteErinnerung m) async => ids.add(m.id);
  @override
  Future<List<int>> geplant() async => ids.toList()..sort();
}

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
  await lade('Inter', ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Medium.ttf', 'assets/fonts/Inter-SemiBold.ttf', 'assets/fonts/Inter-Bold.ttf']);
  await lade('BarlowCondensed', ['assets/fonts/BarlowCondensed-SemiBold.ttf', 'assets/fonts/BarlowCondensed-Bold.ttf']);
  await lade('IBMPlexMono', ['assets/fonts/IBMPlexMono-Medium.ttf', 'assets/fonts/IBMPlexMono-SemiBold.ttf']);
  if (File('$mf/MaterialIcons-Regular.otf').existsSync()) await lade('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
}

/// Lernstand wie auf den Screenshots: 600 gesehen, 400 gemeistert, Lerntage.
Map<String, Object> _realistisch() {
  final qs = (json.decode(File('assets/data/questions.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final heute = LerntageService.heute();
  final heuteUtc = DateTime.now().millisecondsSinceEpoch ~/ 86400000;
  final prog = <String, dynamic>{};
  for (var i = 0; i < 600; i++) {
    final g = i % 3 != 2;
    prog[qs[i]['id'] as String] = {'s': g ? 4 : 1, 'c': g ? 4 : 0, 'w': g ? 0 : 1, 'b': g ? 3 : 0, 'l': g ? 1 : 0, 'd': g ? heuteUtc + 5 : heuteUtc - 1};
  }
  final tage = <String, int>{};
  for (final (d, n) in [(0, 18), (1, 40), (2, 22), (4, 55), (5, 12), (7, 30), (9, 8)]) {
    tage['${heute - d}'] = n;
  }
  return {
    'kvm_progress_v1': json.encode(prog),
    'kvm_tage': json.encode(tage),
    'kvm_letzte_pruefung': json.encode({'id': 'P-NT-20150429', 'nr': 2}),
  };
}

Future<_Mitteilungen> _starten(WidgetTester tester, Map<String, Object> werte, {Size groesse = const Size(390, 844)}) async {
  tester.view.physicalSize = groesse * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(werte);
  final m = _Mitteilungen();
  ErinnerungService.instance.dienst = m;
  await tester.runAsync(() async {
    await DataService.instance.load();
    await ThemeController.instance.load();
  });
  AppState.instance.seite = AppSeite.start;
  await tester.pumpWidget(const KvmApp());
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 30));
  }
  return m;
}

Future<void> _tippe(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  // ein Frame zum Starten der Animation, dann bis sie steht
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  final heute = LerntageService.heute();

  testWidgets('Ohne Termin: Link, Formular mit Fehler, Speichern, Ändern, Entfernen', (tester) async {
    await _starten(tester, {});
    expect(find.text('Prüfungstermin eintragen'), findsOneWidget);
    await _tippe(tester, find.text('Prüfungstermin eintragen'));
    expect(find.text('PRÜFUNGSTERMIN'), findsOneWidget);
    // deutsche Beschriftung im Kalender (er zeigt den laufenden Monat)
    final jetzt = datumVonTag(heute);
    final morgen = datumVonTag(heute + 1);
    const monate = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    expect(find.text('${monate[jetzt.month - 1]} ${jetzt.year}'), findsOneWidget);
    // ohne Datum: Fehler wie im Web
    await _tippe(tester, find.text('Speichern'));
    expect(find.text('Bitte ein Datum wählen.'), findsOneWidget);
    // morgen wählen und speichern
    if (morgen.month != jetzt.month) await _tippe(tester, find.byTooltip('Nächster Monat'));
    await _tippe(tester, find.descendant(of: find.byType(CalendarDatePicker), matching: find.text('${morgen.day}')).hitTestable());
    await _tippe(tester, find.text('Speichern'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(Lernplan.instance.termin!.datum, isoVon(heute + 1));
    expect(find.text('MORGEN IST PRÜFUNG'), findsOneWidget);
    // ändern → entfernen → wieder der Link
    await _tippe(tester, find.text('ändern'));
    await _tippe(tester, find.text('Entfernen'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(Lernplan.instance.termin, isNull);
    expect(find.text('Prüfungstermin eintragen'), findsOneWidget);
  });

  testWidgets('Termin in 42 Tagen ohne Fortschritt: „Heute 0 / 245“, drei Antworten später „3 / 245“', (tester) async {
    await _starten(tester, {'kvm_pruefung': json.encode({'datum': isoVon(heute + 42)})});
    expect(DataService.instance.activeQuestions().length, 3666);
    expect(find.text('NOCH 42 TAGE'), findsOneWidget);
    expect(find.text('bis zur Prüfung am ${datumLang(heute + 42)}'), findsOneWidget);
    expect(find.text('0 / 245'), findsOneWidget);
    expect(find.textContaining('Sehr knapp: Mit 245 Fragen am Tag'), findsOneWidget);
    for (final q in DataService.instance.questions.take(3)) {
      ProgressService.instance.record(q.id, true);
    }
    AppState.instance.refresh();
    await tester.pump();
    expect(find.text('3 / 245'), findsOneWidget);
  });

  testWidgets('Termin heute und vorbei', (tester) async {
    await _starten(tester, {'kvm_pruefung': json.encode({'datum': isoVon(heute)})});
    expect(find.text('HEUTE IST PRÜFUNG'), findsOneWidget);
    expect(find.text('Viel Erfolg! Kurz vorher helfen die fälligen Fragen mehr als neuer Stoff.'), findsOneWidget);
    Lernplan.instance.speichern(isoVon(heute - 2));
    await tester.pump();
    expect(find.text('PRÜFUNG VORBEI'), findsOneWidget);
    expect(find.text('Deine Prüfung war am ${datumLang(heute - 2)}. Steht ein neuer Termin an?'), findsOneWidget);
    expect(find.text('Neuen Termin eintragen'), findsOneWidget);
  });

  testWidgets('Lern-Erinnerung: ohne Erlaubnis bleibt der Schalter aus, mit Erlaubnis wird geplant', (tester) async {
    final m = await _starten(tester, {});
    AppState.instance.geheZu(AppSeite.konto);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LERN-ERINNERUNG'), findsOneWidget);
    expect(find.text(kErinnerungStandardZeit), findsOneWidget);
    final schalter = find.descendant(of: find.byType(ErinnerungBlock), matching: find.byType(Switch));
    m.erlaubt = false;
    await _tippe(tester, schalter);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(tester.widget<Switch>(schalter).value, isFalse);
    expect(find.text(kErinnerungGesperrt), findsOneWidget);
    m.erlaubt = true;
    await _tippe(tester, schalter);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(tester.widget<Switch>(schalter).value, isTrue);
    expect(find.text(kErinnerungGesperrt), findsNothing);
    expect(m.ids, isNotEmpty);
    expect(m.ids.every(kErinnerungIds.contains), isTrue);
    await _tippe(tester, schalter);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    expect(m.ids, isEmpty);
    AppState.instance.geheZu(AppSeite.start);
  });

  testWidgets('Start mit Lernplan passt auf 390 × 760 ohne Scrollen (echte Schriften)', (tester) async {
    await tester.runAsync(_schriften);
    await _starten(tester, {..._realistisch(), 'kvm_pruefung': json.encode({'datum': isoVon(heute + 42)})},
        groesse: const Size(390, 760));
    expect(find.text('NOCH 42 TAGE'), findsOneWidget);
    for (final groesse in [const Size(390, 760), const Size(375, 667), const Size(360, 740)]) {
      tester.view.physicalSize = groesse * 2;
      await tester.pump(const Duration(milliseconds: 100));
      final s = tester.state<ScrollableState>(
          find.descendant(of: find.byType(StartSeite), matching: find.byType(Scrollable)).first);
      expect(s.position.maxScrollExtent, 0, reason: '$groesse');
    }
  });
}
