import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvm_trainer/cloud/modelle.dart';
import 'package:kvm_trainer/cloud/werte.dart';
import 'package:kvm_trainer/services/data_service.dart';
import 'package:kvm_trainer/services/lerntage_service.dart';
import 'package:kvm_trainer/services/progress_service.dart';
import 'package:kvm_trainer/services/pruef_stat.dart';
import 'package:kvm_trainer/services/selection_service.dart';

/// Vergleich ohne Netz: ISO-Woche, Meldewerte, Profil-Details (pr/pc),
/// Sortierung nach Prüfungen, Anzeige-Texte.

List<Map<String, dynamic>> _fragen() =>
    (json.decode(File('assets/data/questions.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();

/// 10 Fragen aus Fach 1 gemeistert, 5 aus Fach 2 gesehen (Box 1); Lerntage
/// heute 5, gestern 7, vor drei Tagen 2; drei Prüfungsdurchgänge, zwei davon
/// unter Echtbedingungen.
Map<String, Object> _stand() {
  final qs = _fragen();
  final prog = <String, dynamic>{};
  for (final q in qs.where((q) => q['f'] == 1).take(10)) {
    prog[q['id'] as String] = {'s': 3, 'c': 3, 'w': 0, 'b': 3, 'l': 1, 'd': 99999};
  }
  for (final q in qs.where((q) => q['f'] == 2).take(5)) {
    prog[q['id'] as String] = {'s': 1, 'c': 1, 'w': 0, 'b': 1, 'l': 1, 'd': 99999};
  }
  final h = LerntageService.heute();
  return {
    'kvm_progress_v1': json.encode(prog),
    'kvm_tage': json.encode({'$h': 5, '${h - 1}': 7, '${h - 3}': 2}),
  };
}

const _ergebnisse = '[{"k":"a","id":"P-RE-20241106","t":1,"g":1,"pkt":70,"max":100,"echt":1},'
    '{"k":"b","id":"P-BW-20240515","t":2,"g":2,"pkt":40,"max":100,"echt":0},'
    '{"k":"c","id":"P-MI-20231108","t":3,"g":3,"pkt":55,"max":90,"echt":true}]';

PruefStatistik _stat({
  int n = 3,
  int ok = 2,
  int? schnitt = 61,
  double? bq,
  double? hq,
  double? gesamt,
  double? haupt,
  Map<String, PruefBereichStat> bereiche = const {
    'RE': PruefBereichStat(kurz: 'Recht', n: 2, ok: 1, schnitt: 55, chance: 0.64),
    'BW': PruefBereichStat(kurz: 'BWL', n: 1, ok: 1, schnitt: 73, chance: 0.713),
    'MI': PruefBereichStat(kurz: 'Methoden', n: 0, ok: 0),
  },
}) =>
    PruefStatistik(n: n, ok: ok, schnitt: schnitt, bq: bq, hq: hq, gesamt: gesamt, haupt: haupt, bereiche: bereiche);

/// Alle fünf Bereiche der Basisqualifikationen gewertet.
const Map<String, PruefBereichStat> _alleBQ = {
  'RE': PruefBereichStat(kurz: 'Recht', n: 1, ok: 1, schnitt: 70, chance: 0.886),
  'BW': PruefBereichStat(kurz: 'BWL', n: 1, ok: 1, schnitt: 62, chance: 0.769),
  'MI': PruefBereichStat(kurz: 'Methoden', n: 1, ok: 1, schnitt: 70, chance: 0.886),
  'ZI': PruefBereichStat(kurz: 'Zusammenarbeit', n: 1, ok: 1, schnitt: 70, chance: 0.886),
  'NT': PruefBereichStat(kurz: 'Naturwiss. & Technik', n: 1, ok: 1, schnitt: 70, chance: 0.886),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ProgressService.instance.reset();
    SharedPreferences.setMockInitialValues(_stand());
    await DataService.instance.load();
    await SelectionService.instance.load();
    await ProgressService.instance.load();
    await LerntageService.instance.load();
    if (!SelectionService.instance.isFachActive(5)) SelectionService.instance.toggle(5);
  });

  group('ISO-Woche', () {
    test('Prüfwerte aus FR-004 und Jahreswechsel', () {
      expect(isoWoche(DateTime(2026, 9, 23)), '2026-W39');
      expect(isoWoche(DateTime(2027, 1, 1)), '2026-W53');
      expect(isoWoche(DateTime(2024, 12, 30)), '2025-W01');
      expect(isoWoche(DateTime(2026, 1, 1)), '2026-W01');
      expect(isoWoche(DateTime(2026, 9, 21)), '2026-W39'); // Montag
      expect(isoWoche(DateTime(2026, 9, 27, 23, 59)), '2026-W39'); // Sonntag spät
      expect(isoWoche(DateTime(2026, 3, 29, 12)), '2026-W13'); // Sommerzeit
      expect(kwNummer('2026-W09'), 9);
      expect(kwNummer('2026-W53'), 53);
    });
  });

  group('Meldewerte', () {
    test('rangliste_melden: Reife wie im Ring, Box ≥ 3, Woche, Antworten, Serie', () {
      final w = ranglisteWerte('Lkw_Profi', jetzt: DateTime(2026, 9, 23));
      expect(w.keys, ['p_name', 'p_reife', 'p_gemeistert', 'p_woche', 'p_antworten', 'p_serie']);
      expect(w['p_name'], 'Lkw_Profi');
      expect(w['p_reife'], (ProgressService.instance.overallReife() * 100).round());
      expect(w['p_gemeistert'], 10);
      expect(w['p_woche'], '2026-W39');
      expect(w['p_antworten'], LerntageService.instance.dieseWoche());
      expect(w['p_antworten'], greaterThanOrEqualTo(5)); // heute zählt immer
      expect(w['p_serie'], 2); // heute und gestern
    });

    test('pruefungen_melden: nichts ohne gewertete Prüfung, sonst ganze Zahlen', () {
      expect(pruefWerte(PruefStatistik.leer), isNull);
      expect(pruefWerte(_stat(haupt: 0.886)), {'p_n': 3, 'p_ok': 2, 'p_schnitt': 61, 'p_chance': 89});
      expect(pruefWerte(_stat(schnitt: null))!['p_chance'], isNull);
      expect(pruefWerte(_stat(schnitt: null))!['p_schnitt'], isNull);
      final ich = pruefIch(_stat(haupt: 0.4), 'Lkw_Profi');
      expect([ich.name, ich.n, ich.ok, ich.schnitt, ich.chance, ich.ich], ['Lkw_Profi', 3, 2, 61, 40, true]);
    });
  });

  group('Profil-Details', () {
    test('Fächer, 14 Tage, Lerntage, Echtbedingungen – ohne Prüfung kein pr/pc', () {
      final d = profilDetails(st: PruefStatistik.leer, echt: echtAusErgebnissen(_ergebnisse), mitHQ: true);
      final f = d['f'] as Map<String, dynamic>;
      expect(f.keys, ['1', '2', '3', '4', '5']);
      expect(f['1'], {'r': (ProgressService.instance.fachReife(1) * 100).round(), 'm': 10, 'g': 10, 'n': 559});
      expect(f['2'], {'r': (ProgressService.instance.fachReife(2) * 100).round(), 'm': 0, 'g': 5, 'n': 695});
      final t14 = d['t14'] as List;
      expect(t14.length, 14);
      expect([t14[13], t14[12], t14[11], t14[10]], [5, 7, 0, 2]);
      expect(d['tage'], 3);
      expect(d['echt'], {'n': 2, 'best': 70});
      expect(d.containsKey('pr'), isFalse);
      expect(d.containsKey('pc'), isFalse);
    });

    test('pr je Bereich mit gewerteter Prüfung, pc in Prozent', () {
      final d = profilDetails(st: _stat(), echt: null, mitHQ: true);
      expect(d.containsKey('echt'), isFalse);
      expect(d['pr'], {
        'RE': {'n': 2, 'ok': 1, 's': 55, 'c': 64},
        'BW': {'n': 1, 'ok': 1, 's': 73, 'c': 71},
      });
      expect(d['pc'], {'bq': null, 'hq': null, 'g': null});

      final alle = profilDetails(
        st: _stat(n: 7, ok: 6, bq: 0.52, hq: 0.61, gesamt: 0.317, haupt: 0.317, bereiche: {
          ..._alleBQ,
          'FT': const PruefBereichStat(kurz: 'Fuhrpark', n: 1, ok: 1, schnitt: 66, chance: 0.8),
          'OK': const PruefBereichStat(kurz: 'Organisation', n: 1, ok: 0, schnitt: 45, chance: 0.395),
        }),
        echt: null,
        mitHQ: true,
      );
      expect((alle['pr'] as Map).keys, ['RE', 'BW', 'MI', 'ZI', 'NT', 'FT', 'OK']);
      expect((alle['pr'] as Map)['OK'], {'n': 1, 'ok': 0, 's': 45, 'c': 40});
      expect(alle['pc'], {'bq': 52, 'hq': 61, 'g': 32});
    });

    test('ohne Fachrichtung ist „g“ die Chance der Basisqualifikationen (wie im Web)', () {
      final d = profilDetails(st: _stat(bq: 0.52, haupt: 0.52, bereiche: _alleBQ), echt: null, mitHQ: false);
      expect(d['pc'], {'bq': 52, 'hq': null, 'g': 52});
      expect((d['f'] as Map).keys, ['1', '2', '3', '4', '5']); // Auswahl ändert f nur über die Fächer
    });

    test('Echtbedingungen aus kvm_pruef_erg: robust gegen Leeres und Kaputtes', () {
      expect(echtAusErgebnissen(null), isNull);
      expect(echtAusErgebnissen(''), isNull);
      expect(echtAusErgebnissen('[]'), isNull);
      expect(echtAusErgebnissen('{kaputt'), isNull);
      expect(echtAusErgebnissen('{"a":1}'), isNull);
      expect(echtAusErgebnissen('[{"echt":1,"pkt":3,"max":0}]'), (n: 1, best: 0));
    });

    test('Aktivität rückt ab details_am bis heute nach', () {
      final jetzt = DateTime(2026, 9, 24, 10);
      final t14 = [for (var i = 1; i <= 14; i++) i];
      final gleich = aktivitaetAus(t14, jetzt.subtract(const Duration(hours: 2)), jetzt: jetzt);
      expect([for (final t in gleich) t.anzahl], t14);
      expect(gleich.last.tag, LerntageService.heute(jetzt));
      final alt = aktivitaetAus(t14, jetzt.subtract(const Duration(days: 2)), jetzt: jetzt);
      expect([for (final t in alt) t.anzahl], [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 0]);
      expect(aktivitaetAus(t14, jetzt.subtract(const Duration(days: 40)), jetzt: jetzt).every((t) => t.anzahl == 0),
          isTrue);
      expect(aktivitaetAus(t14, jetzt.add(const Duration(days: 1)), jetzt: jetzt).first.anzahl, 1);
      expect(aktivitaetAus(null, null), isEmpty);
      expect(aktivitaetAus([...t14, 99], null, jetzt: jetzt).last.anzahl, 99); // nur die letzten 14
    });
  });

  group('Sortierung', () {
    test('Prüfungen: bestanden, dann Schnitt, ohne Schnitt hinten, dann Name; gleicher Stand = gleicher Platz', () {
      final l = pruefSortiert(const [
        PruefEintrag(name: 'cora', n: 3, ok: 2, schnitt: 61),
        PruefEintrag(name: 'Bert', n: 4, ok: 2, schnitt: 70),
        PruefEintrag(name: 'anna', n: 2, ok: 2, schnitt: 61),
        PruefEintrag(name: 'Dora', n: 1, ok: 0),
        PruefEintrag(name: 'Emil', n: 2, ok: 0, schnitt: 30),
        PruefEintrag(name: 'Fritz', n: 5, ok: 3, schnitt: 50, ich: true),
      ]);
      expect([for (final e in l) e.name], ['Fritz', 'Bert', 'anna', 'cora', 'Emil', 'Dora']);
      expect([for (final e in l) e.platz], [1, 2, 3, 3, 5, 6]);
      expect(l.first.ich, isTrue);
    });

    test('Woche (Freunde): Antworten, dann Name; gleiche Antworten = gleicher Platz', () {
      final l = wocheSortiert(const [
        WochenEintrag(platz: 0, name: 'Cora', antworten: 40, reife: 50),
        WochenEintrag(platz: 0, name: 'anna', antworten: 55, reife: 20),
        WochenEintrag(platz: 0, name: 'Bert', antworten: 40, reife: 70, ich: true),
        WochenEintrag(platz: 0, name: 'Dora', antworten: 0, reife: 90),
      ]);
      expect([for (final e in l) e.name], ['anna', 'Bert', 'Cora', 'Dora']);
      expect([for (final e in l) e.platz], [1, 2, 2, 4]);
      expect(l[1].ich, isTrue);
    });
  });

  group('Anzeige', () {
    test('Chance als Text', () {
      expect(chanceText(null), '–');
      expect(chanceText(0), '< 1 %');
      expect(chanceText(1), '1 %');
      expect(chanceText(99), '99 %');
      expect(chanceText(100), '> 99 %');
    });

    test('Kürzel und Farbton wie im Web', () {
      expect(kuerzel('Lkw_Profi'), 'LP');
      expect(kuerzel('Max Mustermann'), 'MM');
      expect(kuerzel('meister.2026'), 'M2');
      expect(kuerzel('cora'), 'CO');
      expect(kuerzel('A'), 'A');
      expect(kuerzel('   '), '?');
      expect(farbton('Cora'), 299); // ((67·31+111)·31+114)·31+97 mod 360, schrittweise
      expect(farbton('Cora'), farbton(' Cora '));
      expect(monatJahr(DateTime(2026, 9, 3)), 'September 2026');
      expect(monatJahr(DateTime(2027, 3, 1)), 'März 2027');
    });

    test('Kennzahlen im Prüfungsmodus', () {
      var (k1, k2) = pruefKennzahlen(PruefStatistik.leer, true, null);
      expect(k1.wert, '–');
      expect(k1.text, startsWith('Noch keine Prüfung gewertet.'));
      expect(k2, (wert: '–', text: 'Ab der ersten gewerteten Prüfung stehst du in der Prüfungsrangliste.'));

      (k1, k2) = pruefKennzahlen(_stat(), true, null);
      expect(k1.wert, '2/7');
      expect(k1.text,
          'Prüfungsbereiche gewertet – für die Bestehenschance fehlt noch: Methoden, Zusammenarbeit, '
          'Naturwiss. & Technik, Fuhrpark, Organisation');
      expect(k2.text, 'Dein Stand wird gemeldet – gleich stehst du in der Liste.');
      expect(pruefKennzahlen(_stat(), false, null).$1.wert, '2/5');

      (k1, k2) = pruefKennzahlen(
          _stat(n: 6, ok: 6, bq: 0.52, haupt: 0.52, bereiche: _alleBQ),
          true,
          const PruefRangliste(teilnehmende: 5, ich: PruefEintrag(platz: 3, name: '', n: 6, ok: 6, ich: true)));
      expect(k1, (wert: '52 %', text: 'Bestehenschance · Basisqualifikationen – für beide Teile fehlt noch: Fuhrpark, Organisation'));
      expect(k2, (wert: '3.', text: 'Platz von 5 · 6 von 6 Prüfungen bestanden'));

      expect(pruefKennzahlen(_stat(bq: 0.52, gesamt: 0.52, haupt: 0.52, bereiche: _alleBQ), false, null).$1,
          (wert: '52 %', text: 'Bestehenschance · Basisqualifikationen'));
      expect(pruefKennzahlen(_stat(bq: 0.9, hq: 0.8, gesamt: 0.72, haupt: 0.72), true, null).$1,
          (wert: '72 %', text: 'Bestehenschance · beide Teile'));
      expect(pruefKennzahlen(_stat(hq: 0.8, haupt: 0.8), true, null).$1.text,
          startsWith('Bestehenschance · handlungsspezifischer Teil – für beide Teile fehlt noch: Methoden'));
      expect(pruefKennzahlen(_stat(n: 1, ok: 1, haupt: 0.999, gesamt: 0.999), true, null).$1.wert, '> 99 %');
    });

    test('Fehlertexte wie im Web', () {
      expect(beitrittsFehler('23505'), 'Dieser Spitzname ist schon vergeben.');
      expect(beitrittsFehler('23514'), kTextNameRegel);
      expect(beitrittsFehler('P0006'), 'Dein Konto ist für Rangliste, Gruppen und Freunde gesperrt.');
      expect(beitrittsFehler('XX000'), kTextNichtGeklappt);
      expect(beitrittsFehler(null, netz: true), 'Keine Verbindung – bitte später noch einmal.');
      expect(kGruppenFehler['P0002'], 'Keine Gruppe mit diesem Code gefunden.');
      expect(kLeuteFehler['P0004'], startsWith('Du hast gerade sehr viele offene Anfragen'));
      expect(kSpitznameMuster.hasMatch(spitznameAus('  Lkw   Profi ')), isTrue);
      expect(spitznameAus('  Lkw   Profi '), 'Lkw Profi');
      expect(kSpitznameMuster.hasMatch('ab'), isFalse);
      expect(kSpitznameMuster.hasMatch('Jörg_Straße-1.0'), isTrue);
      expect(kSpitznameMuster.hasMatch('drop;table'), isFalse);
    });

    test('Einladung: Text mit Code und Link zur Web-App', () {
      final e = einladungFuer(const GruppenStand(id: 'g1', name: 'Meisterkurs Herbst 2026', code: 'K7M2QX'));
      expect(e.text, 'Lerngruppe „Meisterkurs Herbst 2026“ im Meister-Trainer – lern mit! Code: K7M2QX');
      expect(e.link, endsWith('#gruppe=K7M2QX'));
      expect(e.link, startsWith('https://'));
    });

    test('Antworten der Datenbank nachsichtig lesen', () {
      final st = RanglisteStand.aus({
        'dabei': true,
        'name': 'Lkw_Profi',
        'teilnehmende': 12,
        'reife_vor': 7,
        'woche_teilnehmende': 9,
        'mein_platz': null,
        'meine_antworten': null,
        'liste': [
          {'platz': 1, 'name': 'Cora', 'antworten': 312, 'reife': 64, 'serie': 5, 'ich': false},
          null,
        ],
      });
      expect([st.dabei, st.name, st.teilnehmende, st.reifeVor, st.meinPlatz], [true, 'Lkw_Profi', 12, 7, null]);
      expect(st.liste.single.antworten, 312);
      expect(RanglisteStand.aus(null).dabei, isFalse);
      expect(FreundeStand.aus(null), isNull);
      expect(GruppenStand.aus(null), isNull);
      expect(Profil.aus({'name': 'x'}).fehler, isTrue);
      final p = Profil.aus({
        'pid': 'p1',
        'name': 'Cora',
        'sichtbar': true,
        'seit': '2026-09-01T10:00:00+00:00',
        'details': {'tage': 3},
        'details_am': '2026-09-20T08:00:00Z',
        'pruef_n': 3,
        'chance': 71,
      });
      expect([p.sichtbar, p.seit?.month, p.details['tage'], p.pruefN, p.chance], [true, 9, 3, 3, 71]);
      final pr = PruefRangliste.aus({
        'teilnehmende': 5,
        'ich': {'platz': 3, 'n': 6, 'ok': 6, 'schnitt': 71, 'chance': 88},
        'liste': [],
      });
      expect([pr.ich!.platz, pr.ich!.ich, pr.liste.length], [3, true, 0]);
    });
  });
}
