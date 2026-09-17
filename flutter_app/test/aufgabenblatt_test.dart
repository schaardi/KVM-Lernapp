import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';

/// Prüft das Aufgabenblatt-Format der gebündelten Prüfungen: Jede Teilaufgabe
/// gehört zu einer Aufgabe, die Punkte gehen auf, und der zusammengesetzte
/// Aufgabentext lässt sich aus den Feldern wieder herstellen (davon hängen die
/// KI-Exporte ab).
void main() {
  final datei = File('assets/data/cases.json');
  final faelle = (json.decode(datei.readAsStringSync()) as List<dynamic>)
      .map((e) => CaseStudy.fromJson(e as Map<String, dynamic>))
      .toList();

  test('Fälle laden', () {
    expect(faelle, isNotEmpty);
    expect(faelle.where((c) => c.id.startsWith('P-')), isNotEmpty);
  });

  test('jede Teilaufgabe gehört zu einer Aufgabe', () {
    for (final c in faelle) {
      expect(c.aufgaben, isNotEmpty, reason: '${c.id} ohne Aufgaben');
      for (final s in c.steps) {
        expect(c.aufgabeVon(s.nr), isNotNull,
            reason: '${s.id} verweist auf Aufgabe ${s.nr}, die es nicht gibt');
      }
    }
  });

  test('Punkte je Aufgabe sind die Summe ihrer Teile, Prüfungen haben 100', () {
    for (final c in faelle) {
      var gesamt = 0;
      for (final a in c.aufgaben) {
        final summe = c.steps
            .where((s) => s.nr == a.nr)
            .fold<int>(0, (n, s) => n + s.pts);
        expect(a.pts, summe, reason: '${c.id} Aufgabe ${a.nr}');
        gesamt += summe;
      }
      if (c.id.startsWith('P-')) {
        expect(gesamt, 100, reason: '${c.id} hat $gesamt statt 100 Punkte');
      }
    }
  });

  test('Verweise mit "braucht" zeigen auf vorhandene Teile derselben Aufgabe', () {
    for (final c in faelle) {
      for (final s in c.steps) {
        final labels =
            c.steps.where((t) => t.nr == s.nr).map((t) => t.teil).toSet();
        for (final b in s.braucht) {
          expect(labels, contains(b), reason: '${s.id} braucht $b)');
        }
      }
    }
  });

  test('Aufgabentext lässt sich aus den Feldern zusammensetzen', () {
    final pruefung = faelle.firstWhere((c) => c.id == 'P-BW-20251106');
    final pool = pruefung.asPool();
    final teil = pool.firstWhere((q) => q.nr == 2 && q.teil == 'c');
    final t = TaskParts.of(teil);

    expect(t.nr, 'Aufgabe 2 c)');
    expect(t.pts, '3 Punkte');
    expect(t.sit, contains('Kunststoffgranulat'));
    expect(t.frage, 'Ermitteln Sie die optimale Bestellmenge.');
    expect(t.volltext, 'Aufgabe 2 c) · 3 Punkte\n\n${t.sit}\n\n${t.frage}');
    expect(teil.maxPoints, 3);
  });

  test('Ausgangslage steht einmal an der Aufgabe, nicht in jedem Teil', () {
    final pruefung = faelle.firstWhere((c) => c.id == 'P-BW-20251106');
    final aufgabe = pruefung.aufgabeVon(2)!;
    expect(aufgabe.sit, contains('Jahresbedarf'));
    for (final s in pruefung.steps.where((s) => s.nr == 2)) {
      expect(s.q, isNot(contains('Jahresbedarf')),
          reason: '${s.id} trägt die Ausgangslage noch im Fragetext');
    }
  });

  test('Fallaufgaben ohne IHK-Bezug bekommen keinen erfundenen Aufgabenkopf', () {
    final fall = faelle.firstWhere((c) => c.id == 'F-LR-c1');
    final t = TaskParts.of(fall.asPool().first);
    expect(t.nr, isEmpty);
    expect(t.pts, isEmpty);
    expect(t.volltext, fall.steps.first.q);
  });

  test('Abbildung der Aufgabe gilt für alle ihre Teile', () {
    final ntg = faelle.firstWhere((c) => c.id == 'P-NT-20251105');
    expect(ntg.aufgabeVon(3)!.bild, 'nt25-rampe');
    for (final q in ntg.asPool().where((q) => q.nr == 3)) {
      expect(q.bildEffektiv, 'nt25-rampe', reason: q.id);
    }
  });
}
