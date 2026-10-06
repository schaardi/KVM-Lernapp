import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/pruefung/echt.dart';
import 'package:kvm_trainer/pruefung/ergebnisse.dart';
import 'package:kvm_trainer/screens/pruefungen_screen.dart';
import 'package:kvm_trainer/services/answer_store.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/letzte_pruefung.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/selection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pruefdaten.dart';

/// Original-Prüfungen nur mit Freigabe (FR-020): Die App bündelt keine
/// Prüfungen; freigegebene werden nachträglich eingesetzt und wieder entfernt.
void main() {
  Future<void> laden(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await DataService.instance.load();
      await SelectionService.instance.load();
      await ProgressService.instance.load();
      await LerntageService.instance.load();
      await LetztePruefung.instance.load();
      await AnswerStore.instance.init();
      await Echtbedingungen.instance.load();
      await PruefErgebnisse.instance.load();
    });
  }

  Future<void> liste(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: const Scaffold(body: PruefungenListe())));
    await tester.pump();
  }

  testWidgets('gebündelt sind keine Prüfungen und keine Anlagen', (tester) async {
    await laden(tester);
    DataService.instance.pruefungenEntfernen();
    expect(DataService.instance.cases, isNotEmpty);
    expect(DataService.instance.cases.where((c) => c.id.startsWith('P-')), isEmpty);
    expect(DataService.instance.anlagen, isEmpty);
  });

  testWidgets('ohne Freigabe: Hinweis mit Weg zur Web-App statt einer Liste', (tester) async {
    await laden(tester);
    DataService.instance.pruefungenEntfernen();
    await liste(tester);
    expect(find.textContaining('Die Original-IHK-Prüfungen gibt es nur mit Freigabe.'), findsOneWidget);
    expect(find.textContaining('schaardi.github.io/KVM-Lernapp › Prüfungen'), findsOneWidget);
  });

  testWidgets('einsetzen, erneut einsetzen, entfernen', (tester) async {
    await laden(tester);
    final eigene = DataService.instance.cases.where((c) => !c.id.startsWith('P-')).length;

    beispielEinsetzen();
    beispielEinsetzen(); // ersetzt, verdoppelt nicht
    final p = DataService.instance.cases.where((c) => c.id.startsWith('P-')).toList();
    expect(p.length, 6);
    expect(DataService.instance.cases.length, eigene + 6);
    expect(DataService.instance.anlage('nt25-rampe')?.titel, 'Beispielabbildung (erfunden)');
    await liste(tester);
    expect(find.textContaining('nur mit Freigabe'), findsNothing);
    expect(find.text('Naturwiss. & Technik'), findsWidgets);

    DataService.instance.pruefungenEntfernen();
    expect(DataService.instance.cases.length, eigene);
    expect(DataService.instance.anlage('nt25-rampe'), isNull);
    await liste(tester);
    expect(find.textContaining('nur mit Freigabe'), findsOneWidget);
  });

  test('nur Fälle mit Prüfungs-ID werden eingesetzt', () {
    DataService.instance.pruefungenEinsetzen({
      'pruefungen': [
        {'id': 'F-XX-c1', 'f': 1, 'sub': 'x', 'title': 'Fremd', 'context': '', 'steps': []},
      ],
    });
    expect(DataService.instance.cases.where((c) => c.id == 'F-XX-c1'), isEmpty);
    DataService.instance.pruefungenEntfernen();
  });
}
