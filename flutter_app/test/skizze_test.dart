import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/pruefung/skizze.dart';
import 'package:kvm_trainer/pruefung/skizze_daten.dart';
import 'package:kvm_trainer/services/answer_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Skizze je Teilaufgabe (FR-013): Erkennung, Voreinstellungen, Zeichnen,
/// Radierer und Zurück, Speicherformat wie im Web.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Erkennung wie skZeichenteil', () {
    test('Aufforderungen zum Zeichnen', () {
      expect(skZeichenteil('Erstellen Sie für den beschriebenen Ablauf ein Flussdiagramm.'), isTrue);
      expect(skZeichenteil('Stellen Sie die Entwicklung der Kosten in einem Diagramm dar.'), isTrue);
      expect(skZeichenteil('Zeichnen Sie das v-t-Diagramm.'), isTrue);
      expect(skZeichenteil('Ermitteln Sie zeichnerisch den Schnittpunkt.'), isTrue);
      expect(skZeichenteil('Kennzeichnen Sie im Netzplan den kritischen Pfad.'), isTrue);
      expect(skZeichenteil('Tragen Sie die Werte in das Wahrscheinlichkeitsnetz (Anlage 1) ein.'), isTrue);
    });

    test('keine Zeichenaufgaben', () {
      expect(skZeichenteil('Nennen Sie vier Diagrammarten.'), isFalse);
      expect(skZeichenteil('Beschreiben Sie Vorteile von Flussdiagrammen.'), isFalse);
      expect(skZeichenteil('Erläutern Sie die Aufgaben der Arbeitsvorbereitung.'), isFalse);
    });

    test('rund 60 der gut 2000 Prüfungs-Teilaufgaben', () {
      final faelle = json.decode(File('assets/data/cases.json').readAsStringSync()) as List<dynamic>;
      var n = 0, alle = 0;
      for (final c in faelle.cast<Map<String, dynamic>>()) {
        if (!(c['id'] as String).startsWith('P-')) continue;
        for (final s in (c['steps'] as List).cast<Map<String, dynamic>>()) {
          alle++;
          if (skZeichenteil((s['q'] ?? '') as String)) n++;
        }
      }
      expect(alle, greaterThan(2000));
      expect(n, 60);
    });
  });

  group('Voreinstellungen', () {
    test('Hoch bei Flussdiagramm, Programmablaufplan, Struktogramm', () {
      expect(skStartFormat('Erstellen Sie ein Flussdiagramm.', null), 'hoch');
      expect(skStartFormat('Erstellen Sie ein Struktogramm.', null), 'hoch');
      expect(skStartFormat('Stellen Sie die Werte in einem Diagramm dar.', null), 'quer');
      expect(skStartFormat('Erstellen Sie ein Flussdiagramm.', {'fmt': 'quer'}), 'quer');
    });

    test('Auf der Anlage nur mit Bild-Anlage und „Anlage“ im Text', () {
      const frage = 'Tragen Sie die Werte in das Wahrscheinlichkeitsnetz (Anlage 1) ein.';
      expect(skStartHintergrund(frage, null, hatAnlage: true), 'anlage');
      expect(skStartHintergrund(frage, null, hatAnlage: false), 'karo');
      expect(skStartHintergrund('Zeichnen Sie ein Diagramm.', null, hatAnlage: true), 'karo');
      expect(skStartHintergrund(frage, {'bg': 'karo'}, hatAnlage: true), 'karo');
      expect(skHoehe(bg: 'anlage', fmt: 'quer', anlageVerhaeltnis: 0.8), 1250);
      expect(skHoehe(bg: 'karo', fmt: 'hoch'), skHoch);
      expect(skHoehe(bg: 'karo', fmt: 'quer'), skQuer);
    });

    test('Einrasten auf ein halbes Karo', () {
      expect(skRasten(18), 12.5);
      expect(skRasten(19), 25);
      expect(skRasten(106), 100);
    });
  });

  group('Zeichnen', () {
    late SkizzeZustand z;
    var aenderungen = 0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AnswerStore.instance.init();
      aenderungen = 0;
      z = SkizzeZustand(
        id: 'P-MI-20241106-s4',
        frage: 'Erstellen Sie für den Ablauf ein Flussdiagramm.',
        anlage: null,
        onAenderung: () => aenderungen++,
      );
    });

    void ziehen(String werkzeug, Offset a, Offset b) {
      z.setzeWerkzeug(werkzeug);
      z.start(a);
      z.bewegen(Offset.lerp(a, b, 0.5)!);
      z.bewegen(b);
      z.ende();
    }

    test('Formen und Pfeil, gespeichert wie im Web', () async {
      expect(z.fmt, 'hoch');
      ziehen('oval', const Offset(400, 100), const Offset(600, 180));
      ziehen('pfeil', const Offset(500, 180), const Offset(500, 300));
      ziehen('rechteck', const Offset(400, 300), const Offset(600, 380));
      ziehen('raute', const Offset(420, 450), const Offset(580, 560));
      expect(z.els.map((e) => e['t']), ['o', 'a', 'r', 'd']);
      expect(aenderungen, 4);

      final gespeichert = AnswerStore.instance.skizze('P-MI-20241106-s4')!;
      expect(gespeichert['v'], 1);
      expect(gespeichert['bg'], 'karo');
      expect(gespeichert['fmt'], 'hoch');
      final oval = (gespeichert['els'] as List).first as Map;
      expect(oval, {'t': 'o', 'c': 'k', 's': 3, 'x': 400.0, 'y': 100.0, 'w': 200.0, 'h': 75.0});
      expect(AnswerStore.instance.hatAntwort('P-MI-20241106-s4'), isFalse);
      expect(AnswerStore.instance.hatSkizze('P-MI-20241106-s4'), isTrue);

      // Nach einem Neustart unverändert.
      final prefs = await SharedPreferences.getInstance();
      final roh = json.decode(prefs.getString('kvm_open_sketch')!) as Map<String, dynamic>;
      expect((roh['P-MI-20241106-s4']['els'] as List).length, 4);
      await AnswerStore.instance.init();
      expect((AnswerStore.instance.skizze('P-MI-20241106-s4')!['els'] as List).length, 4);
    });

    test('zu kleine Formen und kurze Linien zählen nicht', () {
      ziehen('rechteck', const Offset(100, 100), const Offset(104, 104));
      ziehen('linie', const Offset(100, 100), const Offset(103, 100));
      expect(z.els, isEmpty);
      expect(AnswerStore.instance.hatSkizze('P-MI-20241106-s4'), isFalse);
    });

    test('Radierer entfernt einen Strich, Zurück holt ihn wieder', () {
      ziehen('stift', const Offset(100, 100), const Offset(300, 120));
      ziehen('linie', const Offset(100, 400), const Offset(500, 400));
      expect(z.els.length, 2);
      final strich = z.els.first;
      expect((strich['pts'] as List).every((p) => p is int), isTrue);

      z.setzeWerkzeug('radierer');
      z.start(const Offset(200, 110));
      z.ende();
      expect(z.els.map((e) => e['t']), ['l']);

      z.zurueck();
      expect(z.els.map((e) => e['t']), ['p', 'l']);
      expect((AnswerStore.instance.skizze('P-MI-20241106-s4')!['els'] as List).length, 2);
    });

    test('Leeren entfernt die Skizze, Zurück bringt sie zurück', () {
      ziehen('rechteck', const Offset(100, 100), const Offset(300, 200));
      z.leeren();
      expect(z.els, isEmpty);
      expect(AnswerStore.instance.skizze('P-MI-20241106-s4'), isNull);
      z.zurueck();
      expect(z.els.length, 1);
    });

    test('Beschreibung für den Prüfauftrag', () {
      ziehen('oval', const Offset(400, 100), const Offset(600, 180));
      ziehen('pfeil', const Offset(500, 180), const Offset(500, 300));
      ziehen('rechteck', const Offset(400, 300), const Offset(600, 380));
      z.els.first['txt'] = 'Beginn';
      expect(skText({'els': z.els}), '[Eigene Skizze: 1 Rechteck, 1 Oval, 1 Pfeil · Beschriftungen: „Beginn“]');
    });
  });
}
