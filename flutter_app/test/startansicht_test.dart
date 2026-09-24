import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/main.dart';
import 'package:kvm_trainer/services/app_state.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/erfolge.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/theme/palette.dart';
import 'package:kvm_trainer/theme/theme_controller.dart';

/// Mehrseitige Startansicht (FR-015): Seiten, Navigation, Statistik zum
/// Aufziehen, Zurück-Taste, Darstellung.
Map<String, Object> _stand() {
  final qs = (json.decode(File('assets/data/questions.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final heute = LerntageService.heute();
  final prog = <String, dynamic>{};
  for (final q in qs.take(30)) {
    prog[q['id'] as String] = {'s': 3, 'c': 3, 'w': 0, 'b': 3, 'l': 1, 'd': 99999};
  }
  return {
    'kvm_progress_v1': json.encode(prog),
    'kvm_tage': json.encode({'$heute': 5, '${heute - 1}': 7, '${heute - 2}': 2, '${heute - 4}': 9}),
  };
}

Future<void> _starten(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(_stand());
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
}

void main() {
  testWidgets('Start zeigt Kennzahlen, Heute-Karte, Prüfungen und sechs Kacheln', (tester) async {
    await _starten(tester);
    expect(find.text('MEISTER FÜR KRAFTVERKEHR'), findsOneWidget);
    expect(find.text('gemeistert'), findsOneWidget);
    expect(find.text('Tage in Folge'), findsOneWidget);
    expect(find.text('ORIGINAL-IHK-PRÜFUNGEN'), findsOneWidget);
    for (final t in ['Mündlich', 'Fallaufgaben', 'Formelbuch', 'Kostenwesen', 'Gefahrgut']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // Serie: heute, gestern, vorgestern → 3
    expect(LerntageService.instance.serie(), 3);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('Statistik klappt per Antippen und Wischen auf und zu', (tester) async {
    await _starten(tester);
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsNothing);
    await tester.tap(find.text('STATISTIK'));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
    expect(find.text('Lernstand zurücksetzen'), findsOneWidget);
    // Tippen direkt nach dem Wischen zählt nicht; wischen nach oben schließt.
    await tester.drag(find.text('gemeistert'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsNothing);
    await tester.drag(find.text('gemeistert'), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
  });

  testWidgets('Navigation: Seiten wechseln, ohne Rangliste vier Reiter, Zurück führt nach Start', (tester) async {
    await _starten(tester);
    // Ohne Anmeldung/Supabase gibt es die Rangliste nicht → kein Reiter „Vergleich“.
    expect(AppState.instance.vergleichVerfuegbar.value, false);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Lernen'));
    await tester.pumpAndSettle();
    expect(AppState.instance.seite, AppSeite.lernen);
    expect(find.text('DEIN LERNWEG'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Konto'));
    await tester.pumpAndSettle();
    expect(find.text('KONTO & EINSTELLUNGEN'), findsOneWidget);
    // Android-Zurück auf einer Unterseite → Start (App bleibt offen)
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(AppState.instance.seite, AppSeite.start);
    // Kachel „Lernen“ öffnet die Seite
    await tester.tap(find.text('Lernen').last);
    await tester.pumpAndSettle();
    expect(AppState.instance.seite, AppSeite.lernen);
  });

  testWidgets('Darstellung: Dunkel wirkt sofort und wird gespeichert', (tester) async {
    await _starten(tester);
    expect(KvmPalette.current.isDark, false);
    ThemeController.instance.set(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(KvmPalette.current.isDark, true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kvm_theme'), 'dark');
    ThemeController.instance.set(ThemeMode.system);
    await tester.pumpAndSettle();
    expect(prefs.getString('kvm_theme'), isNull);
  });

  test('Erfolge: zehn Medaillen aus dem Lernstand', () {
    final e = erfolgeListe();
    expect(e.length, 10);
    expect(e.first.titel, 'Erste Schritte');
  });
}
