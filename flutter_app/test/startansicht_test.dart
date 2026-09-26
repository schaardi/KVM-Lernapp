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

Future<void> _starten(WidgetTester tester, {Size groesse = const Size(390, 844)}) async {
  tester.view.physicalSize = groesse * 2;
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
    // Schneller Wisch nach oben schließt, nach unten öffnet.
    await tester.fling(find.text('gemeistert'), const Offset(0, -60), 1000);
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.fling(find.text('gemeistert'), const Offset(0, 60), 1000);
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
    // Tippen direkt nach dem Wischen zählt nicht.
    await tester.tap(find.text('STATISTIK'));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
  });

  testWidgets('Statistik folgt beim Ziehen dem Finger und rastet ein', (tester) async {
    await _starten(tester);
    double sichtbar() => tester.getSize(find.byType(SizeTransition)).height;
    // Langsam ein Stück nach unten: Die Leiste folgt dem Finger …
    final g = await tester.startGesture(tester.getCenter(find.text('gemeistert')));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
    final h = sichtbar();
    expect(h, greaterThan(60));
    expect(h, lessThan(100));
    // … und schnappt unter einem Drittel beim Loslassen zurück.
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsNothing);
    // Weit genug gezogen und langsam losgelassen: rastet offen ein.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.timedDrag(find.text('gemeistert'), const Offset(0, 420), const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('PRÜFUNGSREIFE JE FACH'), findsOneWidget);
    expect(tester.widget<SizeTransition>(find.byType(SizeTransition)).sizeFactor.value, 1);
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

  testWidgets('Seitenwechsel gleitet und behält Zustand und Scrollposition', (tester) async {
    await _starten(tester);
    // Deckkraft der Seiten im Stapel (0 = Start, 1 = Lernen).
    double deckung(int i) => tester.widget<Opacity>(find.byKey(ValueKey('seite-$i'))).opacity;
    await tester.tap(find.widgetWithText(NavigationDestination, 'Lernen'));
    await tester.pump();
    // Nacheinander, nicht übereinander: Erst huscht die alte Seite hinaus …
    await tester.pump(const Duration(milliseconds: 60));
    expect(deckung(0), inExclusiveRange(0.0, 1.0));
    expect(deckung(1), 0.0);
    // … dann gleitet die neue herein, die alte ist schon weg.
    await tester.pump(const Duration(milliseconds: 90));
    expect(deckung(0), 0.0);
    expect(deckung(1), greaterThan(0.0));
    expect(find.text('MEISTER FÜR KRAFTVERKEHR'), findsOneWidget);
    expect(find.text('DEIN LERNWEG'), findsOneWidget);
    final x = tester.getTopLeft(find.text('DEIN LERNWEG')).dx;
    await tester.pumpAndSettle();
    expect(deckung(1), 1.0);
    expect(tester.getTopLeft(find.text('DEIN LERNWEG')).dx, lessThan(x));
    expect(find.text('MEISTER FÜR KRAFTVERKEHR'), findsNothing);
    // Scrollposition bleibt beim Hin und Her erhalten.
    await tester.drag(find.text('DEIN LERNWEG'), const Offset(0, -300));
    await tester.pumpAndSettle();
    final y = tester.getTopLeft(find.text('DEIN LERNWEG')).dy;
    await tester.tap(find.widgetWithText(NavigationDestination, 'Konto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Lernen'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('DEIN LERNWEG')).dy, y);
  });

  testWidgets('Breit: Die Markierung der oberen Leiste gleitet zum neuen Reiter', (tester) async {
    await _starten(tester, groesse: const Size(1280, 800));
    Rect marke() => tester.getRect(find.byType(AnimatedPositioned));
    Rect reiter(String t) => tester.getRect(find.ancestor(of: find.text(t), matching: find.byType(Material)).first);
    expect(marke(), reiter('Start'));
    await tester.tap(find.text('Prüfungen').first);
    // Umbau, dann Vermessen – ab dem nächsten Bild gleitet die Markierung.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mitte = marke();
    expect(mitte.left, greaterThan(reiter('Start').left));
    expect(mitte.left, lessThan(reiter('Prüfungen').left));
    await tester.pumpAndSettle();
    expect(marke(), reiter('Prüfungen'));
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
