import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_trainer/models.dart';
import 'package:kvm_trainer/pruefung/echt.dart';
import 'package:kvm_trainer/pruefung/ergebnisse.dart';
import 'package:kvm_trainer/services/answer_store.dart';
import 'package:kvm_trainer/services/pruef_stat.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prüfungsergebnisse (FR-014): Durchgänge speichern, Wertung,
/// Bestehenschance genau nach Formel, Neustart, Übernahme des alten Verlaufs.
CaseStudy _pruefung(String id, List<int> punkte) => CaseStudy(
      id: id,
      f: 1,
      sub: 'IHK-Prüfung: Test',
      title: 'IHK-Prüfung Test – 1. Januar 2024',
      context: '',
      aufgaben: const [Aufgabe(nr: 1, pts: 100)],
      steps: [
        for (var i = 0; i < punkte.length; i++)
          Question(id: '$id-s$i', f: 1, sub: 'x', type: 'open', q: 'Frage $i', nr: 1, teil: 'abcdefgh'[i], pts: punkte[i]),
      ],
    );

Future<void> _laden(Map<String, Object> werte) async {
  SharedPreferences.setMockInitialValues(werte);
  await AnswerStore.instance.init();
  await Echtbedingungen.instance.load();
  await PruefErgebnisse.instance.load();
}

PruefVersuch _v(int p, {bool echt = false}) => PruefVersuch('P-RE-20240101', p, echt, 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bestehenschance (FR-014 4)', () {
    test('Prüfwerte: eine Prüfung mit 70 % → 88,6 %, 62 % → 76,9 %, 45 % → 39,5 %', () {
      expect(peChance([_v(70)])!, closeTo(0.886, 0.0005));
      expect(peChance([_v(62)])!, closeTo(0.769, 0.0005));
      expect(peChance([_v(45)])!, closeTo(0.395, 0.0005));
      expect(peChance([]), isNull);
    });

    test('Formel: Gewichte 0,8^(n−i), Prüfungsbedingungen ×1,5, Streuung ab der zweiten Prüfung', () {
      // Von Hand gerechnet: x = [50, 80], w = [0,8; 1]
      const w1 = 0.8, w2 = 1.0;
      const sw = w1 + w2, sw2 = w1 * w1 + w2 * w2;
      const mu = (w1 * 50 + w2 * 80) / sw;
      const s2 = (w1 * (50 - mu) * (50 - mu) + w2 * (80 - mu) * (80 - mu)) / sw * 2 / 1;
      const streu2 = (3 * 144 + 1 * s2) / 4;
      const neff = sw * sw / sw2;
      final erwartet = peCdf((mu - 49.5) / _wurzel(streu2 * (1 + 1 / neff)));
      expect(peChance([_v(50), _v(80)])!, closeTo(erwartet, 1e-12));
      // Neuere Prüfungen zählen mehr, Prüfungsbedingungen auch.
      expect(peChance([_v(50), _v(80)])!, greaterThan(peChance([_v(80), _v(50)])!));
      expect(peChance([_v(50, echt: true), _v(80)])!, lessThan(peChance([_v(50), _v(80)])!));
    });

    test('Standardnormalverteilung nach Abramowitz/Stegun', () {
      expect(peCdf(0), closeTo(0.5, 1e-9));
      expect(peCdf(1.96), closeTo(0.975, 1e-4));
      expect(peCdf(-1.96), closeTo(0.025, 1e-4));
    });

    test('Anzeige: ganze Prozent, unter 1 % und über 99 % mit Zeichen', () {
      expect(peProzent(null), '–');
      expect(peProzent(0.004), '< 1 %');
      expect(peProzent(0.995), '> 99 %');
      expect(peProzent(0.99), '99 %');
      expect(peProzent(0.886), '89 %');
      expect(chanceStufe(0.7), ChanceStufe.gut);
      expect(chanceStufe(0.4), ChanceStufe.mittel);
      expect(chanceStufe(0.39), ChanceStufe.knapp);
    });
  });

  group('Wertung (FR-014 3)', () {
    test('gewertet: jede Teilaufgabe hat Punkte oder unter Prüfungsbedingungen', () {
      const voll = PruefDurchgang(k: 'a', id: 'P-RE-20240101', t: 1, pkt: 55, max: 100, bew: 5, teile: 5);
      const teilweise = PruefDurchgang(k: 'b', id: 'P-RE-20240101', t: 1, pkt: 20, max: 100, bew: 2, teile: 5);
      const echt = PruefDurchgang(k: 'c', id: 'P-RE-20240101', t: 1, pkt: 20, max: 100, bew: 2, teile: 5, echt: true);
      expect(voll.gewertet, isTrue);
      expect(teilweise.gewertet, isFalse);
      expect(echt.gewertet, isTrue);
      expect(voll.bestanden, isTrue);
      expect(echt.bestanden, isFalse);
      expect(voll.note, 4);
    });

    test('Erstversuch: je Prüfung zählt nur der erste gewertete Durchgang', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      pe.merken(const PruefDurchgang(k: 'x0', id: 'P-RE-20240101', t: 10, pkt: 10, max: 100, bew: 1, teile: 5), jetzt: 10);
      pe.merken(const PruefDurchgang(k: 'x1', id: 'P-RE-20240101', t: 20, pkt: 70, max: 100, bew: 5, teile: 5), jetzt: 20);
      pe.merken(const PruefDurchgang(k: 'x2', id: 'P-RE-20240101', t: 30, pkt: 90, max: 100, bew: 5, teile: 5), jetzt: 30);
      final erst = pe.erstversuche();
      expect(erst.length, 1);
      expect(erst.single.k, 'x1');
      final st = pe.statistik(hqAktiv: false);
      expect(st.n, 1);
      expect(st.ok, 1);
      expect(st.schnitt, 70);
      expect(st.bereiche['RE']!.chance, closeTo(0.886, 0.0005));
      expect(st.bq.p, isNull); // die übrigen vier Bereiche fehlen noch
      expect(st.bq.fehlt, ['BW', 'MI', 'ZI', 'NT']);
      expect(st.haupt, isNull);
      expect(st.durchgaenge, 3);
    });

    test('Teile: Basisqualifikationen, handlungsspezifisch nur mit Fachrichtung', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      var t = 1;
      for (final k in ['RE', 'BW', 'MI', 'ZI', 'NT']) {
        pe.merken(PruefDurchgang(k: 'k$k', id: 'P-$k-20240101', t: t++, pkt: 70, max: 100, bew: 3, teile: 3));
      }
      final ohneHq = pe.statistik(hqAktiv: false);
      expect(ohneHq.hq, isNull);
      expect(ohneHq.bq.p, closeTo(_hoch(0.8865, 5), 0.01));
      expect(ohneHq.gesamt, ohneHq.bq.p);
      expect(ohneHq.haupt!.teil, 'bq');
      final mitHq = pe.statistik(hqAktiv: true);
      expect(mitHq.hq!.fehlt, ['FT', 'OK']);
      expect(mitHq.gesamt, isNull);
      expect(mitHq.haupt!.teil, 'bq');
      pe.merken(PruefDurchgang(k: 'kFT', id: 'P-FT-20240101', t: t++, pkt: 60, max: 100, bew: 3, teile: 3));
      pe.merken(PruefDurchgang(k: 'kOK', id: 'P-OK-20240101', t: t++, pkt: 60, max: 100, bew: 3, teile: 3));
      final beide = pe.statistik(hqAktiv: true);
      expect(beide.gesamt, closeTo(beide.bq.p! * beide.hq!.p!, 1e-12));
      expect(beide.haupt!.teil, 'g');
      expect(beide.n, 7);
    });
  });

  group('Durchgänge speichern (FR-014 2)', () {
    test('„Zum Ergebnis“ mehrmals ändert denselben Durchgang; t bleibt, g wächst', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      final fall = _pruefung('P-RE-20240101', [4, 6]);
      AnswerStore.instance.setPoints('P-RE-20240101-s0', 3);
      final a = pe.merken(pe.durchgang(fall, jetzt: 1000), jetzt: 1000);
      AnswerStore.instance.setPoints('P-RE-20240101-s1', 5);
      final b = pe.merken(pe.durchgang(fall, jetzt: 5000), jetzt: 900);
      expect(pe.alle.length, 1);
      expect(b.k, a.k);
      expect(b.t, 1000);
      expect(b.g, a.g + 1); // max(jetzt, altes g + 1)
      expect(b.pkt, 8);
      expect(b.max, 10);
      expect(b.bew, 2);
      expect(b.teile, 2);
      expect(b.gewertet, isTrue);
    });

    test('Speicherformat wie im Web: kvm_pruef_erg und kvm_pruef_lauf', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      final fall = _pruefung('P-NT-20150429', [10]);
      pe.echtStarten(fall, jetzt: 1000);
      final e = Echtbedingungen.instance.abgeben(fall.id, jetzt: 1000 + 30 * 60000)!;
      pe.merken(pe.durchgang(fall, echt: e, jetzt: 2000000), jetzt: 2000000);
      final prefs = await SharedPreferences.getInstance();
      final liste = json.decode(prefs.getString('kvm_pruef_erg')!) as List;
      final d = liste.single as Map<String, dynamic>;
      expect(d.keys.toSet(), {'k', 'id', 't', 'g', 'pkt', 'max', 'bew', 'teile', 'echt', 'dauer', 'min'});
      expect(d['echt'], 1);
      expect(d['min'], 60);
      expect(d['dauer'], 30 * 60000);
      expect(d['bew'], 0);
      expect(d['teile'], 1);
      final lauf = json.decode(prefs.getString('kvm_pruef_lauf')!) as Map<String, dynamic>;
      expect(lauf['P-NT-20150429'], d['k']);
      expect(RegExp(r'^[0-9a-z]+$').hasMatch(d['k'] as String), isTrue);
    });

    test('Prüfungsbedingungen bleiben 1, auch wenn später nachbewertet', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      pe.merken(const PruefDurchgang(k: 'k1', id: 'P-RE-20240101', t: 5, pkt: 30, max: 100, bew: 1, teile: 3, echt: true, dauer: 60000, min: 90));
      final b = pe.merken(const PruefDurchgang(k: 'k1', id: 'P-RE-20240101', t: 9, pkt: 60, max: 100, bew: 3, teile: 3));
      expect(b.echt, isTrue);
      expect(b.dauer, 60000);
      expect(b.min, 90);
      expect(b.t, 5);
    });

    test('Übernahme aus kvm_echt_verlauf (einmalig)', () async {
      await _laden({
        'kvm_echt_verlauf': json.encode([
          {'id': 'P-NT-20150429', 'tag': 20000, 'min': 60, 'dauer': 3000000, 'pkt': 64, 'max': 100, 'note': 3},
          {'id': 'P-RE-20240101', 'tag': 19990, 'min': 90, 'dauer': 0, 'pkt': 0, 'max': 0},
        ]),
      });
      final alle = PruefErgebnisse.instance.alle;
      expect(alle.length, 1);
      final e = alle.single;
      expect(e.k, 'e20000-P-NT-20150429-3000000');
      expect(e.t, 20000 * 86400000 + 43200000);
      expect(e.g, e.t);
      expect(e.echt, isTrue);
      expect(e.bew, isNull);
      expect(e.teile, isNull);
      expect(e.gewertet, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('kvm_pruef_erg'), isNotNull);
    });

    test('Zusammenführen: das größere g gewinnt, echt bleibt 1, Ungültiges fällt weg', () async {
      await _laden({});
      final pe = PruefErgebnisse.instance;
      pe.merken(const PruefDurchgang(k: 'k1', id: 'P-RE-20240101', t: 5, pkt: 30, max: 100, bew: 3, teile: 3), jetzt: 100);
      final geaendert = pe.zusammenfuehren([
        {'k': 'k1', 'id': 'P-RE-20240101', 't': 5, 'g': 50, 'pkt': 99, 'max': 100, 'bew': 3, 'teile': 3, 'echt': 1},
        {'k': 'k2', 'id': 'P-BW-20240101', 't': 7, 'g': 70, 'pkt': 60, 'max': 100, 'bew': 3, 'teile': 3, 'echt': 0},
        {'k': 'k3', 'id': 'kaputt', 't': 7, 'g': 70, 'pkt': 60, 'max': 100},
        {'k': 'k4', 'id': 'P-ZI-20240101', 't': 7, 'g': 70, 'pkt': 0, 'max': 0},
      ]);
      expect(geaendert, isTrue);
      final k1 = pe.alle.firstWhere((e) => e.k == 'k1');
      expect(k1.pkt, 30); // lokal jünger bewertet (g = 100)
      expect(k1.echt, isTrue); // echt bleibt 1
      expect(pe.alle.map((e) => e.k).toSet(), {'k1', 'k2'});
      expect(pe.zusammenfuehren([
        {'k': 'k2', 'id': 'P-BW-20240101', 't': 7, 'g': 70, 'pkt': 60, 'max': 100},
      ]), isFalse);
    });
  });

  group('Neu starten (FR-014 1)', () {
    test('vollständig bewertet, nie gemerkt → vorher gemerkt; Blätter leer, neue Kennung', () async {
      await _laden({
        'kvm_open_answers': json.encode({'P-RE-20240101-s0': 'Antwort'}),
        'kvm_open_points': json.encode({'P-RE-20240101-s0': 4, 'P-RE-20240101-s1': 2}),
        'kvm_open_calc': json.encode({
          'P-RE-20240101-s1': [
            {'l': 'Kosten', 'f': '4.400 ÷ 22', 'u': '€'}
          ]
        }),
        'kvm_open_tabs': json.encode({
          'P-RE-20240101-s0#t0': {'0-1': '12'},
          'P-RE-2024010-s0#t0': {'0-1': 'fremd'},
        }),
        'kvm_open_sketch': json.encode({
          'P-RE-20240101-s1': {
            'v': 1,
            'bg': 'karo',
            'fmt': 'quer',
            'els': [
              {'t': 'r', 'c': 'k', 's': 3, 'x': 100, 'y': 100, 'w': 200, 'h': 100, 'txt': 'Beginn'}
            ]
          }
        }),
      });
      final pe = PruefErgebnisse.instance;
      final fall = _pruefung('P-RE-20240101', [4, 6]);
      final alt = pe.lauf(fall.id);
      expect(AnswerStore.instance.pruefungenMitStand(), contains('P-RE-20240101'));
      pe.neuStarten(fall);
      expect(pe.alle.length, 1);
      expect(pe.alle.single.k, alt);
      expect(pe.alle.single.pkt, 6);
      expect(pe.lauf(fall.id), isNot(alt));
      final s = AnswerStore.instance;
      expect(s.get('P-RE-20240101-s0'), '');
      expect(s.points('P-RE-20240101-s0'), isNull);
      expect(s.hatCalc('P-RE-20240101-s1'), isFalse);
      expect(s.hatSkizze('P-RE-20240101-s1'), isFalse);
      expect(s.tabGefuellt('P-RE-20240101-s0#t0'), isFalse);
      expect(s.tabGefuellt('P-RE-2024010-s0#t0'), isTrue); // fremde Prüfung bleibt
      expect(s.pruefungenMitStand(), isNot(contains('P-RE-20240101')));
    });

    test('nicht vollständig bewertet → nichts gemerkt; laufende Prüfungsbedingungen enden', () async {
      await _laden({
        'kvm_open_points': json.encode({'P-RE-20240101-s0': 4}),
      });
      final pe = PruefErgebnisse.instance;
      final fall = _pruefung('P-RE-20240101', [4, 6]);
      Echtbedingungen.instance.setzen(EchtLauf(id: fall.id, start: DateTime.now().millisecondsSinceEpoch, min: 90));
      pe.neuStarten(fall);
      expect(pe.alle, isEmpty);
      expect(Echtbedingungen.instance.lauf, isNull);
      expect(AnswerStore.instance.points('P-RE-20240101-s0'), isNull);
    });

    test('Start unter Prüfungsbedingungen leert die Blätter und stellt die Uhr', () async {
      await _laden({
        'kvm_open_answers': json.encode({'P-NT-20150429-s0': 'Antwort'}),
      });
      final fall = _pruefung('P-NT-20150429', [10]);
      PruefErgebnisse.instance.echtStarten(fall, jetzt: 5000);
      expect(AnswerStore.instance.get('P-NT-20150429-s0'), '');
      final e = Echtbedingungen.instance.von(fall.id)!;
      expect(e.min, 60);
      expect(e.start, 5000);
      final prefs = await SharedPreferences.getInstance();
      expect(json.decode(prefs.getString('kvm_echt')!), {'id': 'P-NT-20150429', 'start': 5000, 'min': 60});
    });
  });

  group('Prüfung unter Echtbedingungen (FR-007)', () {
    test('Bearbeitungszeit aus dem Text, sonst 90 bzw. 60 Minuten', () {
      CaseStudy fall(String id, String ctx) =>
          CaseStudy(id: id, f: 5, sub: '', title: '', context: ctx, steps: const []);
      expect(echtMinuten(fall('P-OK-20221115', 'Bearbeitungszeit 180 Minuten, 100 Punkte insgesamt')), 180);
      expect(echtMinuten(fall('P-RE-20240101', '')), 90);
      expect(echtMinuten(fall('P-NT-20150429', '')), 60);
    });

    test('Uhr und Dauer', () {
      expect(uhrText(3600000), '1:00:00');
      expect(uhrText(3599000), '59:59');
      expect(uhrText(5385000), '1:29:45');
      expect(uhrText(-5), '0:00');
      expect(dauerText(72 * 60000), '1 h 12 min');
      expect(dauerText(60 * 60000), '1 h');
      expect(dauerText(45 * 60000), '45 min');
    });

    test('Abgabe: ende = min(jetzt, start + min), nach Ablauf zeitUm', () async {
      await _laden({});
      final ec = Echtbedingungen.instance;
      ec.setzen(const EchtLauf(id: 'P-NT-20150429', start: 0, min: 60));
      // start 0 ist ungültig (wie im Web) – beim Laden fällt der Durchgang weg
      await ec.load();
      expect(ec.lauf, isNull);
      ec.setzen(const EchtLauf(id: 'P-NT-20150429', start: 1000, min: 60));
      final e = ec.abgeben('P-NT-20150429', zeitUm: true, jetzt: 1000 + 61 * 60000)!;
      expect(e.ende, 1000 + 60 * 60000);
      expect(e.zeitUm, isTrue);
      expect(dauerText(e.dauer), '1 h');
    });
  });

  test('pruefStatistik und pruefStand werden gefüllt', () async {
    await _laden({});
    final vorher = pruefStand.value;
    PruefErgebnisse.instance.merken(
        const PruefDurchgang(k: 'z1', id: 'P-MI-20240101', t: 1, pkt: 62, max: 100, bew: 2, teile: 2));
    expect(pruefStand.value, greaterThan(vorher));
    final st = pruefStatistik();
    expect(st.n, 1);
    expect(st.ok, 1);
    expect(st.schnitt, 62);
    expect(st.bereiche['MI']!.chance, closeTo(0.769, 0.0005));
    expect(st.bereiche['MI']!.kurz, 'Methoden');
  });
}

double _wurzel(double x) => x <= 0 ? 0 : _newton(x);
double _newton(double x) {
  var r = x;
  for (var i = 0; i < 60; i++) {
    r = (r + x / r) / 2;
  }
  return r;
}

double _hoch(double b, int e) {
  var r = 1.0;
  for (var i = 0; i < e; i++) {
    r *= b;
  }
  return r;
}
